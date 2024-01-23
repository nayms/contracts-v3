// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults, c, LC, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { StakeConfig } from "src/shared/FreeStructs.sol";
import { ERC20Wrapper } from "../src/utils/ERC20Wrapper.sol";

// import { InitDiamondFixture } from "./fixtures/InitDiamondFixture.sol";
// import { IDiamondLoupe } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondLoupe.sol";
// import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
// import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
// import { DiamondAlreadyInitialized } from "src/init/InitDiamond.sol";
// import { LibGovernance } from "src/libs/LibGovernance.sol";

// import { IERC165 } from "lib/diamond-2-hardhat/contracts/interfaces/IERC165.sol";
// import { IERC173 } from "lib/diamond-2-hardhat/contracts/interfaces/IERC173.sol";
// import { IERC20 } from "../src/interfaces/IERC20.sol";

function makeId2(bytes12 _objecType, bytes20 randomBytes) pure returns (bytes32) {
    return bytes32((_objecType)) | (bytes32(randomBytes) >> 96);
}

using LibHelpers for address;

contract T01DeploymentTest is D03ProtocolDefaults {
    using stdStorage for StdStorage;

    bytes32 immutable VTOKENID = makeId2(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256(bytes("test"))));
    bytes32 NAYMSID;

    NaymsAccount alice;

    function setUp() public {
        NAYMSID = address(nayms)._getIdForAddress();

        alice = makeNaymsAcc("Alice");
        vm.startPrank(deployer);
        nayms.transfer(alice.addr, 100_000_000e18);

        startPrank(sa);
        nayms.addSupportedExternalToken(naymsAddress, 1e13);

        vm.startPrank(sm.addr);
        hCreateEntity(alice, entity, "Alice data");
        vm.startPrank(alice.addr);
        nayms.approve(naymsAddress, 100_000_000e18);
        // note: the tokens get transferred to the user's parent entity
        nayms.externalDeposit(naymsAddress, 100_000_000e18);
    }

    function vtokenId(bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32) {
        bytes memory vTokenBytes = abi.encodePacked(bytes4(LC.OBJECT_TYPE_STAKED), _interval, _tokenId << 96);
        return bytes32(vTokenBytes);
    }

    function test_vtokenId() public {
        bytes20 entityId = bytes20(keccak256(bytes("test")));
        c.log(vm.toString(entityId));
        bytes32 tokenId = makeId2(LC.OBJECT_TYPE_ENTITY, entityId);
        uint64 interval = 1;

        bytes32 vtokenId = vtokenId(tokenId, interval);
        bytes4 objectType = bytes4(vtokenId);

        c.logBytes32(vtokenId);
        c.logBytes32(vtokenId << 32);
        c.logBytes32(vtokenId << 96);
        c.log(vm.toString(entityId));
        uint64 intervalExtracted = uint64(bytes8((vtokenId << 32)));
        c.log(vm.toString(intervalExtracted));
        assertEq(objectType, LC.OBJECT_TYPE_STAKED);
        assertEq(intervalExtracted, interval);

        bytes20 entityIdExtracted = bytes20(vtokenId << 96);

        assertEq(entityIdExtracted, entityId);
    }

    function test_updateStaking() public {
        nayms.updateStakingParams(VTOKENID);

        StakeConfig memory stakeConfig = nayms.stakeConfigs(VTOKENID);

        assertEq(stakeConfig.initDate, block.timestamp);
    }

    function test_currentInterval() public {
        vm.warp(1);
        nayms.updateStakingParams(VTOKENID);
        StakeConfig memory stakeConfig = nayms.stakeConfigs(VTOKENID);

        assertEq(nayms.currentInterval(VTOKENID), 0);
        vm.warp(stakeConfig.initDate + stakeConfig.interval - 1);
        assertEq(nayms.currentInterval(VTOKENID), 0);
        vm.warp(stakeConfig.initDate + stakeConfig.interval);
        assertEq(nayms.currentInterval(VTOKENID), 1);
        vm.warp(stakeConfig.initDate + stakeConfig.interval * 2);
        assertEq(nayms.currentInterval(VTOKENID), 2);
    }

    function test_stake() public {
        // Stake
        // Initialize staking for token 00
        vm.warp(1);
        nayms.updateStakingParams(NAYMSID);

        nayms.internalBalanceOf(alice.id, NAYMSID);
        nayms.stake(NAYMSID, 1 ether);
        // nayms.stake(deployer._getIdForAddress(), NAYMSID, 1 ether);
    }

    function test_StakeBeforeInitStaking() public {
        vm.warp(1);
        nayms.updateStakingParams(NAYMSID);

        startPrank(alice);
        nayms.stake(NAYMSID, 100);

        nayms.internalBalanceOf(alice.id, NAYMSID);

        nayms.currentOwedBoost(NAYMSID, alice.id);
    }
    // function test_stake() public {
    //     // Stake
    //     // Initialize staking for token 00
    //     vm.warp(1);
    //     nayms.updateStakingParams(VTOKENID);

    //     NaymsAccount memory alice = makeNaymsAcc("Alice");

    //     (, , , , address wrapperAddress) = nayms.getObjectMeta(VTOKENID);
    //     ERC20Wrapper wrapper = ERC20Wrapper(wrapperAddress);

    //     startPrank(sa);
    //     nayms.addSupportedExternalToken(wrapperAddress, 1e13);

    //     vm.startPrank(sm.addr);
    //     hCreateEntity(alice, entity, "Alice data");
    //     vm.startPrank(alice.addr);
    //     nayms.externalDeposit(naymsAddress, 100_000_000e18);
    //     // nayms.stake(alice.id, VTOKENID, 1 ether);
    //     nayms.stake(deployer._getIdForAddress(), VTOKENID, 1 ether);
    // }
}

// nlf is a capital provider
// it will invest with assets it holds
