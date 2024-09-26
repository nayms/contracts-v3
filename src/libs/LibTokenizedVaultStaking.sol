// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { StakingConfig, StakingState, RewardsBalances } from "../shared/FreeStructs.sol";

import { StakingNotStarted, StakingAlreadyStarted, IntervalRewardPayedOutAlready, InvalidAValue, InvalidRValue, InvalidDividerValue, InvalidStakingInitDate, APlusRCannotBeGreaterThanDivider, InvalidIntervalSecondsValue, InvalidTokenRewardAmount, EntityDoesNotExist, InitDateTooFar, IntervalOutOfRange, BoostMultiplierConvergenceFailure, InvalidTokenId, InvalidStakingAmount, InvalidStaker } from "../shared/CustomErrors.sol";

// solhint-disable no-console
import { console2 as c } from "forge-std/console2.sol";
import { StdStyle } from "forge-std/Test.sol";

library LibTokenizedVaultStaking {
    using StdStyle for *;

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
    function _vTokenId(bytes32 _entityId, bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32) {
        return bytes32(abi.encodePacked(bytes4(LC.OBJECT_TYPE_STAKED), _interval, bytes20(keccak256(abi.encodePacked(_entityId, _tokenId)))));
    }

    function _vTokenIdBucket(bytes32 _entityId, bytes32 _tokenId) internal pure returns (bytes32) {
        return _vTokenId(_entityId, _tokenId, type(uint64).max);
    }

    function _initStaking(bytes32 _entityId, StakingConfig calldata _config) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }

        _validateStakingParams(_config);

        if (s.stakingConfigs[_entityId].initDate == 0) {
            s.stakingConfigs[_entityId] = _config;
        } else {
            revert StakingAlreadyStarted(_entityId, _config.tokenId);
        }

        // note: Staking starts on the initDate which could be a future date relative to the current block.timestamp
        emit TokenStakingStarted(_entityId, _config.tokenId, _config.initDate, _config.a, _config.r, _config.divider, _config.interval);
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

    function _lastCollectedInterval(bytes32 _entityId, bytes32 _stakerId) internal view returns (uint64) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeCollected[_entityId][_stakerId];
    }

    function _lastPaidInterval(bytes32 _entityId) internal view returns (uint64) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeCollected[_entityId][_entityId];
    }

    function _payReward(bytes32 _stakingRewardId, bytes32 _entityId, bytes32 _rewardTokenId, uint256 _rewardAmount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (_rewardAmount <= s.objectMinimumSell[_rewardTokenId]) {
            revert InvalidTokenRewardAmount(_stakingRewardId, _entityId, _rewardTokenId, _rewardAmount);
        }

        LibObject._createObject(_stakingRewardId, LC.OBJECT_TYPE_STAKING_REWARD);

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        uint64 interval = _currentInterval(_entityId);
        bytes32 vTokenId = _vTokenId(_entityId, tokenId, interval);

        (StakingState memory stakingState, ) = _getStakingStateWithRewardsBalances(_entityId, _entityId, interval);

        if (block.timestamp < s.stakingConfigs[_entityId].initDate) {
            revert StakingNotStarted(_entityId, tokenId);
        }

        if (s.stakeCollected[_entityId][_entityId] == interval) {
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
        LibTokenizedVault._internalTransfer(_entityId, _vTokenIdBucket(_entityId, tokenId), _rewardTokenId, _rewardAmount);

        emit TokenRewardPaid(_stakingRewardId, _entityId, tokenId, _rewardTokenId, _rewardAmount);
    }

    function _stake(bytes32 _stakerId, bytes32 _entityId, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (!s.existingEntities[_stakerId]) revert EntityDoesNotExist(_stakerId);
        if (!s.existingEntities[_entityId]) revert EntityDoesNotExist(_entityId);
        if (_stakerId == _entityId) revert InvalidStaker(_stakerId);

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        if (_amount < s.objectMinimumSell[tokenId]) revert InvalidStakingAmount();

        uint64 currentInterval = _currentInterval(_entityId);
        bytes32 vTokenIdMax = _vTokenIdBucket(_entityId, tokenId);

        // First collect rewards. This will update the current state.
        _collectRewards(_stakerId, _entityId, currentInterval);

        // get the tokens
        LibTokenizedVault._internalTransfer(_stakerId, vTokenIdMax, tokenId, _amount);

        // needed for the original staked amount when unstaking
        s.stakeBalance[vTokenIdMax][_stakerId] += _amount;

        // ratio = d * (t_current - ti) / tn
        uint256 ratio;
        if (block.timestamp <= _calculateStartTimeOfCurrentInterval(_entityId)) {
            ratio = _getD(_entityId) / s.stakingConfigs[_entityId].interval;
        } else {
            ratio = (_getD(_entityId) * (block.timestamp - _calculateStartTimeOfCurrentInterval(_entityId))) / s.stakingConfigs[_entityId].interval;
        }

        uint256 boost1 = ((((_getD(_entityId) - ratio) * _amount) / _getD(_entityId)) * _getA(_entityId)) / _getD(_entityId);
        uint256 boost2 = (((ratio * _amount) / _getD(_entityId)) * _getA(_entityId)) / _getD(_entityId);
        uint256 balance1 = _amount - (ratio * _amount) / _getD(_entityId);
        uint256 balance2 = (ratio * _amount) / _getD(_entityId);

        s.stakeBalance[_vTokenId(_entityId, tokenId, currentInterval + 1)][_stakerId] += balance1 + boost1;
        s.stakeBalance[_vTokenId(_entityId, tokenId, currentInterval + 1)][_entityId] += balance1 + boost1;

        s.stakeBoost[_vTokenId(_entityId, tokenId, currentInterval + 1)][_stakerId] += (boost1 * _getR(_entityId)) / _getD(_entityId) + boost2;
        s.stakeBoost[_vTokenId(_entityId, tokenId, currentInterval + 1)][_entityId] += (boost1 * _getR(_entityId)) / _getD(_entityId) + boost2;

        s.stakeBalance[_vTokenId(_entityId, tokenId, currentInterval + 2)][_stakerId] += balance2;
        s.stakeBalance[_vTokenId(_entityId, tokenId, currentInterval + 2)][_entityId] += balance2;

        emit TokenStaked(_stakerId, _entityId, tokenId, _amount);
    }

    // Unstakes the full amount for a staker
    function _unstake(bytes32 _stakerId, bytes32 _entityId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(LibObject._isObjectType(_stakerId, LC.OBJECT_TYPE_ENTITY), "only an entity can unstake");

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        uint64 currentInterval = _currentInterval(_entityId);
        uint64 lastPaidInterval = s.stakeCollected[_entityId][_entityId];

        // must read states before the reward is claimed!
        (StakingState memory userStateAtLastPaid, ) = _getStakingStateWithRewardsBalances(_stakerId, _entityId, lastPaidInterval);
        (StakingState memory totalStateAtLastPaid, ) = _getStakingStateWithRewardsBalances(_entityId, _entityId, lastPaidInterval);

        _syncData(_stakerId, _entityId, currentInterval);
        _syncData(_entityId, _entityId, currentInterval);

        _collectRewards(_stakerId, _entityId, currentInterval); // collect rewards first, sync data up to last paid
        s.stakeCollected[_entityId][_stakerId] = currentInterval; // update collection interval, even if no reward

        // staker's balance in the past are never adjusted
        // stakers and NLF balances are adjusted in the current interval when unstaking
        // in the current interval, if a reward was paid and therefor collected, staking distribution need to be adjusted according to the balances
        if (lastPaidInterval == currentInterval && currentInterval != 0) {
            bytes32 vTokenIdLastPaid = _vTokenId(_entityId, tokenId, lastPaidInterval);
            s.stakingDistributionAmount[vTokenIdLastPaid] -= (s.stakingDistributionAmount[vTokenIdLastPaid] * userStateAtLastPaid.balance) / totalStateAtLastPaid.balance;
        }

        _adjustStateOnUnstake(_stakerId, _entityId, tokenId, currentInterval);
        _adjustStateOnUnstake(_stakerId, _entityId, tokenId, currentInterval + 1);
        _adjustStateOnUnstake(_stakerId, _entityId, tokenId, currentInterval + 2);

        bytes32 vTokenIdMax = _vTokenIdBucket(_entityId, tokenId);
        uint256 originalAmountStaked = s.stakeBalance[vTokenIdMax][_stakerId];

        s.stakeBalance[vTokenIdMax][_stakerId] = 0;

        LibTokenizedVault._internalTransfer(vTokenIdMax, _stakerId, tokenId, originalAmountStaked);

        emit TokenUnstaked(_stakerId, _entityId, tokenId, originalAmountStaked);
    }

    function _adjustStateOnUnstake(bytes32 _stakerId, bytes32 _entityId, bytes32 _tokenId, uint64 _interval) private {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 vTokenId = _vTokenId(_entityId, _tokenId, _interval);

        s.stakeBoost[vTokenId][_entityId] -= s.stakeBoost[vTokenId][_stakerId];
        s.stakeBalance[vTokenId][_entityId] -= s.stakeBalance[vTokenId][_stakerId];

        s.stakeBoost[vTokenId][_stakerId] = 0;
        s.stakeBalance[vTokenId][_stakerId] = 0;
    }

    // This function is used to calculate the correct current state for the user,
    // as well as the totals for when a staking reward distribution is made.
    function _getStakingStateWithRewardsBalances(
        bytes32 _stakerId,
        bytes32 _entityId,
        uint64 _interval
    ) internal view returns (StakingState memory state, RewardsBalances memory rewards) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;
        uint64 lastSynced = s.stakingSynced[_entityId][_stakerId];

        // Get the last interval where distribution was collected by the user.
        state.lastCollectedInterval = s.stakeCollected[_entityId][_stakerId];
        if (_interval < state.lastCollectedInterval) {
            return (state, rewards); // nothing to do, return zeroes
        }

        state.balance = s.stakeBalance[_vTokenId(_entityId, tokenId, state.lastCollectedInterval)][_stakerId];
        state.boost = s.stakeBoost[_vTokenId(_entityId, tokenId, state.lastCollectedInterval)][_stakerId];

        for (uint64 i = state.lastCollectedInterval + 1; i <= _interval; ++i) {
            if (i == lastSynced) {
                state.balance = s.stakeBalance[_vTokenId(_entityId, tokenId, i)][_stakerId];
                state.boost = s.stakeBoost[_vTokenId(_entityId, tokenId, i)][_stakerId];
            } else {
                state.balance += s.stakeBalance[_vTokenId(_entityId, tokenId, i)][_stakerId] + state.boost;
                state.boost = s.stakeBoost[_vTokenId(_entityId, tokenId, i)][_stakerId] + (state.boost * _getR(_entityId)) / _getD(_entityId);
            }

            // check to see if there are rewards for this interval, and update arrays
            uint256 totalDistributionAmount = s.stakingDistributionAmount[_vTokenId(_entityId, tokenId, i)];
            if (totalDistributionAmount > 0) {
                uint256 currencyIndex;
                (rewards, currencyIndex) = addUniqueValue(rewards, s.stakingDistributionDenomination[_vTokenId(_entityId, tokenId, i)]);

                // Use the same math as dividend distributions, assuming zero has already been collected
                uint256 userDistributionAmount = LibTokenizedVault._getWithdrawableDividendAndDeductionMath(
                    state.balance,
                    s.stakeBalance[_vTokenId(_entityId, tokenId, i)][_entityId],
                    totalDistributionAmount,
                    0
                );

                rewards.amounts[currencyIndex] += userDistributionAmount;
                rewards.lastPaidInterval = i; // interval when reward was paid out, but before the one provided as input
            }
        }
    }

    function _syncData(bytes32 _stakerId, bytes32 _entityId, uint64 _interval) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_interval <= _currentInterval(_entityId), "cannot sync after current interval");

        (StakingState memory state, ) = _getStakingStateWithRewardsBalances(_stakerId, _entityId, _interval);

        s.stakingSynced[_entityId][_stakerId] = _interval;

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;
        bytes32 vTokenId = _vTokenId(_entityId, tokenId, _interval);

        s.stakeBoost[vTokenId][_stakerId] = state.boost;
        s.stakeBalance[vTokenId][_stakerId] = state.balance;
    }

    function _collectRewards(bytes32 _stakerId, bytes32 _entityId, uint64 _interval) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(LibObject._isObjectType(_stakerId, LC.OBJECT_TYPE_ENTITY), "only an entity can collect rewards");

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;

        StakingState memory state;
        RewardsBalances memory rewards;

        (state, rewards) = _getStakingStateWithRewardsBalances(_stakerId, _entityId, _interval);
        if (rewards.currencies.length > 0) {
            if (rewards.lastPaidInterval < _interval) {
                // we must update the stake collected for the user, to the interval when that reward was actually paid out, not the current one
                // also update the state and boosts up to that interval, not later than that, that is why we make this call again with different interval
                // so that we can calculate the boosted amounts up to the desired interval
                (state, rewards) = _getStakingStateWithRewardsBalances(_stakerId, _entityId, rewards.lastPaidInterval);
            }
            bytes32 vTokenId = _vTokenId(_entityId, tokenId, rewards.lastPaidInterval);

            // Update state
            s.stakeCollected[_entityId][_stakerId] = rewards.lastPaidInterval;
            s.stakeBoost[vTokenId][_stakerId] = state.boost;
            s.stakeBalance[vTokenId][_stakerId] = state.balance;

            for (uint64 i = 0; i < rewards.currencies.length; ++i) {
                LibTokenizedVault._internalTransfer(_vTokenIdBucket(_entityId, tokenId), _stakerId, rewards.currencies[i], rewards.amounts[i]);
                emit TokenRewardCollected(_stakerId, _entityId, tokenId, _interval, rewards.currencies[i], rewards.amounts[i]);
            }
        }
    }

    function _validateStakingParams(StakingConfig calldata _config) internal view {
        if (_config.a == 0) revert InvalidAValue();
        if (_config.r == 0) revert InvalidRValue();
        if (_config.divider == 0) revert InvalidDividerValue();
        if (_config.a + _config.r > _config.divider) revert APlusRCannotBeGreaterThanDivider();
        if (_config.a + _config.r != _config.divider) revert BoostMultiplierConvergenceFailure(_config.a, _config.r, _config.divider);
        if (_config.interval == 0) revert InvalidIntervalSecondsValue();
        if (_config.interval < LC.MIN_STAKING_INTERVAL || _config.interval > LC.MAX_STAKING_INTERVAL) revert IntervalOutOfRange(_config.interval);
        if (_config.initDate <= block.timestamp) revert InvalidStakingInitDate();
        if (_config.initDate > block.timestamp + LC.MAX_INIT_DATE_PERIOD) revert InitDateTooFar(_config.initDate);
        if (_config.tokenId == 0) revert InvalidTokenId();
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

    function addUniqueValue(RewardsBalances memory rewards, bytes32 newValue) internal pure returns (RewardsBalances memory, uint256) {
        require(rewards.currencies.length == rewards.amounts.length, "Different array lengths!");

        uint256 length = rewards.currencies.length;
        for (uint256 i = 0; i < length; i++) {
            if (rewards.currencies[i] == newValue) {
                return (rewards, i);
            }
        }

        // prettier-ignore
        RewardsBalances memory rewards_ = RewardsBalances({
            currencies: new bytes32[](length + 1),
            amounts: new uint256[](rewards.amounts.length + 1),
            lastPaidInterval: 0
        });

        for (uint64 i = 0; i < length; i++) {
            rewards_.currencies[i] = rewards.currencies[i];
            rewards_.amounts[i] = rewards.amounts[i];
            rewards_.lastPaidInterval = i;
        }

        rewards_.currencies[length] = newValue;

        return (rewards_, length);
    }

    /**
     * @dev Get the starting time of a given interval
     * @param _entityId The internal ID of the token
     * @param _interval The interval to get the time for
     */
    function _calculateStartTimeOfInterval(bytes32 _entityId, uint64 _interval) internal view returns (uint64 intervalTime_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        intervalTime_ = SafeCastLib.toUint64(s.stakingConfigs[_entityId].initDate + (_interval * s.stakingConfigs[_entityId].interval));
    }

    function _calculateStartTimeOfCurrentInterval(bytes32 _entityId) internal view returns (uint64 intervalTime_) {
        intervalTime_ = _calculateStartTimeOfInterval(_entityId, _currentInterval(_entityId));
    }

    function _stakedAmount(bytes32 _stakerId, bytes32 _entityId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;
        bytes32 vTokenIdMax = _vTokenIdBucket(_entityId, tokenId);

        return s.stakeBalance[vTokenIdMax][_stakerId];
    }

    function _getStakingAmounts(bytes32 _stakerId, bytes32 _entityId) internal view returns (uint256 stakedBalance_, uint256 boostedBalance_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint64 currentInterval = _currentInterval(_entityId);
        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;
        stakedBalance_ = _stakedAmount(_stakerId, _entityId);

        if (!_isStakingInitialized(_entityId)) {
            // boost is always 1 before init
            return (stakedBalance_, boostedBalance_);
        }

        // we need to read the state at current interval + 2 (c+2) since the balance is always written to the future intervals when staking
        // however this method will return future state including the boost the user will only qualify for, at the time of [c+2]
        (StakingState memory state, ) = _getStakingStateWithRewardsBalances(_stakerId, _entityId, currentInterval + 2);

        // user only qualifies for boost up to the current interval [c]
        // so we need to undo the boost for balance[c+1] and balance[c+2]
        // boost for c+1 is already calculated into the balance at [c+1]
        // so that deboost factor will always be balance[c+1] * (d - (d^2) / (a + d))
        // mind the integer math here, whatever we multiply with this factor has to be divided by d
        uint256 reverseBoostFactor = _getD(_entityId) - ((_getD(_entityId) * _getD(_entityId)) / (_getA(_entityId) + _getD(_entityId)));
        uint256 boost1 = (s.stakeBalance[_vTokenId(_entityId, tokenId, currentInterval + 1)][_stakerId] * reverseBoostFactor) / _getD(_entityId);

        // boost at [c+1] is what applies to balance[c+2] so that one also needs to be taken out of the final boosted balance
        uint256 boost2 = s.stakeBoost[_vTokenId(_entityId, tokenId, currentInterval + 1)][_stakerId];

        boostedBalance_ = state.balance - boost1 - boost2;

        if (boostedBalance_ < stakedBalance_) {
            boostedBalance_ = stakedBalance_;
        }
    }
}
