// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage, StdStyle } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults, c, LC, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { StakingConfig, StakingState } from "src/shared/FreeStructs.sol";

import { DummyToken } from "./utils/DummyToken.sol";

import { LibTokenizedVaultStaking } from "src/libs/LibTokenizedVaultStaking.sol";

import { IntervalRewardPayedOutAlready } from "src/shared/CustomErrors.sol";

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

    NaymsAccount nlf;
    DummyToken naymToken;

    uint256 immutable usdcTotal = 1_000_000e6;
    uint256 immutable bobStakeAmount = 100e6;
    uint256 immutable sueStakeAmount = 200e6;
    uint256 immutable louStakeAmount = 400e6;
    uint256 immutable totalStakeAmount = 700e6; // should be => bobStakeAmount + sueStakeAmount + louStakeAmount;

    uint256 immutable rewardAmount = 100e6;

    mapping(bytes32 stakerId => mapping(uint64 interval => StakingState)) public stakingStates;
    function recordStakingState(bytes32 stakerId) public {
        stakingStates[stakerId][nayms.currentInterval(nlf.entityId)] = nayms.getStakingState(stakerId, nlf.entityId);
    }

    function setUp() public {
        naymToken = new DummyToken();

        nlf = makeNaymsAcc(LC.NLF_IDENTIFIER);

        NAYMSID = address(naymToken)._getIdForAddress();

        VTOKENID0 = vtokenId(NAYMSID, 0);
        VTOKENID1 = vtokenId(NAYMSID, 1);

        bob = makeNaymsAcc("Bob");
        sue = makeNaymsAcc("Sue");
        lou = makeNaymsAcc("Lou");

        // vm.startPrank(deployer);
        naymToken.mint(bob.addr, 10_000_000e18);
        naymToken.mint(sue.addr, 10_000_000e18);
        naymToken.mint(lou.addr, 10_000_000e18);

        startPrank(sa);
        nayms.addSupportedExternalToken(address(naymToken), 1e18);

        vm.startPrank(sm.addr);
        hCreateEntity(bob.entityId, bob, entity, "Bob data");
        hCreateEntity(sue.entityId, sue, entity, "Sue data");
        hCreateEntity(lou.entityId, lou, entity, "Lou data");
        hCreateEntity(sm.entityId, sm, entity, "System Manager data");
        hCreateEntity(nlf.entityId, nlf, entity, "NLF");

        vm.startPrank(bob.addr);
        naymToken.approve(address(nayms), 10_000_000e18);
        nayms.externalDeposit(address(naymToken), 10_000_000e18);

        vm.startPrank(sue.addr);
        naymToken.approve(address(nayms), 10_000_000e18);
        nayms.externalDeposit(address(naymToken), 10_000_000e18);

        vm.startPrank(lou.addr);
        naymToken.approve(address(nayms), 10_000_000e18);
        nayms.externalDeposit(address(naymToken), 10_000_000e18);

        // for now, assume sm pays the distributions
        startPrank(nlf);

        fundEntityUsdc(sm, usdcTotal);
        nayms.internalTransferFromEntity(nlf.entityId, usdcId, usdcTotal);
    }

    function vtokenId(bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32) {
        return LibTokenizedVaultStaking._vTokenId(_tokenId, _interval);
    }

    function initStaking(uint256 initDate) internal {
        StakingConfig memory config = StakingConfig({
            tokenId: NAYMSID,
            initDate: initDate,
            a: 15e12, // Amplification factor
            r: 85e12,
            divider: 100e12,
            interval: 30 days // Amount of time per interval in seconds
        });

        startPrank(sa);
        nayms.initStaking(nlf.entityId, config);
        vm.stopPrank();
    }

    function test_vtokenId() public {
        c.log(" ~ vTokenID Test ~".green());

        uint64 interval = 1;
        bytes20 entityId = bytes20(nlf.entityId << 96);
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

    function test_currentInterval() public {
        vm.warp(1);

        initStaking(block.timestamp);

        StakingConfig memory stakingConfig = nayms.getStakingConfig(nlf.entityId);

        assertEq(nayms.currentInterval(nlf.entityId), 0, "current interval not 0");

        vm.warp(stakingConfig.initDate + stakingConfig.interval - 1);
        assertEq(nayms.currentInterval(nlf.entityId), 0, "current interval not 0 again");

        vm.warp(stakingConfig.initDate + stakingConfig.interval);
        assertEq(nayms.currentInterval(nlf.entityId), 1, "current interval not 1");

        vm.warp(stakingConfig.initDate + stakingConfig.interval * 2);
        assertEq(nayms.currentInterval(nlf.entityId), 2, "current interval not 2");
    }

    function test_stake() public {
        initStaking(block.timestamp);

        StakingConfig memory config = nayms.getStakingConfig(nlf.entityId);

        assertEq(config.initDate, block.timestamp);
        assertEq(config.a + config.r, config.divider);

        startPrank(bob);
        nayms.stake(nlf.entityId, 1 ether);
    }

    function printBoosts(bytes32 entityId, bytes32 stakerId, string memory name) internal view {
        uint64 interval = nayms.currentInterval(entityId);
        StakingState memory stakingState = nayms.getStakingState(stakerId, entityId);

        c.log("");
        c.log("     ~~~~~~~  %s  ~~~~~~~".blue().bold(), name);
        c.log("     Balance[%s]:".green(), interval, stakingState.balance);
        c.log("       Boost[%s]:".green(), interval, stakingState.boost);
        c.log("");
    }

    function test_StakingScenario1() public {
        uint256 stakingStart = 100 days;
        initStaking(block.timestamp + stakingStart);

        c.log("(TIME: -20)".blue());
        vm.warp(stakingStart - 20 days);

        recordStakingState(bob.entityId);

        assertEq(stakingStates[bob.entityId][0].balance, 0, "Bob's staking balance[0] should be 0 before staking");

        recordStakingState(nlf.entityId);
        assertEq(nayms.internalBalanceOf(nlf.entityId, NAYMSID), 0, "Nayms' internal balance[0] should be 0 before staking");
        assertEq(stakingStates[nlf.entityId][0].balance, 0, "Nayms' staking balance[0] should be 0 before staking");

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        printBoosts(nlf.entityId, bob.entityId, "Bob");

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][0].balance, bobStakeAmount, "Bob's staking balance[0] should increase");
        assertEq(stakingStates[bob.entityId][0].boost, 15e6, "Bob's boost[0] should increase");

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][0].balance, bobStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(stakingStates[nlf.entityId][0].boost, 15e6, "Nayms' boost[0] should increase");

        c.log("(TIME: -10)".blue());
        vm.warp(stakingStart - 10 days);
        startPrank(sue);
        nayms.stake(nlf.entityId, sueStakeAmount);
        printBoosts(nlf.entityId, sue.entityId, "Sue");
        printBoosts(nlf.entityId, nlf.entityId, "Nayms");

        recordStakingState(sue.entityId);
        assertEq(stakingStates[sue.entityId][0].balance, sueStakeAmount, "Sue's staking balance[0] should increase");
        assertEq(stakingStates[sue.entityId][0].boost, 30e6, "Sue's boost[0] should increase");

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][0].balance, sueStakeAmount + bobStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(stakingStates[nlf.entityId][0].boost, 45e6, "Nayms' boost[0] should increase");

        c.log("(TIME: 0)".blue(), " ~~~~~~~~~~~~~~ Staking Started ~~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart);

        c.log("(TIME: 20)".blue());
        vm.warp(stakingStart + 20 days);
        startPrank(lou);
        nayms.stake(nlf.entityId, louStakeAmount);
        printBoosts(nlf.entityId, lou.entityId, "Lou");
        printBoosts(nlf.entityId, nlf.entityId, "Nayms");

        recordStakingState(lou.entityId);
        assertEq(stakingStates[lou.entityId][0].balance, louStakeAmount, "Lou's staking balance[0] should increase");
        assertEq(stakingStates[lou.entityId][0].boost, 20e6, "Lou's boost[0] should increase");

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][0].balance, totalStakeAmount, "Nayms' staking balance[0] should increase");
        assertEq(stakingStates[nlf.entityId][0].boost, 65e6, "Nayms' boost[0] should increase");

        c.log("(TIME: 30)".blue(), " ~~~~~~~~~~~~~ Distribution[1] Paid ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 30 days);
        startPrank(nlf);
        assertEq(nayms.lastIntervalPaid(nlf.entityId), 0, "Last interval paid should be 0");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal, "USCD balance should not change");

        assertEq(nayms.lastIntervalPaid(nlf.entityId), 0, "Last interval paid should be 1");
        nayms.payReward(bytes32("1"), nlf.entityId, usdcId, rewardAmount);

        assertEq(nayms.lastIntervalPaid(nlf.entityId), 1, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount, "USCD balance should change");
        assertEq(nayms.internalBalanceOf(nayms.vTokenId(NAYMSID, 0), usdcId), 100e6, "NLF's USDC balance should increase");

        vm.expectRevert(abi.encodeWithSelector(IntervalRewardPayedOutAlready.selector, 1));
        nayms.payReward(bytes32("1"), nlf.entityId, usdcId, rewardAmount);

        printBoosts(nlf.entityId, nlf.entityId, "Nayms");

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][1].balance, 765e6, "Nayms' staking balance[1] should increase");
        assertEq(stakingStates[nlf.entityId][1].boost, 9525e4, "Nayms' boost[1] should increase");

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][1].balance, 115e6, "Bob's staking balance[1] should increase");
        assertEq(stakingStates[bob.entityId][1].boost, 1275e4, "Bob's boost[1] should increase");

        recordStakingState(sue.entityId); // re-read state
        assertEq(stakingStates[sue.entityId][1].balance, 230e6, "Sue's staking balance[1] should increase");
        assertEq(stakingStates[sue.entityId][1].boost, 255e5, "Sue's boost[1] should increase");

        recordStakingState(lou.entityId); // re-read state
        assertEq(stakingStates[lou.entityId][1].balance, 420e6, "Lou's staking balance[1] should increase");
        assertEq(stakingStates[lou.entityId][1].boost, 57e6, "Lou's boost[1] should increase");

        printBoosts(nlf.entityId, lou.entityId, "Lou");

        c.log("(TIME: 60)".blue(), " ~~~~~~~~~~~~~ Distribution[2] Paid ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 60 days);

        assertEq(nayms.lastIntervalPaid(nlf.entityId), 1, "Last interval paid should be 1");
        nayms.payReward(bytes32("1"), nlf.entityId, usdcId, rewardAmount);
        assertEq(nayms.lastIntervalPaid(nlf.entityId), 2, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount * 2, "USCD balance should change");
        assertEq(nayms.internalBalanceOf(nayms.vTokenId(NAYMSID, 0), usdcId), rewardAmount * 2, "NLF's USDC balance should increase");

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][2].balance, 86025e4, "Nayms' staking balance[2] should increase");
        assertEq(stakingStates[nlf.entityId][2].boost, 809625e2, "Nayms' boost[2] should increase");

        printBoosts(nlf.entityId, nlf.entityId, "Nayms");

        c.log("(TIME: 62)".blue(), " ~~~~~~~~~~~~~ Bob Claimed Rewards ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 62 days);

        startPrank(bob);

        (, uint256[] memory bobRewardAmounts) = nayms.getRewardsBalance(nlf.entityId);
        assertEq(bobRewardAmounts[0], (stakingStates[bob.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance, "Bob's reward amount incorrect");

        nayms.collectRewards(nlf.entityId);

        // current interval is [2] here, so rewards should include intervals [0] and [1]
        // distribution is only paid for interval[1], hence the assert below:
        // prettier-ignore
        assertEq(
            nayms.internalBalanceOf(bob.entityId, usdcId), 
            (stakingStates[bob.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance, 
            "Bob's USDC balance should increase"
        ); // 15032679

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][2].balance, 12775e4, "Bob's staking balance[2] should increase");
        assertEq(stakingStates[bob.entityId][2].boost, 108375e2, "Bob's boost[2] should increase");

        recordStakingState(sue.entityId); // re-read state
        assertEq(stakingStates[sue.entityId][2].balance, 2555e5, "Sue's staking balance[2] should increase");
        assertEq(stakingStates[sue.entityId][2].boost, 21675e3, "Sue's boost[2] should increase");

        recordStakingState(lou.entityId); // re-read state
        assertEq(stakingStates[lou.entityId][2].balance, 477e6, "Lou's staking balance[2] should increase");
        assertEq(stakingStates[lou.entityId][2].boost, 4845e4, "Lou's boost[2] should increase");

        printBoosts(nlf.entityId, nlf.entityId, "Nayms");
        printBoosts(nlf.entityId, bob.entityId, "Bob");
        printBoosts(nlf.entityId, sue.entityId, "Sue");
        printBoosts(nlf.entityId, lou.entityId, "Lou");

        c.log("(TIME: 90)".blue(), " ~~~~~~~~~~~~~ 3rd Distribution Paid ~~~~~~~~~~~~~".yellow());
        startPrank(nlf);
        vm.warp(stakingStart + 90 days);
        assertEq(nayms.lastIntervalPaid(nlf.entityId), 2, "Last interval paid should be 2");
        nayms.payReward(bytes32("1"), nlf.entityId, usdcId, rewardAmount);

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][3].balance, 9412125e2, "Nayms' staking balance[3] should increase");
        assertEq(stakingStates[nlf.entityId][3].boost, 68818125, "Nayms' boost[3] should increase");
        printBoosts(nlf.entityId, nlf.entityId, "Nayms");

        c.log("(TIME: 91)".blue(), " ~~~~~~~~~~~~~ Sue Claimed Rewards ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 91 days);

        startPrank(sue);

        (, uint256[] memory sueRewardAmounts) = nayms.getRewardsBalance(nlf.entityId);
        assertEq(
            sueRewardAmounts[0],
            ((stakingStates[sue.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance) +
                ((stakingStates[sue.entityId][2].balance * rewardAmount) / stakingStates[nlf.entityId][2].balance),
            "Sue's reward amount incorrect"
        );

        nayms.collectRewards(nlf.entityId);

        // current interval is [3] here, so rewards should include intervals [0], [1] and [2]
        // distribution is not paid for interval[0], hence the assert below:
        // prettier-ignore
        assertEq(
            nayms.internalBalanceOf(sue.entityId, usdcId), 
            ((stakingStates[sue.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance) + ((stakingStates[sue.entityId][2].balance * rewardAmount) / stakingStates[nlf.entityId][2].balance), 
            "Sue's USDC balance should increase"
        ); // 59766027

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][3].balance, 138587500, "Bob's staking balance[3] should increase");
        assertEq(stakingStates[bob.entityId][3].boost, 9211875, "Bob's boost[3] should increase");

        recordStakingState(sue.entityId); // re-read state
        assertEq(stakingStates[sue.entityId][3].balance, 277175e3, "Sue's staking balance[3] should increase");
        assertEq(stakingStates[sue.entityId][3].boost, 18423750, "Sue's boost[3] should increase");

        recordStakingState(lou.entityId); // re-read state
        assertEq(stakingStates[lou.entityId][3].balance, 52545e4, "Lou's staking balance[3] should increase");
        assertEq(stakingStates[lou.entityId][3].boost, 411825e2, "Lou's boost[3] should increase");

        c.log("(TIME: 92)".blue(), " ~~~~~~~~~~~~~ Lou Claimed Rewards ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 92 days);

        startPrank(lou);

        (, uint256[] memory louRewardAmounts) = nayms.getRewardsBalance(nlf.entityId);
        assertEq(
            louRewardAmounts[0],
            ((stakingStates[lou.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance) +
                ((stakingStates[lou.entityId][2].balance * rewardAmount) / stakingStates[nlf.entityId][2].balance),
            "Lou's reward amount incorrect"
        );

        nayms.collectRewards(nlf.entityId);

        // current interval is [3] here, so rewards should include intervals [0], [1] and [2]
        // distribution is not paid for interval[0], hence the assert below:
        // prettier-ignore
        assertEq(
            nayms.internalBalanceOf(lou.entityId, usdcId), 
            ((stakingStates[lou.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance) + ((stakingStates[lou.entityId][2].balance * rewardAmount) / stakingStates[nlf.entityId][2].balance), 
            "Lou's USDC balance should increase"
        ); // 110350957

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][3].balance, 138587500, "Bob's staking balance[3] should increase");
        assertEq(stakingStates[bob.entityId][3].boost, 9211875, "Bob's boost[3] should increase");

        recordStakingState(sue.entityId); // re-read state
        assertEq(stakingStates[sue.entityId][3].balance, 277175e3, "Sue's staking balance[3] should increase");
        assertEq(stakingStates[sue.entityId][3].boost, 18423750, "Sue's boost[3] should increase");

        recordStakingState(lou.entityId); // re-read state
        assertEq(stakingStates[lou.entityId][3].balance, 52545e4, "Lou's staking balance[3] should increase");
        assertEq(stakingStates[lou.entityId][3].boost, 411825e2, "Lou's boost[3] should increase");

        assertEq(nayms.stakedAmount(bob.entityId, nlf.entityId), bobStakeAmount, "Incorrect Bob's original stake amount");
        assertEq(nayms.stakedAmount(sue.entityId, nlf.entityId), sueStakeAmount, "Incorrect Sue's original stake amount");
        assertEq(nayms.stakedAmount(lou.entityId, nlf.entityId), louStakeAmount, "Incorrect Lou's original stake amount");

        printBoosts(nlf.entityId, nlf.entityId, "Nayms");
        printBoosts(nlf.entityId, bob.entityId, "Bob");
        printBoosts(nlf.entityId, sue.entityId, "Sue");
        printBoosts(nlf.entityId, lou.entityId, "Lou");
    }

    function test_unstakeScenario1() public {
        test_StakingScenario1();
        startPrank(bob);
        nayms.unstake(nlf.entityId);
        startPrank(sue);
        nayms.unstake(nlf.entityId);
        startPrank(lou);
        nayms.unstake(nlf.entityId);

        // nayms token balances should be back to their original minted amounts per user
        assertEq(nayms.internalBalanceOf(bob.entityId, NAYMSID), 10_000_000e18);
        assertEq(nayms.internalBalanceOf(sue.entityId, NAYMSID), 10_000_000e18);
        assertEq(nayms.internalBalanceOf(lou.entityId, NAYMSID), 10_000_000e18);
    }
}
