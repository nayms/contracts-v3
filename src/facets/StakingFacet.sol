// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibTokenizedVaultStaking, StakeConfig } from "../libs/LibTokenizedVaultStaking.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";
import { Modifiers } from "../shared/Modifiers.sol";

contract StakingFacet is Modifiers {
    using LibHelpers for address;

    function vTokenId(bytes32 _tokenId, uint64 _interval) external pure returns (bytes32) {
        return LibTokenizedVaultStaking._vTokenId(_tokenId, _interval);
    }

    function updateStakingParamsWithDefaults(bytes32 _tokenId) external {
        LibTokenizedVaultStaking._updateStakingParams(_tokenId);
    }

    function updateStakingParams(bytes32 _tokenId, uint64 a, uint64 r, uint64 divider, uint64 intervalSeconds) external {
        LibTokenizedVaultStaking._updateStakingParams(_tokenId, a, r, divider, intervalSeconds);
    }

    function stakeConfigs(bytes32 _tokenId) external view returns (StakeConfig memory stakeConfig) {
        stakeConfig = LibTokenizedVaultStaking._stakeConfigs(_tokenId);
    }

    function initStaking(bytes32 _tokenId) external {
        LibTokenizedVaultStaking._initStaking(_tokenId);
    }

    function currentInterval(bytes32 _tokenId) external view returns (uint64 interval_) {
        interval_ = LibTokenizedVaultStaking._currentInterval(_tokenId);
    }

    function stake(bytes32 _tokenId, uint256 _amount) external {
        bytes32 parentId = LibObject._getParent(msg.sender._getIdForAddress());
        LibTokenizedVaultStaking._stake(parentId, _tokenId, _amount);
    }

    function lastCollectedInterval(bytes32 _tokenId, bytes32 _ownerId) external view returns (uint64 interval_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        interval_ = s.stakeCollected[_tokenId][_ownerId];
    }

    function lastIntervalPaid(bytes32 _tokenId) external view returns (uint64 interval_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        interval_ = s.stakeCollected[_tokenId][_tokenId];
    }

    function calculateStartTimeOfInterval(bytes32 _tokenId, uint64 _interval) external view returns (uint256 startTime_) {
        startTime_ = LibTokenizedVaultStaking._calculateStartTimeOfInterval(_tokenId, _interval);
    }

    function calculateStartTimeOfCurrentInterval(bytes32 _tokenId) external view returns (uint256 startTime_) {
        startTime_ = LibTokenizedVaultStaking._calculateStartTimeOfCurrentInterval(_tokenId);
    }

    function unstake(bytes32 _ownerId, bytes32 _tokenId) external {
        LibTokenizedVaultStaking._unstake(_ownerId, _tokenId);
    }

    function rewardsBalance(bytes32 _ownerId, bytes32 _tokenId) external view returns (bytes32[] memory rewardCurrencies_, uint256[] memory rewardAmounts_) {
        uint64 interval_ = LibTokenizedVaultStaking._currentInterval(_tokenId);
        (, , , rewardCurrencies_, rewardAmounts_) = LibTokenizedVaultStaking._getRewardsStateWithRewardsBalances(_ownerId, _tokenId, interval_);
    }

    function payReward(bytes32 _tokenId, bytes32 _rewardTokenId, uint256 _amount) external {
        LibTokenizedVaultStaking._payReward(_tokenId, _rewardTokenId, _amount);
    }

    function currrentVtokenBalance(bytes32 _ownerId, bytes32 _tokenId) external view returns (uint256 vTokenBalance_) {
        vTokenBalance_ = LibTokenizedVaultStaking._currentVtokenBalance(_ownerId, _tokenId);
    }
}
