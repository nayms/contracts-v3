// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage, StdStyle } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults, c, LC, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { StakeConfig, StakingState } from "src/shared/FreeStructs.sol";
import { ERC20Wrapper } from "../src/utils/ERC20Wrapper.sol";

import { LibTokenizedVaultStaking } from "src/libs/LibTokenizedVaultStaking.sol";

function makeId2(bytes12 _objecType, bytes20 randomBytes) pure returns (bytes32) {
    return bytes32((_objecType)) | (bytes32(randomBytes));
}

contract StakingTest is D03ProtocolDefaults {
    using LibHelpers for address;
    using stdStorage for StdStorage;
    using StdStyle for *;

    bytes32 immutable VTOKENID = makeId2(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256(bytes("test"))));

    bytes32 VTOKENID0;
    bytes32 VTOKENID1;
    bytes32 NAYMSID;

    NaymsAccount bob;
    NaymsAccount sue;
    NaymsAccount lou;

    function setUp() public {
        NAYMSID = address(nayms)._getIdForAddress();
        VTOKENID0 = vtokenId(NAYMSID, 0);
        VTOKENID1 = vtokenId(NAYMSID, 1);

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

    function vtokenId(bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32) {
        return LibTokenizedVaultStaking._vTokenId(_tokenId, _interval);
    }

    function test_vtokenId() public {
        c.log(" ~ vTokenID Test ~".green());

        uint64 interval = 1;
        bytes20 entityId = bytes20(keccak256(bytes("test")));
        bytes32 vId = vtokenId(entityId, interval);

        c.log("interval =", interval);
        c.log("vId =", vm.toString(vId));
        c.log("entityId =", vm.toString(entityId));

        uint64 intervalExtracted = uint64(bytes8((vId << 32)));
        c.log("intervalExtracted =", vm.toString(intervalExtracted));

        assertEq(bytes4(vId), LC.OBJECT_TYPE_STAKED, "Invalid object type");
        assertEq(intervalExtracted, interval, "Invalid interval");

        bytes20 entityIdExtracted = bytes20(vId << 96);
        c.log("entityIdExtracted =", vm.toString(entityIdExtracted));
        assertEq(entityIdExtracted, entityId, "Invalid entity ID");
    }

    function test_updateStaking() public {
        nayms.updateStakingParamsWithDefaults(VTOKENID);
        StakeConfig memory stakeConfig = nayms.stakeConfigs(VTOKENID);
        assertEq(stakeConfig.initDate, block.timestamp);
        assertEq(stakeConfig.a + stakeConfig.r, stakeConfig.divider);
    }

    function test_currentInterval() public {
        vm.warp(1);
        nayms.updateStakingParamsWithDefaults(VTOKENID);
        nayms.initStaking(VTOKENID);

        StakeConfig memory stakeConfig = nayms.stakeConfigs(VTOKENID);
        assertEq(nayms.currentInterval(VTOKENID), 0, "current interval not 0");
        vm.warp(stakeConfig.initDate + stakeConfig.interval - 1);
        assertEq(nayms.currentInterval(VTOKENID), 0, "current interval not 0 again");
        vm.warp(stakeConfig.initDate + stakeConfig.interval);
        assertEq(nayms.currentInterval(VTOKENID), 1, "current interval not 1");
        vm.warp(stakeConfig.initDate + stakeConfig.interval * 2);
        assertEq(nayms.currentInterval(VTOKENID), 2, "current interval not 2");
    }

    function test_stake() public {
        // vm.warp(1);
        nayms.updateStakingParamsWithDefaults(NAYMSID);
        nayms.initStaking(NAYMSID);

        startPrank(bob);
        nayms.stake(NAYMSID, 1 ether);
    }

    function printBoosts(bytes32 tokenId, bytes32 ownerId, string memory name) internal view {
        uint64 interval = nayms.currentInterval(tokenId);
        StakingState memory ownerState = nayms.getStakingState(ownerId, tokenId, interval);

        c.log("   ~~~~ %s Staking State ~~~~".blue().bold(), name);
        c.log("     Staking Balance[%s]:".green(), interval, ownerState.balanceAtInterval);
        c.log("       Staking Boost[%s]:".green(), interval, ownerState.boostAtInterval);
    }

    function calculateBoost(uint256 amountStaked) internal view returns (uint256 boost) {
        boost = (nayms.stakeConfigs(NAYMSID).a * amountStaked) / nayms.stakeConfigs(NAYMSID).divider;
    }

    function test_StakeBeforeInitStaking() public {
        uint256 stakingStart = 100 days;

        c.log("TIME: -20".blue());
        vm.warp(stakingStart - 20 days);

        nayms.updateStakingParamsWithDefaults(NAYMSID);

        uint256 bobStakeAmount = 100e6;
        uint256 sueStakeAmount = 200e6;
        uint256 louStakeAmount = 400e6;

        StakingState memory bobState0 = nayms.getStakingState(bob.entityId, NAYMSID, 0);
        assertEq(bobState0.balanceAtInterval, 0, "Bob's staking balance[0] should be 0 before staking");

        StakingState memory naymsState0 = nayms.getStakingState(NAYMSID, NAYMSID, 0);
        assertEq(nayms.internalBalanceOf(NAYMSID, NAYMSID), 0, "Nayms' internal balance[0] should be 0 before staking");
        assertEq(naymsState0.balanceAtInterval, 0, "Nayms' staking balance[0] should be 0 before staking");

        startPrank(bob);
        nayms.stake(NAYMSID, bobStakeAmount);
        printBoosts(NAYMSID, bob.entityId, "Bob");

        bobState0 = nayms.getStakingState(bob.entityId, NAYMSID, 0); // re-read state
        assertEq(bobState0.balanceAtInterval, bobStakeAmount, "Bob's staking balance[0] should increase");
        assertEq(bobState0.boostAtInterval, 15e6, "Bob's boost[0] should increase");

        naymsState0 = nayms.getStakingState(NAYMSID, NAYMSID, 0); // re-read state
        assertEq(naymsState0.balanceAtInterval, bobStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(naymsState0.boostAtInterval, 15e6, "Nayms' boost[0] should increase");

        c.log("TIME: -10".blue());
        vm.warp(stakingStart - 10 days);
        startPrank(sue);
        nayms.stake(NAYMSID, sueStakeAmount);
        printBoosts(NAYMSID, sue.entityId, "Sue");
        printBoosts(NAYMSID, NAYMSID, "Nayms");

        StakingState memory sueState0 = nayms.getStakingState(sue.entityId, NAYMSID, 0);
        assertEq(sueState0.balanceAtInterval, sueStakeAmount, "Sue's staking balance[0] should increase");
        assertEq(sueState0.boostAtInterval, 30e6, "Sue's boost[0] should increase");

        naymsState0 = nayms.getStakingState(NAYMSID, NAYMSID, 0); // re-read state
        assertEq(naymsState0.balanceAtInterval, sueStakeAmount + bobStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(naymsState0.boostAtInterval, 45e6, "Nayms' boost[0] should increase");

        c.log("TIME: 0 (Staking Time)".blue());
        vm.warp(stakingStart);
        nayms.initStaking(NAYMSID);
        c.log("~~~~~~~~~~~~~~ Staking Started ~~~~~~~~~~~~~~".yellow());

        c.log("TIME: 20".blue());
        vm.warp(stakingStart + 20 days);
        startPrank(lou);
        nayms.stake(NAYMSID, louStakeAmount);
        printBoosts(NAYMSID, lou.entityId, "Lou");
        printBoosts(NAYMSID, NAYMSID, "Nayms");

        StakingState memory louState0 = nayms.getStakingState(lou.entityId, NAYMSID, 0);
        assertEq(louState0.balanceAtInterval, louStakeAmount, "Lou's staking balance[0] should increase");
        assertEq(louState0.boostAtInterval, 20e6, "Lou's boost[0] should increase");

        naymsState0 = nayms.getStakingState(NAYMSID, NAYMSID, 0); // re-read state
        assertEq(naymsState0.balanceAtInterval, louStakeAmount + sueStakeAmount + bobStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(naymsState0.boostAtInterval, 65e6, "Nayms' boost[0] should increase");

        c.log("TIME: 30".blue());
        vm.warp(stakingStart + 30 days);
        startPrank(sm);
        assertEq(nayms.lastIntervalPaid(NAYMSID), 0, "Last interval paid should be 0");
        nayms.payReward(NAYMSID, usdcId, 100e6);
        c.log(" ~~~~~~~~~~~~~ 1st Distribution Paid ~~~~~~~~~~~~~".yellow());
        printBoosts(NAYMSID, NAYMSID, "Nayms");

        StakingState memory naymsState1 = nayms.getStakingState(NAYMSID, NAYMSID, 1); // re-read state
        assertEq(naymsState1.balanceAtInterval, 765e6, "Nayms' staking balance[1] should increase");
        assertEq(naymsState1.boostAtInterval, 9525e4, "Nayms' boost[1] should increase");

        StakingState memory bobState1 = nayms.getStakingState(bob.entityId, NAYMSID, 1); // re-read state
        assertEq(bobState1.balanceAtInterval, 115e6, "Bob's staking balance[1] should increase");
        assertEq(bobState1.boostAtInterval, 1275e4, "Bob's boost[1] should increase");

        StakingState memory sueState1 = nayms.getStakingState(sue.entityId, NAYMSID, 1); // re-read state
        assertEq(sueState1.balanceAtInterval, 230e6, "Sue's staking balance[1] should increase");
        assertEq(sueState1.boostAtInterval, 255e5, "Sue's boost[1] should increase");

        StakingState memory louState1 = nayms.getStakingState(lou.entityId, NAYMSID, 1); // re-read state
        assertEq(louState1.balanceAtInterval, 420e6, "Lou's staking balance[1] should increase");
        assertEq(louState1.boostAtInterval, 57e6, "Lou's boost[1] should increase");

        c.log("TIME: 60".blue());
        vm.warp(stakingStart + 60 days);
        assertEq(nayms.lastIntervalPaid(NAYMSID), 1, "Last interval paid should be 1");
        nayms.payReward(NAYMSID, usdcId, 100e6);
        c.log(" ~~~~~~~~~~~~~ 2nd Distribution Paid ~~~~~~~~~~~~~".yellow());
        printBoosts(NAYMSID, NAYMSID, "Nayms");

        c.log("TIME: 62".blue());
        vm.warp(stakingStart + 62 days);

        StakingState memory bobState2 = nayms.getStakingState(bob.entityId, NAYMSID, 2); // re-read state
        assertEq(bobState2.balanceAtInterval, 12775e4, "Bob's staking balance[2] should increase");
        assertEq(bobState2.boostAtInterval, 108375e2, "Bob's boost[2] should increase");

        printBoosts(NAYMSID, NAYMSID, "Nayms");
        printBoosts(NAYMSID, bob.entityId, "Bob");
        printBoosts(NAYMSID, sue.entityId, "Sue");
        printBoosts(NAYMSID, lou.entityId, "Lou");
    }
}
