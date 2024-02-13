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

    uint256 immutable usdcTotal = 1_000_000e6;

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

        fundEntityUsdc(sm, usdcTotal);
        nayms.internalTransferFromEntity(NAYMSID, usdcId, usdcTotal);
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

        c.log("");
        c.log("     ~~~~~~~  %s  ~~~~~~~".blue().bold(), name);
        c.log("     Balance[%s]:".green(), interval, ownerState.balance);
        c.log("       Boost[%s]:".green(), interval, ownerState.boost);
        c.log("");
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
        uint256 totalStakeAmount = bobStakeAmount + sueStakeAmount + louStakeAmount;

        StakingState memory bobState0 = nayms.getStakingState(bob.entityId, NAYMSID, 0);
        assertEq(bobState0.balance, 0, "Bob's staking balance[0] should be 0 before staking");

        StakingState memory naymsState0 = nayms.getStakingState(NAYMSID, NAYMSID, 0);
        assertEq(nayms.internalBalanceOf(NAYMSID, NAYMSID), 0, "Nayms' internal balance[0] should be 0 before staking");
        assertEq(naymsState0.balance, 0, "Nayms' staking balance[0] should be 0 before staking");

        startPrank(bob);
        nayms.stake(NAYMSID, bobStakeAmount);
        printBoosts(NAYMSID, bob.entityId, "Bob");

        bobState0 = nayms.getStakingState(bob.entityId, NAYMSID, 0); // re-read state
        assertEq(bobState0.balance, bobStakeAmount, "Bob's staking balance[0] should increase");
        assertEq(bobState0.boost, 15e6, "Bob's boost[0] should increase");

        naymsState0 = nayms.getStakingState(NAYMSID, NAYMSID, 0); // re-read state
        assertEq(naymsState0.balance, bobStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(naymsState0.boost, 15e6, "Nayms' boost[0] should increase");

        c.log("TIME: -10".blue());
        vm.warp(stakingStart - 10 days);
        startPrank(sue);
        nayms.stake(NAYMSID, sueStakeAmount);
        printBoosts(NAYMSID, sue.entityId, "Sue");
        printBoosts(NAYMSID, NAYMSID, "Nayms");

        StakingState memory sueState0 = nayms.getStakingState(sue.entityId, NAYMSID, 0);
        assertEq(sueState0.balance, sueStakeAmount, "Sue's staking balance[0] should increase");
        assertEq(sueState0.boost, 30e6, "Sue's boost[0] should increase");

        naymsState0 = nayms.getStakingState(NAYMSID, NAYMSID, 0); // re-read state
        assertEq(naymsState0.balance, sueStakeAmount + bobStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(naymsState0.boost, 45e6, "Nayms' boost[0] should increase");

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
        assertEq(louState0.balance, louStakeAmount, "Lou's staking balance[0] should increase");
        assertEq(louState0.boost, 20e6, "Lou's boost[0] should increase");

        naymsState0 = nayms.getStakingState(NAYMSID, NAYMSID, 0); // re-read state
        assertEq(naymsState0.balance, totalStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(naymsState0.boost, 65e6, "Nayms' boost[0] should increase");

        c.log("TIME: 30".blue());
        vm.warp(stakingStart + 30 days);
        startPrank(sm);
        assertEq(nayms.lastIntervalPaid(NAYMSID), 0, "Last interval paid should be 0");
        assertEq(nayms.internalBalanceOf(NAYMSID, usdcId), usdcTotal, "USCD balance should not change");

        uint256 rewardAmount = 100e6;

        assertEq(nayms.lastIntervalPaid(NAYMSID), 0, "Last interval paid should be 1");
        nayms.payReward(NAYMSID, usdcId, rewardAmount);
        assertEq(nayms.lastIntervalPaid(NAYMSID), 1, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(NAYMSID, usdcId), usdcTotal - rewardAmount, "USCD balance should change");
        assertEq(nayms.internalBalanceOf(nayms.vTokenId(NAYMSID, 0), usdcId), 100e6, "NLF's USDC balance should increase");
        c.log(" ~~~~~~~~~~~~~ 1st Distribution Paid ~~~~~~~~~~~~~".yellow());

        printBoosts(NAYMSID, NAYMSID, "Nayms");

        {
            StakingState memory naymsState1 = nayms.getStakingState(NAYMSID, NAYMSID, 1); // re-read state
            assertEq(naymsState1.balance, 765e6, "Nayms' staking balance[1] should increase");
            assertEq(naymsState1.boost, 9525e4, "Nayms' boost[1] should increase");

            StakingState memory bobState1 = nayms.getStakingState(bob.entityId, NAYMSID, 1); // re-read state
            assertEq(bobState1.balance, 115e6, "Bob's staking balance[1] should increase");
            assertEq(bobState1.boost, 1275e4, "Bob's boost[1] should increase");

            StakingState memory sueState1 = nayms.getStakingState(sue.entityId, NAYMSID, 1); // re-read state
            assertEq(sueState1.balance, 230e6, "Sue's staking balance[1] should increase");
            assertEq(sueState1.boost, 255e5, "Sue's boost[1] should increase");

            StakingState memory louState1 = nayms.getStakingState(lou.entityId, NAYMSID, 1); // re-read state
            assertEq(louState1.balance, 420e6, "Lou's staking balance[1] should increase");
            assertEq(louState1.boost, 57e6, "Lou's boost[1] should increase");
        }

        printBoosts(NAYMSID, lou.entityId, "Lou");

        c.log("TIME: 60".blue());
        vm.warp(stakingStart + 60 days);

        assertEq(nayms.lastIntervalPaid(NAYMSID), 1, "Last interval paid should be 1");
        nayms.payReward(NAYMSID, usdcId, rewardAmount);
        assertEq(nayms.lastIntervalPaid(NAYMSID), 2, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(NAYMSID, usdcId), usdcTotal - rewardAmount * 2, "USCD balance should change");
        assertEq(nayms.internalBalanceOf(nayms.vTokenId(NAYMSID, 0), usdcId), rewardAmount * 2, "NLF's USDC balance should increase");
        c.log(" ~~~~~~~~~~~~~ 2nd Distribution Paid ~~~~~~~~~~~~~".yellow());

        StakingState memory naymsState2 = nayms.getStakingState(NAYMSID, NAYMSID, 2); // re-read state
        assertEq(naymsState2.balance, 86025e4, "Nayms' staking balance[2] should increase");
        assertEq(naymsState2.boost, 809625e2, "Nayms' boost[2] should increase");

        printBoosts(NAYMSID, NAYMSID, "Nayms");

        c.log("TIME: 62".blue());
        vm.warp(stakingStart + 62 days);

        startPrank(bob);
        nayms.collectRewards(NAYMSID);
        c.log(" ~~~~~~~~~~~~~ Bob Claimed Rewards ~~~~~~~~~~~~~".yellow());

        c.log(" ~~~~~~~~~~~~~ USDC BALANCES AFTER ~~~~~~~~~~~~~".yellow());
        c.log("NAYM:", nayms.internalBalanceOf(NAYMSID, usdcId));
        c.log("vToken0:", nayms.internalBalanceOf(nayms.vTokenId(NAYMSID, 0), usdcId));
        c.log("Bob:", nayms.internalBalanceOf(bob.entityId, usdcId));

        {
            StakingState memory bobState2 = nayms.getStakingState(bob.entityId, NAYMSID, 2); // re-read state
            assertEq(bobState2.balance, 12775e4, "Bob's staking balance[2] should increase");
            assertEq(bobState2.boost, 108375e2, "Bob's boost[2] should increase");

            StakingState memory sueState2 = nayms.getStakingState(sue.entityId, NAYMSID, 2); // re-read state
            assertEq(sueState2.balance, 2555e5, "Sue's staking balance[2] should increase");
            assertEq(sueState2.boost, 21675e3, "Sue's boost[2] should increase");

            StakingState memory louState2 = nayms.getStakingState(lou.entityId, NAYMSID, 2); // re-read state
            assertEq(louState2.balance, 477e6, "Lou's staking balance[2] should increase");
            assertEq(louState2.boost, 4845e4, "Lou's boost[2] should increase");
        }

        printBoosts(NAYMSID, NAYMSID, "Nayms");
        printBoosts(NAYMSID, bob.entityId, "Bob");
        printBoosts(NAYMSID, sue.entityId, "Sue");
        printBoosts(NAYMSID, lou.entityId, "Lou");

        c.log("TIME: 90".blue());
        vm.warp(stakingStart + 90 days);
        assertEq(nayms.lastIntervalPaid(NAYMSID), 2, "Last interval paid should be 2");
        nayms.payReward(NAYMSID, usdcId, rewardAmount);
        c.log(" ~~~~~~~~~~~~~ 3rd Distribution Paid ~~~~~~~~~~~~~".yellow());

        StakingState memory naymsState3 = nayms.getStakingState(NAYMSID, NAYMSID, 3); // re-read state
        assertEq(naymsState3.balance, 9412125e2, "Nayms' staking balance[3] should increase");
        assertEq(naymsState3.boost, 68818125, "Nayms' boost[3] should increase");
        printBoosts(NAYMSID, NAYMSID, "Nayms");

        c.log("TIME: 91".blue());
        vm.warp(stakingStart + 91 days);

        startPrank(sue);
        nayms.collectRewards(NAYMSID);
        c.log(" ~~~~~~~~~~~~~ Sue Claimed Rewards ~~~~~~~~~~~~~".yellow());

        {
            StakingState memory bobState3 = nayms.getStakingState(bob.entityId, NAYMSID, 3); // re-read state
            assertEq(bobState3.balance, 138587500, "Bob's staking balance[3] should increase");
            assertEq(bobState3.boost, 9211875, "Bob's boost[3] should increase");

            StakingState memory sueState3 = nayms.getStakingState(sue.entityId, NAYMSID, 3); // re-read state
            assertEq(sueState3.balance, 277175e3, "Sue's staking balance[3] should increase");
            assertEq(sueState3.boost, 18423750, "Sue's boost[3] should increase");

            StakingState memory louState3 = nayms.getStakingState(lou.entityId, NAYMSID, 3); // re-read state
            assertEq(louState3.balance, 52545e4, "Lou's staking balance[3] should increase");
            assertEq(louState3.boost, 411825e2, "Lou's boost[3] should increase");
        }

        c.log("TIME: 92".blue());
        vm.warp(stakingStart + 92 days);

        startPrank(lou);
        nayms.collectRewards(NAYMSID);
        c.log(" ~~~~~~~~~~~~~ Lou Claimed Rewards ~~~~~~~~~~~~~".yellow());

        {
            StakingState memory bobState3 = nayms.getStakingState(bob.entityId, NAYMSID, 3); // re-read state
            assertEq(bobState3.balance, 138587500, "Bob's staking balance[3] should increase");
            assertEq(bobState3.boost, 9211875, "Bob's boost[3] should increase");

            StakingState memory sueState3 = nayms.getStakingState(sue.entityId, NAYMSID, 3); // re-read state
            assertEq(sueState3.balance, 277175e3, "Sue's staking balance[3] should increase");
            assertEq(sueState3.boost, 18423750, "Sue's boost[3] should increase");

            StakingState memory louState3 = nayms.getStakingState(lou.entityId, NAYMSID, 3); // re-read state
            assertEq(louState3.balance, 52545e4, "Lou's staking balance[3] should increase");
            assertEq(louState3.boost, 411825e2, "Lou's boost[3] should increase");
        }

        printBoosts(NAYMSID, NAYMSID, "Nayms");
        printBoosts(NAYMSID, bob.entityId, "Bob");
        printBoosts(NAYMSID, sue.entityId, "Sue");
        printBoosts(NAYMSID, lou.entityId, "Lou");
    }
}
