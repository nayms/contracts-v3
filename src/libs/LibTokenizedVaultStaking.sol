// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { StakingConfig, StakingState, RewardsBalances } from "../shared/FreeStructs.sol";

import { StakingNotStarted, StakingAlreadyStarted, IntervalRewardPayedOutAlready, InvalidAValue, InvalidRValue, InvalidDividerValue, APlusRCannotBeGreaterThanDivider, InvalidIntervalSecondsValue } from "../shared/CustomErrors.sol";

// solhint-disable no-console
import { console2 as c } from "forge-std/console2.sol";
import { StdStyle } from "forge-std/Test.sol";

library LibTokenizedVaultStaking {
    using StdStyle for *;

    event DebugStake(bytes32 tokenId, bytes32 ownerId);
    //     event DebugBoost(uint256 boostTotal, uint256 blockTimestamp, uint64 startTimeOfCurrentInterval, uint64 interval);
    //     event DebugBoost2(uint256 boost1, uint256 boost2);
    //     event DebugStakeBoost(uint256 stakeBoostOwner1, uint256 stakeBoostOwner2, uint256 stakeBoostToken1, uint256 stakeBoostToken2);

    event TokenStakingStarted(bytes32 indexed entityId, bytes32 tokenId, uint256 initDate, uint64 a, uint64 r, uint64 divider, uint64 interval);
    event TokenStaked(bytes32 indexed stakerId, bytes32 entityId, bytes32 tokenId, uint256 amount);
    event TokenUnstaked(bytes32 indexed stakerId, bytes32 entityId, bytes32 tokenId, uint256 amount);
    event TokenRewardPaid(bytes32 guid, bytes32 entityId, bytes32 tokenId, bytes32 rewardTokenId, uint256 rewardAmount);
    event TokenRewardCollected(bytes32 indexed stakerId, bytes32 entityId, bytes32 tokenId, uint64 interval, bytes32 rewardCurrency, uint256 rewardAmount);

    /**
     * @dev First 4 bytes: "VTOK", next 8 bytes: interval, next 20 bytes: right 20 bytes of tokenId
     * @param _tokenId The internal ID of the token.
     * @param _interval The interval of staking.
     */
    function _vTokenId(bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32 vTokenId_) {
        vTokenId_ = bytes32(abi.encodePacked(bytes4(LC.OBJECT_TYPE_STAKED), _interval, bytes20(_tokenId)));
    }

    function _initStaking(bytes32 _entityId, StakingConfig calldata _config) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        _validateStakingParams(_config);

        if (s.stakingConfigs[_entityId].initDate == 0) {
            s.stakingConfigs[_entityId] = _config;
        } else {
            revert StakingAlreadyStarted(_entityId, _config.tokenId);
        }
        emit TokenStakingStarted(_entityId, _config.tokenId, block.timestamp, _config.a, _config.r, _config.divider, _config.interval);
    }

    function _isStakingInitialized(bytes32 _entityId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.stakingConfigs[_entityId].initDate > 0 && s.stakingConfigs[_entityId].initDate < block.timestamp);
    }

    function _stakingConfig(bytes32 _entityId) internal view returns (StakingConfig memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingConfigs[_entityId];
    }

    function _currentInterval(bytes32 _entityId) internal view returns (uint64 currentInterval_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.stakingConfigs[_entityId].initDate == 0 || block.timestamp < s.stakingConfigs[_entityId].initDate) {
            currentInterval_ = 0;
        } else {
            currentInterval_ = uint64((block.timestamp - s.stakingConfigs[_entityId].initDate) / s.stakingConfigs[_entityId].interval);
        }
    }

    function _payReward(bytes32 _guid, bytes32 _entityId, bytes32 _rewardTokenId, uint256 _rewardAmount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        uint64 interval = _currentInterval(_entityId);
        bytes32 vTokenId = _vTokenId(tokenId, interval);

        StakingState memory stakingState = _getStakingState(_entityId, _entityId, interval);

        if (block.timestamp < s.stakingConfigs[_entityId].initDate) {
            revert StakingNotStarted(_entityId, tokenId);
        }

        if (s.stakingDistributionDenomination[vTokenId] != 0) {
            revert IntervalRewardPayedOutAlready(interval);
        }

        s.stakingDistributionAmount[vTokenId] = _rewardAmount;
        s.stakingDistributionDenomination[vTokenId] = _rewardTokenId;

        // No money needs to actually be transferred
        s.stakeBalance[vTokenId][_entityId] = stakingState.balance;
        s.stakeBoost[vTokenId][_entityId] = stakingState.boost;

        // Update last colleted interval for the token itself
        s.stakeCollected[_entityId][_entityId] = interval;

        // Transfer the funds
        LibTokenizedVault._internalTransfer(_entityId, _vTokenId(tokenId, 0), _rewardTokenId, _rewardAmount);

        emit TokenRewardPaid(_guid, _entityId, tokenId, _rewardTokenId, _rewardAmount);
    }

    function _stake(bytes32 _stakerId, bytes32 _entityId, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        uint64 currentInterval = _currentInterval(_entityId);
        bytes32 vTokenId0 = _vTokenId(tokenId, 0);
        bytes32 vTokenId = _vTokenId(tokenId, currentInterval);
        bytes32 nextVTokenId = _vTokenId(tokenId, currentInterval + 1);

        // First collect rewards. This will update the current state.
        _collectRewards(_stakerId, _entityId, currentInterval);

        // get the tokens
        LibTokenizedVault._internalTransfer(_stakerId, vTokenId0, tokenId, _amount);

        // update the share of staking reward
        s.stakeBalance[vTokenId][_stakerId] += _amount;

        if (currentInterval != 0) {
            // needed for the original staked amount when unstaking
            s.stakeBalance[vTokenId0][_stakerId] += _amount;
        }

        s.stakeBalance[vTokenId][_entityId] += _amount;

        // update the boosts on the current and next intervals depending on time
        uint256 boostTotal = (_amount * _getA(_entityId)) / _getD(_entityId);
        uint256 boostNext;

        if (_isStakingInitialized(_entityId)) {
            boostNext = (boostTotal * (block.timestamp - _calculateStartTimeOfCurrentInterval(_entityId))) / s.stakingConfigs[_entityId].interval;
        }

        uint256 boost = boostTotal - boostNext;

        // give to the staker
        s.stakeBoost[vTokenId][_stakerId] += boost;
        s.stakeBoost[nextVTokenId][_stakerId] += boostNext;

        // give to the totals!!!
        s.stakeBoost[vTokenId][_entityId] += boost;
        s.stakeBoost[nextVTokenId][_entityId] += boostNext;

        emit TokenStaked(_stakerId, _entityId, tokenId, _amount);
    }

    // Unstakes the full amount for a staker
    function _unstake(bytes32 _stakerId, bytes32 _entityId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        uint64 currentInterval = _currentInterval(_entityId);
        bytes32 vTokenId0 = _vTokenId(tokenId, 0);
        bytes32 vTokenId = _vTokenId(tokenId, currentInterval);

        // collect your rewards first
        _collectRewards(_stakerId, _entityId, currentInterval);

        // set boost and balances to zero
        s.stakeBoost[vTokenId][_stakerId] = 0;
        s.stakeBalance[vTokenId][_stakerId] = 0;

        uint256 originalAmountStaked = s.stakeBalance[vTokenId0][_stakerId];
        s.stakeBalance[vTokenId0][_stakerId] = 0;

        LibTokenizedVault._internalTransfer(vTokenId0, _stakerId, tokenId, originalAmountStaked);

        emit TokenUnstaked(_stakerId, _entityId, tokenId, originalAmountStaked);
    }

    // This function is used to calculate the correct current state for the user,
    // as well as the totals for when a staking reward distribution is made.
    function _getStakingStateWithRewardsBalances(
        bytes32 _stakerId,
        bytes32 _entityId,
        uint64 _interval
    ) internal view returns (StakingState memory state, RewardsBalances memory rewards) {
        // Rewards can be made in various denominations, but only 1 denomination per
        // interval. This limits the size of the array.
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        // Get the last interval where distribution was collected by the user.
        state.lastCollectedInterval = s.stakeCollected[_entityId][_stakerId];
        // Get the current interval
        if (_interval < state.lastCollectedInterval) {
            revert("rewards already collected");
        }
        if (_interval > _currentInterval(_entityId)) {
            revert("interval is in the future");
        }

        {
            uint256 totalDistributionAmount;
            uint256 userDistributionAmount;
            bytes32 stakingDistributionDenomination;
            uint256 currencyIndex;

            state.balance = s.stakeBalance[_vTokenId(tokenId, state.lastCollectedInterval)][_stakerId];
            state.boost = s.stakeBoost[_vTokenId(tokenId, state.lastCollectedInterval)][_stakerId];
            for (uint64 i = state.lastCollectedInterval; i < _interval; ++i) {
                // check to see if there are rewards for this interval, and update arrays
                totalDistributionAmount = s.stakingDistributionAmount[_vTokenId(tokenId, i)];

                if (totalDistributionAmount > 0) {
                    stakingDistributionDenomination = s.stakingDistributionDenomination[_vTokenId(tokenId, i)];
                    (rewards, currencyIndex) = addUniqueValue(rewards, stakingDistributionDenomination);

                    // Use the same math as dividend distributions, assuming zero has already been collected
                    userDistributionAmount = LibTokenizedVault._getWithdrawableDividendAndDeductionMath(
                        state.balance,
                        s.stakeBalance[_vTokenId(tokenId, i)][_entityId],
                        totalDistributionAmount,
                        0
                    );
                    rewards.amounts[currencyIndex] += userDistributionAmount;
                    rewards.lastPaidInterval = i;
                }
                state.balance += state.boost;
                state.boost = s.stakeBoost[_vTokenId(tokenId, i + 1)][_stakerId] + (state.boost * _getR(_entityId)) / _getD(_entityId);
            }
        }
    }

    function _getStakingState(bytes32 _stakerId, bytes32 _entityId, uint64 _interval) internal view returns (StakingState memory state) {
        // Rewards can be made in various denominations, but only 1 denomination per
        // interval. This limits the size of the array.
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        state.lastCollectedInterval = s.stakeCollected[_entityId][_stakerId];

        if (_interval < state.lastCollectedInterval) {
            revert("rewards already collected");
        }
        if (_interval > _currentInterval(_entityId)) {
            revert("interval is in the future");
        }

        {
            state.balance = s.stakeBalance[_vTokenId(tokenId, state.lastCollectedInterval)][_stakerId];
            state.boost = s.stakeBoost[_vTokenId(tokenId, state.lastCollectedInterval)][_stakerId];
            for (uint64 i = state.lastCollectedInterval; i < _interval; ++i) {
                state.balance += state.boost;
                state.boost = s.stakeBoost[_vTokenId(tokenId, i + 1)][_stakerId] + (state.boost * _getR(_entityId)) / _getD(_entityId);
            }
        }
    }

    function _collectRewards(bytes32 _stakerId, bytes32 _entityId, uint64 _interval) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        (StakingState memory state, RewardsBalances memory rewards) = _getStakingStateWithRewardsBalances(_stakerId, _entityId, _interval);
        if (rewards.currencies.length > 0) {
            bytes32 vTokenId = _vTokenId(tokenId, _interval);

            // Update state
            s.stakeCollected[_entityId][_stakerId] = _interval; // TODO: set to the actual reward interval, not current!
            s.stakeBoost[vTokenId][_stakerId] = state.boost;
            s.stakeBalance[vTokenId][_stakerId] = state.balance;

            for (uint64 i = 0; i < rewards.currencies.length; ++i) {
                LibTokenizedVault._internalTransfer(_vTokenId(tokenId, 0), _stakerId, rewards.currencies[i], rewards.amounts[i]);
                emit TokenRewardCollected(_stakerId, _entityId, tokenId, _interval, rewards.currencies[i], rewards.amounts[i]);
            }
        }
    }

    function _validateStakingParams(StakingConfig calldata _config) internal pure {
        if (_config.a == 0) revert InvalidAValue();
        if (_config.r == 0) revert InvalidRValue();
        if (_config.divider == 0) revert InvalidDividerValue();
        if (_config.a + _config.r > _config.divider) revert APlusRCannotBeGreaterThanDivider();
        if (_config.interval == 0) revert InvalidIntervalSecondsValue();
    }

    function _getR(bytes32 _entityId) internal view returns (uint64) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingConfigs[_entityId].r;
    }

    function _getA(bytes32 _entityId) internal view returns (uint64) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingConfigs[_entityId].a;
    }

    function _getD(bytes32 _entityId) internal view returns (uint64) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingConfigs[_entityId].divider;
    }

    function addUniqueValue(RewardsBalances memory rewards, bytes32 newValue) public pure returns (RewardsBalances memory, uint256) {
        require(rewards.currencies.length == rewards.amounts.length, "Different array lengths!");

        for (uint256 i = 0; i < rewards.currencies.length; i++) {
            if (rewards.currencies[i] == newValue) {
                return (rewards, i);
            }
        }

        RewardsBalances memory rewards_ = RewardsBalances({
            currencies: new bytes32[](rewards.currencies.length + 1),
            amounts: new uint256[](rewards.amounts.length + 1),
            lastPaidInterval: 0
        });

        for (uint64 i = 0; i < rewards.currencies.length; i++) {
            rewards_.currencies[i] = rewards.currencies[i];
            rewards_.amounts[i] = rewards.amounts[i];
            rewards_.lastPaidInterval = i;
        }

        rewards_.currencies[rewards.currencies.length] = newValue;

        return (rewards_, rewards.currencies.length);
    }

    /**
     * @dev Get the starting time of a given interval
     * @param _entityId The internal ID of the token
     * @param _interval The interval to get the time for
     */
    function _calculateStartTimeOfInterval(bytes32 _entityId, uint64 _interval) internal view returns (uint64 intervalTime_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        intervalTime_ = uint64(s.stakingConfigs[_entityId].initDate + (_interval * s.stakingConfigs[_entityId].interval));
    }

    function _calculateStartTimeOfCurrentInterval(bytes32 _entityId) internal view returns (uint64 intervalTime_) {
        intervalTime_ = _calculateStartTimeOfInterval(_entityId, _currentInterval(_entityId));
    }

    function _stakedAmount(bytes32 _stakerId, bytes32 _entityId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;
        bytes32 vTokenId0 = _vTokenId(tokenId, 0);

        return s.stakeBalance[vTokenId0][_stakerId];
    }
}
