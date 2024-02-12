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

        c.log(" ------------------ getting state for Nayms totals ------------------ ");
        StakingState memory naymsState = nayms.getStakingState(NAYMSID, tokenId, interval);

        c.log(" ------------------ getting state for %s ------------------ ", name);
        StakingState memory ownerState = nayms.getStakingState(ownerId, tokenId, interval);

        c.log("             ~~~ %s's Boosts ~~~".blue().bold(), name);
        c.log("    Current Interval:".green(), interval);
        c.log("   NAYM Total Supply:".green().blue(), nayms.totalSupply());
        c.log("   NAYM Total Staked:".green(), naymsState.balanceAtInterval);
        c.log("    NAYM Total Boost:".green(), naymsState.boostAtInterval);
        c.log("     Staking Balance:".green(), ownerState.balanceAtInterval);
        c.log("       Staking Boost:".green(), ownerState.boostAtInterval);

        if (nayms.stakeConfigs(tokenId).initDate != 0) {
            c.log(string.concat("  Days Since Staking: ".green(), vm.toString((block.timestamp - nayms.stakeConfigs(tokenId).initDate) / 1 days), " days"));
        }
    }

    function calculateBoost(uint256 amountStaked) internal view returns (uint256 boost) {
        boost = (nayms.stakeConfigs(NAYMSID).a * amountStaked) / nayms.stakeConfigs(NAYMSID).divider;
    }

    function test_StakeBeforeInitStaking() public {
        uint256 stakingStart = 100 days;

        // TIME: -20.00
        vm.warp(stakingStart - 20 days);

        nayms.updateStakingParamsWithDefaults(NAYMSID);

        uint256 bobStakeAmount = 100e6;
        uint256 sueStakeAmount = 200e6;
        uint256 louStakeAmount = 400e6;

        assertEq(nayms.getStakingState(bob.entityId, NAYMSID, 0).balanceAtInterval, 0, "Bob's staking balance should be 0 before staking");
        assertEq(nayms.internalBalanceOf(NAYMSID, NAYMSID), 0, "Nayms' internal balance should be 0 before staking");
        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 0).balanceAtInterval, 0, "Nayms' staking balance should be 0 before staking");

        startPrank(bob);
        nayms.stake(NAYMSID, bobStakeAmount);
        // printBoosts(NAYMSID, bob.entityId, "Bob");

        assertEq(nayms.getStakingState(bob.entityId, NAYMSID, 0).balanceAtInterval, bobStakeAmount, "Bob's staking balance should increase");
        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 0).balanceAtInterval, bobStakeAmount, "Nayms' staking balance should increase");
        assertEq(nayms.getStakingState(bob.entityId, NAYMSID, 0).boostAtInterval, 15e6, "Bob's boost should increase");
        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 0).boostAtInterval, 15e6, "Nayms' boost should increase");

        // TIME: -10.00
        vm.warp(stakingStart - 10 days);
        startPrank(sue);
        nayms.stake(NAYMSID, sueStakeAmount);
        // printBoosts(NAYMSID, sue.entityId, "Sue");

        assertEq(nayms.getStakingState(sue.entityId, NAYMSID, 0).balanceAtInterval, sueStakeAmount, "Sue's staking balance should increase");
        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 0).balanceAtInterval, sueStakeAmount + bobStakeAmount, "Nayms' staking balance should increase");
        assertEq(nayms.getStakingState(sue.entityId, NAYMSID, 0).boostAtInterval, 30e6, "Sue's boost should increase");
        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 0).boostAtInterval, 45e6, "Nayms' boost should increase");

        // TIME: 0 (Staking Time)
        vm.warp(stakingStart);
        nayms.initStaking(NAYMSID);
        c.log("~~~~~~~~~~~~~~ Staking Started ~~~~~~~~~~~~~~".yellow());

        // TIME: 20.00
        vm.warp(stakingStart + 20 days);
        startPrank(lou);
        nayms.stake(NAYMSID, louStakeAmount);
        // printBoosts(NAYMSID, lou.entityId, "Lou");

        assertEq(nayms.getStakingState(lou.entityId, NAYMSID, 0).balanceAtInterval, louStakeAmount, "Lou's staking balance should increase");
        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 0).balanceAtInterval, louStakeAmount + sueStakeAmount + bobStakeAmount, "Nayms' staking balance should increase");
        assertEq(nayms.getStakingState(lou.entityId, NAYMSID, 0).boostAtInterval, 20e6, "Lou's boost should increase");
        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 0).boostAtInterval, 65e6, "Nayms' boost should increase");

        // TIME: 30.00
        vm.warp(stakingStart + 30 days);
        startPrank(sm);
        assertEq(nayms.lastIntervalPaid(NAYMSID), 0);
        nayms.payReward(NAYMSID, usdcId, 100e6);
        c.log(" ~~~~~~~~~~~~~ 1st Distribution Paid ~~~~~~~~~~~~~".yellow());

        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 1).balanceAtInterval, 765e6, "Nayms' staking balance should increase");
        assertEq(nayms.getStakingState(NAYMSID, NAYMSID, 1).boostAtInterval, 9525e4, "Nayms' boost should increase");

        assertEq(nayms.getStakingState(bob.entityId, NAYMSID, 1).balanceAtInterval, 115e6, "Bob's staking balance should increase");
        assertEq(nayms.getStakingState(bob.entityId, NAYMSID, 1).boostAtInterval, 1275e4, "Bob's boost should increase");

        assertEq(nayms.getStakingState(sue.entityId, NAYMSID, 1).balanceAtInterval, 230e6, "Sue's staking balance should increase");
        assertEq(nayms.getStakingState(sue.entityId, NAYMSID, 1).boostAtInterval, 255e5, "Sue's boost should increase");

        assertEq(nayms.getStakingState(lou.entityId, NAYMSID, 1).balanceAtInterval, 420e6, "Lou's staking balance should increase");
        assertEq(nayms.getStakingState(lou.entityId, NAYMSID, 1).boostAtInterval, 57e6, "Lou's boost should increase");

        vm.warp(stakingStart + 60 days);
        assertEq(nayms.lastIntervalPaid(NAYMSID), 1);
        nayms.payReward(NAYMSID, usdcId, 100e6);
        c.log(" ~~~~~~~~~~~~~ 2nd Distribution Paid ~~~~~~~~~~~~~".yellow());

        vm.warp(stakingStart + 62 days);
        printBoosts(NAYMSID, bob.entityId, "Bob");
        printBoosts(NAYMSID, sue.entityId, "Sue");
        printBoosts(NAYMSID, lou.entityId, "Lou");
    }
}
