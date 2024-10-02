// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibTokenizedVaultStaking, StakingConfig } from "../libs/LibTokenizedVaultStaking.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { Modifiers } from "../shared/Modifiers.sol";
import { RewardsBalances } from "../shared/FreeStructs.sol";

contract StakingFacet is Modifiers {
    using LibHelpers for address;

    /**
     * @notice Staking ID for given token ID, entity ID and interval
     * @param _entityId staking entity ID
     * @param _tokenId token ID
     * @param _interval staking interval
     * @return vTokenId
     */
    function vTokenId(bytes32 _entityId, bytes32 _tokenId, uint64 _interval) external pure returns (bytes32) {
        return LibTokenizedVaultStaking._vTokenId(_entityId, _tokenId, _interval);
    }

    /**
     * @notice Get the current interval for a staking entity
     * @param _entityId staking entity ID
     * @return current interval
     */
    function currentInterval(bytes32 _entityId) external view returns (uint64) {
        return LibTokenizedVaultStaking._currentInterval(_entityId);
    }

    /**
     * @notice Get the configuration for a staking entity
     * @param _entityId staking entity ID
     * @return staking configuration
     */
    function getStakingConfig(bytes32 _entityId) external view returns (StakingConfig memory) {
        return LibTokenizedVaultStaking._stakingConfig(_entityId);
    }

    /**
     * @notice Initialize the configuration for a staking entity
     * @param _entityId staking entity ID
     * @param _config staking configuration
     */
    function initStaking(bytes32 _entityId, StakingConfig calldata _config) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibTokenizedVaultStaking._initStaking(_entityId, _config);
    }

    /**
     * @notice Stake tokens into a staking entity
     * @param _entityId staking entity ID
     * @param _amount staking amount
     */
    function stake(bytes32 _entityId, uint256 _amount) external notLocked {
        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);
        LibTokenizedVaultStaking._stake(parentId, _entityId, _amount);
    }

    /**
     * @notice Unstake tokens from a staking entity
     * @param _entityId staking entity ID
     */
    function unstake(bytes32 _entityId) external notLocked {
        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);
        LibTokenizedVaultStaking._unstake(parentId, _entityId);
    }

    /**
     * @notice Last interval reward was collected by the user entity
     * @param _entityId staking entity ID
     * @param _stakerId staker ID
     * @return last collected interval
     */
    function lastCollectedInterval(bytes32 _entityId, bytes32 _stakerId) external view returns (uint64) {
        return LibTokenizedVaultStaking._lastCollectedInterval(_entityId, _stakerId);
    }

    /**
     * @notice Last interval reward was paid out by the staking entity
     * @param _entityId staking entity ID
     * @return last paid interval
     */
    function lastPaidInterval(bytes32 _entityId) external view returns (uint64) {
        return LibTokenizedVaultStaking._lastPaidInterval(_entityId);
    }

    /**
     * @notice Calculates the start time of an interval
     * @param _entityId staking entity ID
     * @param _interval interval
     * @return start of interval
     */
    function calculateStartTimeOfInterval(bytes32 _entityId, uint64 _interval) external view returns (uint256) {
        return LibTokenizedVaultStaking._calculateStartTimeOfInterval(_entityId, _interval);
    }

    /**
     * @notice Calculates the start time of a current interval
     * @param _entityId staking entity ID
     * @return start of current interval
     */
    function calculateStartTimeOfCurrentInterval(bytes32 _entityId) external view returns (uint256) {
        return LibTokenizedVaultStaking._calculateStartTimeOfCurrentInterval(_entityId);
    }

    /**
     * @notice Gets the reward balance for a staker
     * @param _stakerId staker ID
     * @param _entityId entity ID
     * @return rewardCurrencies_ currencies in which rewards are distributed
     * @return rewardAmounts_ amounts distributed for respective currencies
     */
    function getRewardsBalance(bytes32 _stakerId, bytes32 _entityId) external view returns (bytes32[] memory rewardCurrencies_, uint256[] memory rewardAmounts_) {
        uint64 interval_ = LibTokenizedVaultStaking._currentInterval(_entityId);

        (, RewardsBalances memory b) = LibTokenizedVaultStaking._getStakingStateWithRewardsBalances(_stakerId, _entityId, interval_);

        rewardCurrencies_ = b.currencies;
        rewardAmounts_ = b.amounts;
    }

    /**
     * @notice Collect rewards for a staker
     * @param _entityId staking entity ID
     */
    function collectRewards(bytes32 _entityId) external notLocked {
        bytes32 parentId = LibObject._getParent(msg.sender._getIdForAddress());
        uint64 lastPaid = LibTokenizedVaultStaking._lastPaidInterval(_entityId);

        LibTokenizedVaultStaking._collectRewards(parentId, _entityId, lastPaid);
    }

    /**
     * @notice Pay out a reward to stakers
     * @param _stakingRewardId unique staking reward GUID
     * @param _entityId entity ID
     * @param _rewardTokenId currency ID of the reward
     * @param _amount reward amount
     */
    function payReward(bytes32 _stakingRewardId, bytes32 _entityId, bytes32 _rewardTokenId, uint256 _amount) external notLocked assertPrivilege(_entityId, LC.GROUP_ENTITY_ADMINS) {
        LibTokenizedVaultStaking._payReward(_stakingRewardId, _entityId, _rewardTokenId, _amount);
    }

    /**
     * @notice Gets the staked amount for a staker, with and without boost applied to it
     * @param _stakerId staker ID
     * @param _entityId staking entity ID
     * @return stakedAmount_ total amount staked
     * @return boostedAmount_ boosted staked amount, total amount with boost applied to it
     */
    function getStakingAmounts(bytes32 _stakerId, bytes32 _entityId) external view returns (uint256 stakedAmount_, uint256 boostedAmount_) {
        return LibTokenizedVaultStaking._getStakingAmounts(_stakerId, _entityId);
    }
}
