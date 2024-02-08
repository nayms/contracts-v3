// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { StakeConfig } from "../shared/FreeStructs.sol";

library LibTokenizedVaultStaking {
    event DebugStake(bytes32 tokenId, bytes32 ownerId);
    //     event DebugBoost(uint256 boostTotal, uint256 blockTimestamp, uint64 startTimeOfCurrentInterval, uint64 interval);
    //     event DebugBoost2(uint256 boost1, uint256 boost2);
    //     event DebugStakeBoost(uint256 stakeBoostOwner1, uint256 stakeBoostOwner2, uint256 stakeBoostToken1, uint256 stakeBoostToken2);
    event StakingParamsUpdated(bytes32 indexed tokenId, uint64 a, uint64 r, uint64 divider, uint64 interval);

    event StakingStarted(bytes32 indexed tokenId, uint256 initDate);
    //     /**
    //      * @dev Emitted when a user stakes tokens.
    //      * @param ownerId Id of owner
    //      * @param tokenId ID of token
    //      * @param amountStaked amount staked
    //      * @param totalAmountStaked total amount staked
    //      */
    //     event InternalTokensStaked(bytes32 indexed ownerId, bytes32 tokenId, uint256 amountStaked, uint256 totalAmountStaked);
    //     /**
    //      * @dev Emitted when a user unstakes tokens.
    //      * @param ownerId Id of owner
    //      * @param tokenId ID of token
    //      * @param totalAmountUnstaked total amount staked
    //      */
    //     event InternalTokensUnstaked(bytes32 indexed ownerId, bytes32 tokenId, uint256 totalAmountUnstaked);
    //     error StakingAlreadyInitialized(bytes32 tokenId);
    error StakingAlreadyStarted(bytes32 tokenId);

    /**
     * @dev First 4 bytes: "VTOK", next 8 bytes: interval, next 20 bytes: right 20 bytes of tokenId
     * @param _tokenId The internal ID of the token.
     * @param _interval The interval of staking.
     */
    function _vTokenId(bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32 vTokenId_) {
        // Todo: fix this for NAYM token ID since it's right padded with 0s instead of left padded
        // Todo: Give vTokens a dedicated prefix to avoid collisions!!!
        vTokenId_ = bytes32(abi.encodePacked(bytes4(LC.OBJECT_TYPE_STAKED), _interval, _tokenId << 96));
    }

    /**
     * @dev Initialize AppStorage.stakeConfigs for a token. These are the staking configurations for a token.
     * @param _tokenId The internal ID of the token
     */
    function _updateStakingParams(bytes32 _tokenId) internal {
        _updateStakingParams(_tokenId, 150000000, 850000000, 1000000000, 30 days);
    }

    /**
     * @dev Initialize AppStorage.stakeConfigs for a token. These are the staking configurations for a token.
     * @param _tokenId The internal ID of the token
     * @param a The initial boost factor
     * @param r The boost reduction per interval
     * @param divider The divider for the boost
     * @param intervalSeconds The interval in seconds
     */
    function _updateStakingParams(bytes32 _tokenId, uint64 a, uint64 r, uint64 divider, uint64 intervalSeconds) internal {
        // Staking for an ID can only be initialized once
        // Stake.lastStakePaid on bucket 0, for the tokenid, is set to the init timestamp.
        // It is possible for stakers to exist before staking is initialized, but they will only start earming rewards after initialization
        AppStorage storage s = LibAppStorage.diamondStorage();
        _validateStakingParams(a, r, divider, intervalSeconds);
        s.stakeConfigs[_tokenId] = StakeConfig({ initDate: 0, a: a, r: r, divider: divider, interval: intervalSeconds });
        emit StakingParamsUpdated(_tokenId, a, r, divider, intervalSeconds);
    }

    function _initStaking(bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // todo validate args
        if (s.stakeConfigs[_tokenId].initDate == 0) {
            s.stakeConfigs[_tokenId].initDate = block.timestamp;
        } else {
            revert StakingAlreadyStarted(_tokenId);
        }
        emit StakingStarted(_tokenId, block.timestamp);
    }

    function _isStakingInitialized(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.stakeConfigs[_tokenId].initDate < block.timestamp);
    }

    function _stakeConfigs(bytes32 _tokenId) internal view returns (StakeConfig memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeConfigs[_tokenId];
    }

    function _currentInterval(bytes32 _tokenId) internal view returns (uint64 currentInterval_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.stakeConfigs[_tokenId].initDate == 0) {
            currentInterval_ = 0;
        } else {
            currentInterval_ = uint64((block.timestamp - s.stakeConfigs[_tokenId].initDate) / s.stakeConfigs[_tokenId].interval);
        }
    }

    function _payReward(bytes32 _tokenId, bytes32 _rewardTokenId, uint256 _rewardAmount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // get the current state
        // I need to wait for the interval to finish, so the
        uint64 interval = _currentInterval(_tokenId);
        bytes32 vTokenId = _vTokenId(_tokenId, interval);
        (uint256 balanceAtInterval_, uint256 boostAtInterval_, uint64 lastCollectedInterval_) = _getRewardsState(_tokenId, _tokenId, interval);

        s.stakingDistributionAmount[vTokenId] = _rewardAmount;
        s.stakingDistributionDenomination[vTokenId] = _rewardTokenId;

        //No money needs to actually be transferred
        s.stakeBalance[vTokenId][_tokenId] += balanceAtInterval_;
        s.stakeBoost[vTokenId][_tokenId] += boostAtInterval_;

        s.stakeBalance[vTokenId][_tokenId] += _rewardAmount;
        s.stakeBoost[vTokenId][_tokenId] += (_rewardAmount * _getA(_tokenId)) / _getD(_tokenId);
    }

    function _stake(bytes32 _stakerId, bytes32 _tokenId, uint256 _amount) internal {
        emit DebugStake(_tokenId, _stakerId);
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint64 currentInterval = _currentInterval(_tokenId);
        bytes32 vTokenId = _vTokenId(_tokenId, currentInterval);
        bytes32 nextVTokenId = _vTokenId(_tokenId, currentInterval + 1);

        // First collect rewards. This will update the current state.
        _collectRewards(_stakerId, _tokenId, currentInterval);

        //firset get the money
        LibTokenizedVault._internalTransfer(_stakerId, _tokenId, _tokenId, _amount);

        // update the share of the staking reward
        s.stakeBalance[vTokenId][_stakerId] += _amount;

        // update the boosts on the current and next intervals depending on time
        uint256 boostTotal = (_amount * _getA(_tokenId)) / _getD(_tokenId);
        uint256 boostNext = (boostTotal * (block.timestamp - _calculateStartTimeOfCurrentInterval(_tokenId))) / s.stakeConfigs[_tokenId].interval;
        uint256 boost = boostTotal - boostNext;
        // give to the staker
        s.stakeBoost[vTokenId][_stakerId] += boost;
        s.stakeBoost[nextVTokenId][_stakerId] += boostNext;

        //give to the totals!!!
        s.stakeBoost[vTokenId][_tokenId] += boost;
        s.stakeBoost[nextVTokenId][_tokenId] += boostNext;
    }

    // Unstakes the full amount for a staker
    function _unstake(bytes32 _stakerId, bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint64 currentInterval = _currentInterval(_tokenId);
        bytes32 vTokenId0 = _vTokenId(_tokenId, 0);
        bytes32 vTokenId = _vTokenId(_tokenId, currentInterval);

        //collect your rewards first
        _collectRewards(_stakerId, _tokenId, currentInterval);

        // Set boost and rewards to zero
        s.stakeBoost[vTokenId][_stakerId] = 0;
        s.stakeBalance[vTokenId][_stakerId] = 0;

        uint256 originalAmountStaked = s.stakeBalance[vTokenId0][_stakerId];
        s.stakeBalance[vTokenId0][_stakerId] = 0;
        LibTokenizedVault._internalTransfer(_tokenId, _stakerId, _tokenId, originalAmountStaked);
    }

    // This function is used to calculate the correct current state for the user,
    // as well as the totals for when a staking reward distribution is made.
    function _getRewardsStateWithRewardsBalances(
        bytes32 _stakerId,
        bytes32 _tokenId,
        uint64 _interval
    )
        internal
        view
        returns (
            uint256 balanceAtInterval_,
            uint256 boostAtInterval_,
            uint64 lastCollectedInterval_,
            bytes32[] memory rewardCurrenciesAtInterval_,
            uint256[] memory rewardAmountsAtInterval_
        )
    {
        // Rewards can be made in various denominations, but only 1 denomination per
        // interval. This limits the size of the array.
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (_isStakingInitialized(_tokenId)) {
            revert("staking hasnt started");
        }
        bytes32 vTokenId;
        bytes32 nextVTokenId;
        uint256 dAmount;
        // Get the last interval where distribution was collected by the user.
        lastCollectedInterval_ = s.stakeCollected[_tokenId][_stakerId];
        // Get the current interval
        uint64 currentInterval = _currentInterval(_tokenId);
        if (_interval <= lastCollectedInterval_) {
            revert("rewards already collected");
        }
        if (_interval > currentInterval) {
            revert("interval is in the future");
        }
        // reward[i+1] = reward[i] + boost[i]
        // boost[i+1] = boost[i] * r
        // Iterate through and add the boosts that the user should have until we reach the specified interval.
        uint256 totalDistributionAmount;
        uint256 userDistributionAmount;
        bytes32 stakingDistributionDenomination;
        uint256 currencyIndex;
        for (uint64 i = lastCollectedInterval_; i < _interval; ++i) {
            vTokenId = _vTokenId(_tokenId, lastCollectedInterval_);
            nextVTokenId = _vTokenId(_tokenId, i + 1);

            balanceAtInterval_ = s.stakeBalance[vTokenId][_stakerId] + s.stakeBoost[vTokenId][_stakerId];
            boostAtInterval_ = s.stakeBoost[nextVTokenId][_stakerId] + (s.stakeBoost[vTokenId][_stakerId] * _getR(_tokenId)) / _getD(_tokenId);

            // check to see if there are rewards for this interval, and update arrays
            totalDistributionAmount = s.stakingDistributionAmount[vTokenId];
            if (totalDistributionAmount > 0) {
                stakingDistributionDenomination = s.stakingDistributionDenomination[vTokenId];
                (rewardCurrenciesAtInterval_, currencyIndex) = addUniqueValue(rewardCurrenciesAtInterval_, stakingDistributionDenomination);

                // Use the same math as dividend distributions, assuming zero has already been collected
                userDistributionAmount = LibTokenizedVault._getWithdrawableDividendAndDeductionMath(
                    s.stakeBalance[vTokenId][_stakerId],
                    s.stakeBalance[vTokenId][vTokenId],
                    totalDistributionAmount,
                    0
                );

                rewardAmountsAtInterval_[currencyIndex] += userDistributionAmount;
            }
        }
    }

    function _getRewardsState(
        bytes32 _stakerId,
        bytes32 _tokenId,
        uint64 _interval
    ) internal view returns (uint256 balanceAtInterval_, uint256 boostAtInterval_, uint64 lastCollectedInterval_) {
        // Rewards can be made in various denominations, but only 1 denomination per
        // interval. This limits the size of the array.
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (_isStakingInitialized(_tokenId)) {
            revert("staking hasnt started");
        }
        bytes32 vTokenId;
        bytes32 nextVTokenId;
        uint256 dAmount;
        // Get the last interval where distribution was collected by the user.
        lastCollectedInterval_ = s.stakeCollected[_tokenId][_stakerId];
        // Get the current interval
        uint64 currentInterval = _currentInterval(_tokenId);
        if (_interval <= lastCollectedInterval_) {
            revert("rewards already collected");
        }
        if (_interval > currentInterval) {
            revert("interval is in the future");
        }

        // reward[i+1] = reward[i] + boost[i]
        // boost[i+1] = boost[i] * r
        // Iterate through and add the boosts that the user should have until we reach the specified interval.
        for (uint64 i = lastCollectedInterval_; i < _interval; ++i) {
            vTokenId = _vTokenId(_tokenId, lastCollectedInterval_);
            nextVTokenId = _vTokenId(_tokenId, i + 1);

            balanceAtInterval_ = s.stakeBalance[vTokenId][_stakerId] + s.stakeBoost[vTokenId][_stakerId];
            boostAtInterval_ = s.stakeBoost[nextVTokenId][_stakerId] + (s.stakeBoost[vTokenId][_stakerId] * _getR(_tokenId)) / _getD(_tokenId);
        }
    }

    function _collectRewards(bytes32 _stakerId, bytes32 _tokenId, uint64 _interval) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        (
            uint256 balanceAtInterval_,
            uint256 boostAtInterval_,
            uint64 lastCollectedInterval_,
            bytes32[] memory rewardCurrenciesAtInterval_,
            uint256[] memory rewardAmountsAtInterval_
        ) = _getRewardsStateWithRewardsBalances(_stakerId, _tokenId, _interval);

        bytes32 vTokenId;
        if (rewardCurrenciesAtInterval_.length > 0) {
            // Update state
            vTokenId = _vTokenId(_tokenId, _interval);
            s.stakeCollected[_tokenId][_stakerId] = _interval;
            s.stakeBoost[vTokenId][_stakerId] = boostAtInterval_;
            s.stakeBalance[vTokenId][_stakerId] = balanceAtInterval_;

            for (uint64 i = 0; i < rewardCurrenciesAtInterval_.length; ++i) {
                LibTokenizedVault._internalTransfer(_tokenId, _stakerId, rewardCurrenciesAtInterval_[i], rewardAmountsAtInterval_[i]);
            }
        }
    }

    error InvalidAValue();
    error InvalidRValue();
    error InvalidDividerValue();
    error APlusRCannotBeGreaterThanDivider();
    error InvalidIntervalSecondsValue();

    function _validateStakingParams(uint64 a, uint64 r, uint64 divider, uint64 intervalSeconds) internal pure {
        if (a == 0) revert InvalidAValue();
        if (r == 0) revert InvalidRValue();
        if (divider == 0) revert InvalidDividerValue();
        if (a + r > divider) revert APlusRCannotBeGreaterThanDivider();
        if (intervalSeconds == 0) revert InvalidIntervalSecondsValue();
    }

    function _getR(bytes32 _tokenId) internal view returns (uint64) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeConfigs[_tokenId].r;
    }

    function _getA(bytes32 _tokenId) internal view returns (uint64) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeConfigs[_tokenId].a;
    }

    function _getD(bytes32 _tokenId) internal view returns (uint64) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeConfigs[_tokenId].divider;
    }

    function addUniqueValue(bytes32[] memory existingArray, bytes32 newValue) public pure returns (bytes32[] memory, uint256) {
        bool exists = false;
        uint256 index;

        for (uint256 i = 0; i < existingArray.length; i++) {
            if (existingArray[i] == newValue) {
                exists = true;
                index = i;
                break;
            }
        }

        if (!exists) {
            bytes32[] memory newArray = new bytes32[](existingArray.length + 1);
            for (uint256 i = 0; i < existingArray.length; i++) {
                newArray[i] = existingArray[i];
            }
            newArray[existingArray.length] = newValue;
            return (newArray, existingArray.length);
        }

        return (existingArray, index);
    }

    /**
     * @dev Get the starting time of a given interval
     * @param _tokenId The internal ID of the token
     * @param _interval The interval to get the time for
     */
    function _calculateStartTimeOfInterval(bytes32 _tokenId, uint64 _interval) internal view returns (uint64 intervalTime_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        intervalTime_ = uint64(s.stakeConfigs[_tokenId].initDate + (_interval * s.stakeConfigs[_tokenId].interval));
    }

    function _calculateStartTimeOfCurrentInterval(bytes32 _tokenId) internal view returns (uint64 intervalTime_) {
        intervalTime_ = _calculateStartTimeOfInterval(_tokenId, _currentInterval(_tokenId));
    }

    function _currentVtokenBalance(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeRewardShare[_tokenId][_ownerId];
    }
}
