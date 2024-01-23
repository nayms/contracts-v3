// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibTokenizedVaultStaking, StakeConfig } from "../libs/LibTokenizedVaultStaking.sol";

import { Modifiers } from "../shared/Modifiers.sol";
contract StakingFacet {
    function vTokenId(bytes32 _tokenId, uint64 _interval) external pure returns (bytes32) {
        return LibTokenizedVaultStaking._vTokenId(_tokenId, _interval);
    }

    function updateStakingParams(bytes32 _tokenId) external {
        LibTokenizedVaultStaking._updateStakingParams(_tokenId);
    }
    // function initStaking(bytes32 _tokenId, uint64 a, uint64 r, uint64 divider, uint64 intervalSeconds) external {
    //     LibTokenizedVaultStaking._initStaking(_tokenId, a, r, divider, intervalSeconds);
    // }

    function stakeConfigs(bytes32 _tokenId) external view returns (StakeConfig memory stakeConfig) {
        stakeConfig = LibTokenizedVaultStaking._stakeConfigs(_tokenId);
    }

    function startStaking(bytes32 _tokenId) external {
        LibTokenizedVaultStaking._startStaking(_tokenId);
    }

    function currentInterval(bytes32 _tokenId) external view returns (uint64 interval_) {
        interval_ = LibTokenizedVaultStaking._currentInterval(_tokenId);
    }

    function stake(bytes32 _ownerId, bytes32 _tokenId, uint256 _amount) external {
        LibTokenizedVaultStaking._stake(_ownerId, _tokenId, _amount);
    }

    function calculateStartTimeOfInterval(bytes32 _tokenId, uint64 _interval) external view returns (uint256 startTime_) {
        startTime_ = LibTokenizedVaultStaking._calculateStartTimeOfInterval(_tokenId, _interval);
    }
    function calculateStartTimeOfCurrentInterval(bytes32 _tokenId) external view returns (uint256 startTime_) {
        startTime_ = LibTokenizedVaultStaking._calculateStartTimeOfCurrentInterval(_tokenId);
    }

    function unstakeAll(bytes32 _ownerId, bytes32 _tokenId) external {
        LibTokenizedVaultStaking._unstakeAll(_ownerId, _tokenId);
    }

    function rewardsBalance(bytes32 _ownerId, bytes32 _tokenId, bytes32 _dividendTokenId) external view returns (uint256 rewardsBalance_) {
        rewardsBalance_ = LibTokenizedVaultStaking._rewardsBalance(_ownerId, _tokenId, _dividendTokenId);
    }

    function payDistribution(bytes32 _guid, bytes32 _from, bytes32 _ownerId, bytes32 _tokenId, bytes32 _rewardTokenId, uint256 _amount) external {
        LibTokenizedVaultStaking._payDistribution(_guid, _from, _ownerId, _tokenId, _rewardTokenId, _amount);
    }

    function currentOwedBoost(bytes32 _ownerId, bytes32 _tokenId) external view returns (uint256 owedBoost_, uint256 currentBoost_) {
        (owedBoost_, currentBoost_) = LibTokenizedVaultStaking._currentOwedBoost(_ownerId, _tokenId);
    }

    function owedBoostAtInterval(bytes32 _ownerId, bytes32 _tokenId) external view returns (uint256 owedBoost_, uint256 currentBoost_) {
        (owedBoost_, currentBoost_) = LibTokenizedVaultStaking._owedBoostAtInterval(_ownerId, _tokenId);
    }

    // function currrentVtokenBalance(bytes32 _ownerId, bytes32 _tokenId) external view returns (uint256 vTokenBalance_) {
    //     vTokenBalance_ = LibTokenizedVaultStaking._currrentVtokenBalance(_ownerId, _tokenId);
    // }
}
