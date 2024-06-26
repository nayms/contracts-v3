// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibTokenizedVaultStaking, StakingConfig } from "../libs/LibTokenizedVaultStaking.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { Modifiers } from "../shared/Modifiers.sol";
import { RewardsBalances, StakingState } from "../shared/FreeStructs.sol";

contract StakingFacet is Modifiers {
    using LibHelpers for address;

    function vTokenId(bytes32 _tokenId, uint64 _interval) external pure returns (bytes32) {
        return LibTokenizedVaultStaking._vTokenId(_tokenId, _interval);
    }

    function currentInterval(bytes32 _entityId) external view returns (uint64) {
        return LibTokenizedVaultStaking._currentInterval(_entityId);
    }

    function getStakingConfig(bytes32 _entityId) external view returns (StakingConfig memory) {
        return LibTokenizedVaultStaking._stakingConfig(_entityId);
    }

    function initStaking(bytes32 _entityId, StakingConfig calldata _config) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibTokenizedVaultStaking._initStaking(_entityId, _config);
    }

    function stake(bytes32 _entityId, uint256 _amount) external notLocked(msg.sig) {
        bytes32 parentId = LibObject._getParent(msg.sender._getIdForAddress());
        LibTokenizedVaultStaking._stake(parentId, _entityId, _amount);
    }

    function unstake(bytes32 _entityId) external notLocked(msg.sig) {
        bytes32 parentId = LibObject._getParent(msg.sender._getIdForAddress());
        LibTokenizedVaultStaking._unstake(parentId, _entityId);
    }

    function lastCollectedInterval(bytes32 _entityId, bytes32 _stakerId) external view returns (uint64) {
        return LibTokenizedVaultStaking._lastCollectedInterval(_entityId, _stakerId);
    }

    function lastPaidInterval(bytes32 _entityId) external view returns (uint64) {
        return LibTokenizedVaultStaking._lastPaidInterval(_entityId);
    }

    function calculateStartTimeOfInterval(bytes32 _entityId, uint64 _interval) external view returns (uint256) {
        return LibTokenizedVaultStaking._calculateStartTimeOfInterval(_entityId, _interval);
    }

    function calculateStartTimeOfCurrentInterval(bytes32 _entityId) external view returns (uint256) {
        return LibTokenizedVaultStaking._calculateStartTimeOfCurrentInterval(_entityId);
    }

    function getRewardsBalance(bytes32 _stakerId, bytes32 _entityId) external view returns (bytes32[] memory rewardCurrencies_, uint256[] memory rewardAmounts_) {
        uint64 interval_ = LibTokenizedVaultStaking._currentInterval(_entityId);

        (, RewardsBalances memory b) = LibTokenizedVaultStaking._getStakingStateWithRewardsBalances(_stakerId, _entityId, interval_);

        rewardCurrencies_ = b.currencies;
        rewardAmounts_ = b.amounts;
    }

    function collectRewards(bytes32 _entityId) external notLocked(msg.sig) {
        bytes32 parentId = LibObject._getParent(msg.sender._getIdForAddress());
        uint64 lastPaid = LibTokenizedVaultStaking._lastPaidInterval(_entityId);

        LibTokenizedVaultStaking._collectRewards(parentId, _entityId, lastPaid);
    }

    function getStakingState(bytes32 _stakerId, bytes32 _entityId) external view returns (StakingState memory) {
        uint64 interval = LibTokenizedVaultStaking._currentInterval(_entityId);
        (StakingState memory state, ) = LibTokenizedVaultStaking._getStakingStateWithRewardsBalances(_stakerId, _entityId, interval);
        return state;
    }

    function payReward(
        bytes32 _stakingRewardId,
        bytes32 _entityId,
        bytes32 _rewardTokenId,
        uint256 _amount
    ) external notLocked(msg.sig) assertPrivilege(_entityId, LC.GROUP_ENTITY_ADMINS) {
        LibTokenizedVaultStaking._payReward(_stakingRewardId, _entityId, _rewardTokenId, _amount);
    }

    function getStakingAmounts(bytes32 _stakerId, bytes32 _entityId) external view returns (uint256 stakedAmount_, uint256 boostedAmount_) {
        uint64 interval = LibTokenizedVaultStaking._currentInterval(_entityId);
        (StakingState memory state, ) = LibTokenizedVaultStaking._getStakingStateWithRewardsBalances(_stakerId, _entityId, interval);
        stakedAmount_ = LibTokenizedVaultStaking._stakedAmount(_stakerId, _entityId);
        boostedAmount_ = state.balance;
    }
}
