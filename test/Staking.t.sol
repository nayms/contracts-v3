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

    NaymsAccount bob;
    NaymsAccount sue;
    NaymsAccount lou;

    function setUp() public {
        NAYMSID = address(nayms)._getIdForAddress();

        bob = makeNaymsAcc("Bob");
        sue = makeNaymsAcc("Sue");
        lou = makeNaymsAcc("Lou");
        vm.startPrank(deployer);
        nayms.transfer(bob.addr, 10_000_000e18);
        nayms.transfer(sue.addr, 10_000_000e18);
        nayms.transfer(lou.addr, 10_000_000e18);

        startPrank(sa);
        nayms.addSupportedExternalToken(naymsAddress, 1e13);

        vm.startPrank(sm.addr);
        hCreateEntity(bob.entityId, bob, entity, "Bob data");
        hCreateEntity(sue.entityId, sue, entity, "Sue data");
        hCreateEntity(lou.entityId, lou, entity, "Lou data");
        hCreateEntity(sm.entityId, sm, entity, "System Manager data");
        vm.startPrank(bob.addr);
        nayms.approve(naymsAddress, 10_000_000e18);
        // note: the tokens get transferred to the user's parent entity
        nayms.externalDeposit(naymsAddress, 10_000_000e18);
        vm.startPrank(sue.addr);
        nayms.approve(naymsAddress, 10_000_000e18);
        nayms.externalDeposit(naymsAddress, 10_000_000e18);
        vm.startPrank(lou.addr);
        nayms.approve(naymsAddress, 10_000_000e18);
        nayms.externalDeposit(naymsAddress, 10_000_000e18);

        // for now, assume sm pays the distributions
        startPrank(sm);
        fundEntityUsdc(sm, 100_000_000e6);
    }

    function test_setUp() public {
        // c.logBytes32(bob.entityId);
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

        nayms.internalBalanceOf(bob.id, NAYMSID);
        nayms.stake(NAYMSID, 1 ether);
        // nayms.stake(deployer._getIdForAddress(), NAYMSID, 1 ether);
    }

    function test_StakeBeforeInitStaking() public {
        vm.warp(1);
        nayms.updateStakingParams(NAYMSID);

        startPrank(bob);
        nayms.stake(NAYMSID, 100);

        nayms.internalBalanceOf(bob.entityId, NAYMSID);

        nayms.getEntity(bob.id);
        nayms.currentOwedBoost(NAYMSID, bob.entityId);
        nayms.stakeBoost(NAYMSID, bob.entityId, 0);
        nayms.stakeBoost(NAYMSID, bob.entityId, 1);
        nayms.stakeBoost(NAYMSID, bob.entityId, 2);
        nayms.stakeBoost(NAYMSID, NAYMSID, 0);
        nayms.stakeBoost(NAYMSID, NAYMSID, 1);
        nayms.stakeBoost(NAYMSID, NAYMSID, 2);

        vm.warp(10 days);
        startPrank(sue);
        nayms.stake(NAYMSID, 200);

        vm.warp(20 days);
        // todo set permissions for startStaking
        nayms.startStaking(NAYMSID);

        vm.warp(40 days);
        startPrank(lou);
        nayms.stake(NAYMSID, 400);

        vm.warp(50 days);
        startPrank(sm);
        // nayms.payDistribution("1", , sm.entityId, USDC_IDENTIFIER, 100e6);
    }
    // function test_stake() public {
    //     // Stake
    //     // Initialize staking for token 00
    //     vm.warp(1);
    //     nayms.updateStakingParams(VTOKENID);

    //     NaymsAccount memory bob = makeNaymsAcc("Bob");

    //     (, , , , address wrapperAddress) = nayms.getObjectMeta(VTOKENID);
    //     ERC20Wrapper wrapper = ERC20Wrapper(wrapperAddress);

    //     startPrank(sa);
    //     nayms.addSupportedExternalToken(wrapperAddress, 1e13);

    //     vm.startPrank(sm.addr);
    //     hCreateEntity(bob, entity, "Bob data");
    //     vm.startPrank(bob.addr);
    //     nayms.externalDeposit(naymsAddress, 100_000_000e18);
    //     // nayms.stake(bob.id, VTOKENID, 1 ether);
    //     nayms.stake(deployer._getIdForAddress(), VTOKENID, 1 ether);
    // }
}

// nlf is a capital provider
// it will invest with assets it holds
