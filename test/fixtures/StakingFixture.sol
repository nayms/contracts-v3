// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibTokenizedVaultStaking } from "src/libs/LibTokenizedVaultStaking.sol";
import { AppStorage, LibAppStorage } from "src/shared/AppStorage.sol";

contract StakingFixture {
    function boostAtInterval(bytes32 _stakerId, bytes32 _entityId, uint64 _interval) public view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;
        bytes32 vTokenId = LibTokenizedVaultStaking._vTokenId(tokenId, _interval);

        return s.stakeBoost[vTokenId][_stakerId];
    }

    function balanceAtInterval(bytes32 _stakerId, bytes32 _entityId, uint64 _interval) public view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 tokenId = s.stakingConfigs[_entityId].tokenId;
        bytes32 vTokenId = LibTokenizedVaultStaking._vTokenId(tokenId, _interval);

        return s.stakeBalance[vTokenId][_stakerId];
    }
}
