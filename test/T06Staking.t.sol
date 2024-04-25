// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage, StdStyle } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults, c, LC, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { StakingConfig, StakingState } from "src/shared/FreeStructs.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { StakingFixture } from "test/fixtures/StakingFixture.sol";
import { DummyToken } from "./utils/DummyToken.sol";
import { LibTokenizedVaultStaking } from "src/libs/LibTokenizedVaultStaking.sol";
import { IntervalRewardPayedOutAlready, InvalidTokenRewardAmount } from "src/shared/CustomErrors.sol";

function makeId2(bytes12 _objecType, bytes20 randomBytes) pure returns (bytes32) {
    return bytes32((_objecType)) | (bytes32(randomBytes));
}

contract T06Staking is D03ProtocolDefaults {
    using LibHelpers for address;
    using stdStorage for StdStorage;
    using StdStyle for *;

    uint64 private constant SCALE_FACTOR = 1e14;
    uint64 private constant A = 15e12;
    uint64 private constant R = 85e12;
    uint64 private constant I = 30 days;

    bytes32 immutable VTOKENID = makeId2(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256(bytes("test"))));

    bytes32 VTOKENID1;
    bytes32 NAYMSID;

    NaymsAccount bob;
    NaymsAccount sue;
    NaymsAccount lou;

    NaymsAccount nlf;
    DummyToken naymToken;

    uint256 immutable usdcTotal = 1_000_000e6;
    uint256 immutable wethTotal = 1_000_000e18;
    uint256 immutable bobStakeAmount = 100e6;
    uint256 immutable sueStakeAmount = 200e6;
    uint256 immutable louStakeAmount = 400e6;

    uint256 immutable totalStakeAmount = 700e6; // should be => bobStakeAmount + sueStakeAmount + louStakeAmount;

    uint256 immutable rewardAmount = 100e6;

    uint256 constant stakingStart = 100 days;

    StakingFixture internal stakingFixture;

    mapping(bytes32 stakerId => mapping(uint64 interval => StakingState)) public stakingStates;
    function recordStakingState(bytes32 stakerId) public {
        stakingStates[stakerId][nayms.currentInterval(nlf.entityId)] = nayms.getStakingState(stakerId, nlf.entityId);
    }

    function setUp() public {
        stakingFixture = new StakingFixture();
        bytes4[] memory sSelectors = new bytes4[](2);
        sSelectors[0] = StakingFixture.stakeBoost.selector;
        sSelectors[1] = StakingFixture.stakeBalance.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        // prettier-ignore
        cut[0] = IDiamondCut.FacetCut({ 
            facetAddress: address(stakingFixture), 
            action: IDiamondCut.FacetCutAction.Add, 
            functionSelectors: sSelectors 
        });

        scheduleAndUpgradeDiamond(cut);

        naymToken = new DummyToken();

        nlf = makeNaymsAcc(LC.NLF_IDENTIFIER);

        NAYMSID = address(naymToken)._getIdForAddress();

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

        fundEntityWeth(sm, wethTotal);
        nayms.internalTransferFromEntity(nlf.entityId, wethId, wethTotal);
    }

    function stakeBoost(bytes32 stakerId, bytes32 entityId, uint64 interval) internal returns (uint256) {
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(stakingFixture.stakeBoost.selector, stakerId, entityId, interval));
        require(success, "Should get boost at interval from app storage");
        return abi.decode(result, (uint256));
    }

    function stakeBalance(bytes32 stakerId, bytes32 entityId, uint64 interval) internal returns (uint256) {
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(stakingFixture.stakeBalance.selector, stakerId, entityId, interval));
        require(success, "Should get balance at interval from app storage");
        return abi.decode(result, (uint256));
    }

    function vtokenId(bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32) {
        return LibTokenizedVaultStaking._vTokenId(_tokenId, _interval);
    }

    function initStaking(uint256 initDate) internal {
        StakingConfig memory config = StakingConfig({
            tokenId: NAYMSID,
            initDate: initDate,
            a: A, // Amplification factor
            r: R, // Boost decay factor
            divider: SCALE_FACTOR,
            interval: I // Amount of time per interval in seconds
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
        initStaking(block.timestamp + 1);

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
        uint256 start = block.timestamp + 1;

        initStaking(start);

        StakingConfig memory config = nayms.getStakingConfig(nlf.entityId);

        assertEq(config.initDate, start);
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
        vm.warp(stakingStart + 31 days);
        startPrank(nlf);
        assertEq(nayms.lastPaidInterval(nlf.entityId), 0, "Last interval paid should be 0");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal, "USCD balance should not change");

        assertEq(nayms.lastPaidInterval(nlf.entityId), 0, "Last interval paid should be 1");

        {
            bytes32 guid = makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("1"));
            vm.expectRevert(abi.encodeWithSelector(InvalidTokenRewardAmount.selector, guid, nlf.entityId, usdcId, 0));
            nayms.payReward(guid, nlf.entityId, usdcId, 0);
        }

        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("1")), nlf.entityId, usdcId, rewardAmount);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 1, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount, "USCD balance should change");
        assertEq(nayms.internalBalanceOf(nayms.vTokenId(NAYMSID, type(uint64).max), usdcId), 100e6, "NLF's USDC balance should increase");

        vm.expectRevert(abi.encodeWithSelector(IntervalRewardPayedOutAlready.selector, 1));
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("1a")), nlf.entityId, usdcId, rewardAmount);

        printBoosts(nlf.entityId, nlf.entityId, "Nayms");

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][1].balance, 765e6, "Nayms' staking balance[1] should increase");
        assertEq(stakingStates[nlf.entityId][1].boost, 9525e4, "Nayms' boost[1] should increase");

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][1].balance, calculateBalanceAtTime(30 days, bobStakeAmount), "Bob's staking balance[1] should increase");
        assertEq(stakingStates[bob.entityId][1].boost, 1275e4, "Bob's boost[1] should increase");

        recordStakingState(sue.entityId); // re-read state
        assertEq(stakingStates[sue.entityId][1].balance, calculateBalanceAtTime(30 days, sueStakeAmount), "Sue's staking balance[1] should increase");
        assertEq(stakingStates[sue.entityId][1].boost, 255e5, "Sue's boost[1] should increase");

        recordStakingState(lou.entityId); // re-read state
        assertEq(stakingStates[lou.entityId][1].balance, 420e6, "Lou's staking balance[1] should increase");
        assertEq(stakingStates[lou.entityId][1].boost, 57e6, "Lou's boost[1] should increase");

        printBoosts(nlf.entityId, lou.entityId, "Lou");

        c.log("(TIME: 60)".blue(), " ~~~~~~~~~~~~~ Distribution[2] Paid ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 60 days);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 1, "Last interval paid should be 1");

        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("2")), nlf.entityId, usdcId, rewardAmount);
        assertEq(nayms.lastPaidInterval(nlf.entityId), 2, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount * 2, "USCD balance should change");
        assertEq(nayms.internalBalanceOf(nayms.vTokenId(NAYMSID, type(uint64).max), usdcId), rewardAmount * 2, "NLF's USDC balance should increase");

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][2].balance, 86025e4, "Nayms' staking balance[2] should increase");
        assertEq(stakingStates[nlf.entityId][2].boost, 809625e2, "Nayms' boost[2] should increase");

        printBoosts(nlf.entityId, nlf.entityId, "Nayms");
        printBoosts(nlf.entityId, bob.entityId, "Bob");

        c.log("(TIME: 62)".blue(), " ~~~~~~~~~~~~~ Bob Claimed Rewards ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 62 days);

        startPrank(bob);

        recordStakingState(bob.entityId);
        recordStakingState(nlf.entityId);

        // current interval is [2] here, so rewards should include intervals [0] and [1]
        // distribution is only paid for interval[1], hence the assert below:
        // prettier-ignore
        uint256 bobsReward = (stakingStates[bob.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance +
                            ((stakingStates[bob.entityId][2].balance * rewardAmount) / stakingStates[nlf.entityId][2].balance);

        (, uint256[] memory bobRewardAmounts) = nayms.getRewardsBalance(bob.entityId, nlf.entityId);
        assertEq(bobRewardAmounts[0], bobsReward, "Bob's reward amount incorrect");

        nayms.collectRewards(nlf.entityId);

        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), bobsReward, "Bob's USDC balance should increase");

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][2].balance, calculateBalanceAtTime(60 days, bobStakeAmount), "Bob's staking balance[2] should increase");
        assertEq(stakingStates[bob.entityId][2].boost, 108375e2, "Bob's boost[2] should increase");

        recordStakingState(sue.entityId); // re-read state
        assertEq(stakingStates[sue.entityId][2].balance, calculateBalanceAtTime(60 days, sueStakeAmount), "Sue's staking balance[2] should increase");
        assertEq(stakingStates[sue.entityId][2].boost, 21675e3, "Sue's boost[2] should increase");

        recordStakingState(lou.entityId); // re-read state
        assertEq(stakingStates[lou.entityId][2].balance, calculateBalanceAtTime(40 days, louStakeAmount), "Lou's staking balance[2] should increase");
        assertEq(stakingStates[lou.entityId][2].boost, 4845e4, "Lou's boost[2] should increase");

        printBoosts(nlf.entityId, nlf.entityId, "Nayms");
        printBoosts(nlf.entityId, bob.entityId, "Bob");
        printBoosts(nlf.entityId, sue.entityId, "Sue");
        printBoosts(nlf.entityId, lou.entityId, "Lou");

        c.log("(TIME: 90)".blue(), " ~~~~~~~~~~~~~ 3rd Distribution Paid ~~~~~~~~~~~~~".yellow());
        startPrank(nlf);
        vm.warp(stakingStart + 90 days);
        assertEq(nayms.lastPaidInterval(nlf.entityId), 2, "Last interval paid should be 2");
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("3")), nlf.entityId, usdcId, rewardAmount);

        recordStakingState(nlf.entityId); // re-read state
        assertEq(stakingStates[nlf.entityId][3].balance, 9412125e2, "Nayms' staking balance[3] should increase");
        assertEq(stakingStates[nlf.entityId][3].boost, 68818125, "Nayms' boost[3] should increase");
        printBoosts(nlf.entityId, nlf.entityId, "Nayms");

        c.log("(TIME: 91)".blue(), " ~~~~~~~~~~~~~ Sue Claimed Rewards ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 91 days);

        startPrank(sue);

        recordStakingState(sue.entityId);
        recordStakingState(nlf.entityId);

        // current interval is [3] here, so rewards should include intervals [0], [1], [2] and [3]
        // distribution is not paid for interval[0], hence the assert below:
        // prettier-ignore
        uint256 suesReward = ((stakingStates[sue.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance) +
                             ((stakingStates[sue.entityId][2].balance * rewardAmount) / stakingStates[nlf.entityId][2].balance) +
                             ((stakingStates[sue.entityId][3].balance * rewardAmount) / stakingStates[nlf.entityId][3].balance);

        (, uint256[] memory sueRewardAmounts) = nayms.getRewardsBalance(sue.entityId, nlf.entityId);
        assertEq(sueRewardAmounts[0], suesReward, "Sue's reward amount incorrect");

        nayms.collectRewards(nlf.entityId);

        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), suesReward, "Sue's USDC balance should increase");

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][3].balance, calculateBalanceAtTime(90 days, bobStakeAmount), "Bob's staking balance[3] should increase");
        assertEq(stakingStates[bob.entityId][3].boost, 9211875, "Bob's boost[3] should increase");

        recordStakingState(sue.entityId); // re-read state
        assertEq(stakingStates[sue.entityId][3].balance, calculateBalanceAtTime(90 days, sueStakeAmount), "Sue's staking balance[3] should increase");
        assertEq(stakingStates[sue.entityId][3].boost, 18423750, "Sue's boost[3] should increase");

        recordStakingState(lou.entityId); // re-read state
        assertEq(stakingStates[lou.entityId][3].balance, calculateBalanceAtTime(70 days, louStakeAmount), "Lou's staking balance[3] should increase");
        assertEq(stakingStates[lou.entityId][3].boost, 411825e2, "Lou's boost[3] should increase");

        c.log("(TIME: 92)".blue(), " ~~~~~~~~~~~~~ Lou Claimed Rewards ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 92 days);

        startPrank(lou);

        // current interval is [3] here, so rewards should include intervals [0], [1], [2] and [3]
        // distribution is not paid for interval[0], hence the assert below:
        // prettier-ignore
        uint256 lousReward = ((stakingStates[lou.entityId][1].balance * rewardAmount) / stakingStates[nlf.entityId][1].balance) +
                             ((stakingStates[lou.entityId][2].balance * rewardAmount) / stakingStates[nlf.entityId][2].balance) +
                             ((stakingStates[lou.entityId][3].balance * rewardAmount) / stakingStates[nlf.entityId][3].balance);

        (, uint256[] memory louRewardAmounts) = nayms.getRewardsBalance(lou.entityId, nlf.entityId);
        assertEq(louRewardAmounts[0], lousReward, "Lou's reward amount incorrect");

        nayms.collectRewards(nlf.entityId);

        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), lousReward, "Lou's USDC balance should increase");

        recordStakingState(bob.entityId); // re-read state
        assertEq(stakingStates[bob.entityId][3].balance, calculateBalanceAtTime(90 days, bobStakeAmount), "Bob's staking balance[3] should not increase");
        assertEq(stakingStates[bob.entityId][3].boost, 9211875, "Bob's boost[3] should increase");

        recordStakingState(sue.entityId); // re-read state
        assertEq(stakingStates[sue.entityId][3].balance, calculateBalanceAtTime(90 days, sueStakeAmount), "Sue's staking balance[3] should not increase");
        assertEq(stakingStates[sue.entityId][3].boost, 18423750, "Sue's boost[3] should increase");

        recordStakingState(lou.entityId); // re-read state
        assertEq(stakingStates[lou.entityId][3].balance, calculateBalanceAtTime(70 days, louStakeAmount), "Lou's staking balance[3] should not increase");
        assertEq(stakingStates[lou.entityId][3].boost, 411825e2, "Lou's boost[3] should increase");

        {
            (uint256 bobStakedAmount_, ) = nayms.getStakingAmounts(bob.entityId, nlf.entityId);
            (uint256 sueStakedAmount_, ) = nayms.getStakingAmounts(sue.entityId, nlf.entityId);
            (uint256 louStakedAmount_, ) = nayms.getStakingAmounts(lou.entityId, nlf.entityId);
            assertEq(bobStakedAmount_, bobStakeAmount, "Incorrect Bob's original stake amount");
            assertEq(sueStakedAmount_, sueStakeAmount, "Incorrect Sue's original stake amount");
            assertEq(louStakedAmount_, louStakeAmount, "Incorrect Lou's original stake amount");
        }

        printBoosts(nlf.entityId, nlf.entityId, "Nayms");
        printBoosts(nlf.entityId, bob.entityId, "Bob");
        printBoosts(nlf.entityId, sue.entityId, "Sue");
        printBoosts(nlf.entityId, lou.entityId, "Lou");
    }

    function test_scenario1Extended() public {
        test_StakingScenario1();

        c.log("(TIME: 121)".blue(), " ~~~~~~~~~~~~~~ S1 EXTENSION ~~~~~~~~~~~~~~".yellow());

        vm.warp(stakingStart + 121 days);
        assertEq(nayms.currentInterval(nlf.entityId), 4);

        startPrank(bob);
        uint256 balBeforeStaking = nayms.internalBalanceOf(bob.entityId, usdcId);
        nayms.stake(nlf.entityId, bobStakeAmount);
        printBoosts(nlf.entityId, bob.entityId, "Bob");

        recordStakingState(bob.entityId);
        assertEq(stakingStates[bob.entityId][4].balance, 247799375, "Bob's staking balance[4] should increase");
        assertEq(stakingStates[bob.entityId][4].boost, 22330093, "Bob's boost[4] should increase");
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), balBeforeStaking + expectedRewardAt(bob, 2) + expectedRewardAt(bob, 3), "Bob - staking should collect rewards");

        startPrank(sue);
        balBeforeStaking = nayms.internalBalanceOf(sue.entityId, usdcId);
        nayms.stake(nlf.entityId, sueStakeAmount);
        printBoosts(nlf.entityId, sue.entityId, "Sue");
        recordStakingState(sue.entityId);
        // assertEq(stakingStates[sue.entityId][4].balance, 495598750, "Sue's staking balance[4] should increase");
        assertEq(stakingStates[sue.entityId][4].balance, 495598750, "Sue's staking balance[4] should increase");
        assertEq(stakingStates[sue.entityId][4].boost, 44660187, "Sue's boost[4] should increase");
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), balBeforeStaking + expectedRewardAt(sue, 3), "Sue - staking should collect rewards");

        startPrank(lou);
        balBeforeStaking = nayms.internalBalanceOf(lou.entityId, usdcId);
        nayms.stake(nlf.entityId, louStakeAmount);
        printBoosts(nlf.entityId, lou.entityId, "Lou");
        recordStakingState(lou.entityId);
        assertEq(stakingStates[lou.entityId][4].balance, 966632500, "Lou's staking balance[4] should increase");
        assertEq(stakingStates[lou.entityId][4].boost, 93005125, "Lou's boost[4] should increase");
        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), balBeforeStaking + expectedRewardAt(lou, 3), "Lou - staking should collect rewards");

        recordStakingState(nlf.entityId);

        vm.warp(stakingStart + 151 days);
        assertEq(nayms.currentInterval(nlf.entityId), 5);
        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("5")), nlf.entityId, usdcId, rewardAmount);
        printBoosts(nlf.entityId, nlf.entityId, "Nayms");
        recordStakingState(nlf.entityId);
        assertEq(stakingStates[nlf.entityId][5].balance, 1870026031, "Nayms' staking balance[5] should increase");
        assertEq(stakingStates[nlf.entityId][5].boost, 139496095, "Nayms' boost[5] should increase");

        recordStakingState(bob.entityId);
        recordStakingState(sue.entityId);
        recordStakingState(lou.entityId);

        vm.warp(stakingStart + 181 days);
        assertEq(nayms.currentInterval(nlf.entityId), 6);

        startPrank(lou);
        (, uint256[] memory rewardAmounts) = nayms.getRewardsBalance(lou.entityId, nlf.entityId);
        assertEq(rewardAmounts[0], expectedRewardAt(lou, 5), "Lou's reward amount incorrect");

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("6")), nlf.entityId, usdcId, rewardAmount);
        printBoosts(nlf.entityId, nlf.entityId, "Nayms");
        recordStakingState(nlf.entityId);
        assertEq(stakingStates[nlf.entityId][6].balance, 2009522126, "Nayms' staking balance[6] should increase");
        assertEq(stakingStates[nlf.entityId][6].boost, 118571680, "Nayms' boost[6] should increase");

        recordStakingState(bob.entityId);
        recordStakingState(sue.entityId);
        recordStakingState(lou.entityId);

        vm.warp(stakingStart + 211 days);

        startPrank(bob);
        (, rewardAmounts) = nayms.getRewardsBalance(bob.entityId, nlf.entityId);
        assertEq(rewardAmounts[0], expectedRewardAt(bob, 5) + expectedRewardAt(bob, 6), "Bob's reward amount incorrect");
        uint256 balBeforeCollecting = nayms.internalBalanceOf(bob.entityId, usdcId);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), balBeforeCollecting + expectedRewardAt(bob, 5) + expectedRewardAt(bob, 6), "Bob's USDC balance should increase");

        startPrank(sue);
        (, rewardAmounts) = nayms.getRewardsBalance(sue.entityId, nlf.entityId);
        assertEq(rewardAmounts[0], expectedRewardAt(sue, 5) + expectedRewardAt(sue, 6), "Sue's reward amount incorrect");
        balBeforeCollecting = nayms.internalBalanceOf(sue.entityId, usdcId);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), balBeforeCollecting + expectedRewardAt(sue, 5) + expectedRewardAt(sue, 6), "Sue's USDC balance should increase");

        startPrank(lou);
        (, rewardAmounts) = nayms.getRewardsBalance(lou.entityId, nlf.entityId);
        assertEq(rewardAmounts[0], expectedRewardAt(lou, 5) + expectedRewardAt(lou, 6), "Lou's reward amount incorrect");
        balBeforeCollecting = nayms.internalBalanceOf(lou.entityId, usdcId);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), balBeforeCollecting + expectedRewardAt(lou, 5) + expectedRewardAt(lou, 6), "Lou's USDC balance should increase");
    }

    function expectedRewardAt(NaymsAccount memory na, uint64 interval) public view returns (uint256) {
        return
            stakingStates[na.entityId][interval].lastCollectedInterval >= interval
                ? 0
                : (stakingStates[na.entityId][interval].balance * rewardAmount) / stakingStates[nlf.entityId][interval].balance;
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

    function currentReward(bytes32 _stakerId) private view returns (uint256) {
        (, uint256[] memory rewards) = nayms.getRewardsBalance(_stakerId, nlf.entityId);
        return rewards.length > 0 ? rewards[0] : 0;
    }

    /**
     * Test case for the following scenario:
     *
     *  interval[1]
     *  - stake
     *
     *  interval[2]
     *  - pay reward[2]
     *
     *  interval[3]
     *  - collect reward[2]
     *  - pay reward[3]
     *
     *  interval[4]
     *  - collect reward[3]
     */
    function test_collectAndPayRewardAtSameInterval() public {
        uint256 start = 1;
        initStaking(start);
        c.log(" ~ [%s] Staking start".blue(), nayms.currentInterval(nlf.entityId));

        vm.warp(start + 35 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        recordStakingState(bob.entityId);
        assertEq(stakingStates[bob.entityId][1].balance, bobStakeAmount, "Bob's staking balance[1] should increase");
        c.log(" ~ [%s] Bob staked".blue(), nayms.currentInterval(nlf.entityId));

        vm.warp(start + 70 days);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 0, "Last interval paid should be 0");

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("1")), nlf.entityId, usdcId, rewardAmount); // 100 USDC
        c.log(" ~ [%s] Reward paid out".blue(), nayms.currentInterval(nlf.entityId));

        startPrank(bob);
        vm.warp(start + 91 days);

        assertEq(currentReward(bob.entityId), rewardAmount, "Bob's reward[3] should increase");
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), 0);

        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), rewardAmount);
        c.log(" ~ [%s] Reward[2] collected".blue(), nayms.currentInterval(nlf.entityId));

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("2")), nlf.entityId, usdcId, rewardAmount); // 100 USDC
        c.log(" ~ [%s] Reward paid out".blue(), nayms.currentInterval(nlf.entityId));

        vm.warp(start + 125 days);

        startPrank(bob);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), rewardAmount * 2);
        c.log(" ~ [%s] Reward[3] collected".blue(), nayms.currentInterval(nlf.entityId));
    }

    function test_skipPayingAnInterval() public {
        initStaking({ initDate: 1 });
        c.log(" ~ [%s] Staking start".blue(), nayms.currentInterval(nlf.entityId));

        vm.warp(31 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        recordStakingState(bob.entityId);
        assertEq(stakingStates[bob.entityId][1].balance, bobStakeAmount, "Bob's staking balance[1] should increase");
        c.log(" ~ [%s] Bob staked".blue(), nayms.currentInterval(nlf.entityId));

        vm.warp(61 days);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 0, "Last interval paid should be 0");

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("1")), nlf.entityId, usdcId, rewardAmount); // 100 USDC
        c.log(" ~ [%s] Reward paid out".blue(), nayms.currentInterval(nlf.entityId));

        assertEq(nayms.lastPaidInterval(nlf.entityId), 2, "Last interval paid should be 2");

        vm.warp(151 days);
        assertEq(nayms.currentInterval(nlf.entityId), 5);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("2")), nlf.entityId, usdcId, rewardAmount); // 100 USDC

        vm.warp(181 days);

        startPrank(bob);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), rewardAmount * 2);
    }

    function test_twoStakingRewardCurrencies() public {
        initStaking({ initDate: 1 });
        c.log(" ~ [%s] Staking start".blue(), nayms.currentInterval(nlf.entityId));

        vm.warp(31 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        recordStakingState(bob.entityId);
        assertEq(stakingStates[bob.entityId][1].balance, bobStakeAmount, "Bob's staking balance[1] should increase");
        c.log(" ~ [%s] Bob staked".blue(), nayms.currentInterval(nlf.entityId));

        vm.warp(61 days);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 0, "Last interval paid should be 0");

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("1")), nlf.entityId, usdcId, rewardAmount); // 100 USDC
        c.log(" ~ [%s] Reward paid out".blue(), nayms.currentInterval(nlf.entityId));
        assertEq(nayms.lastPaidInterval(nlf.entityId), 2, "Last interval paid should be 2");

        vm.warp(91 days);

        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("2")), nlf.entityId, wethId, 1 ether);
        c.log(" ~ [%s] Reward paid out".blue(), nayms.currentInterval(nlf.entityId));
        assertEq(nayms.lastPaidInterval(nlf.entityId), 3, "Last interval paid should be 3");

        vm.warp(121 days);

        startPrank(bob);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), rewardAmount);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 1 ether);
    }

    function calculateBalanceAtTime(uint256 t, uint256 initialBalance) public pure returns (uint256 boostedBalanceAtTime) {
        uint256 Xm = calculateMultiplier(t, I, A, R);
        boostedBalanceAtTime = (initialBalance * Xm) / SCALE_FACTOR;
    }

    function calculateMultiplier(uint256 t, uint256 tn, uint256 Xa, uint256 Xr) public pure returns (uint256 Xm) {
        // Xr is r * SCALE_FACTOR

        require(t >= tn, "t < tn not supported yet");

        uint256 X = SCALE_FACTOR;
        uint256 n = t / tn;
        uint256 XrPowN = powN(Xr, n);
        uint256 XrPowNPlusOne = powN(Xr, n + 1);

        uint256 C0 = (Xa * (X - XrPowN)) / (X - Xr);
        uint256 C1 = (Xa * (X - XrPowNPlusOne)) / (X - Xr);

        Xm = (tn * (X + C0) + (C1 - C0) * (t - n * tn)) / tn;
    }

    function powN(uint256 Xr, uint256 n) public pure returns (uint) {
        uint result = Xr;

        for (uint i = 1; i < n; i++) {
            result = (result * Xr) / SCALE_FACTOR;
        }

        return result;
    }

    function test_NAY1_boostReset() public {
        initStaking(block.timestamp + 1);

        uint256 bobsBoost = (bobStakeAmount * A) / (A + R);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        assertEq(stakeBalance(bob.entityId, nlf.entityId, 0), bobStakeAmount, "Bob's stake should increase");
        assertEq(stakeBoost(bob.entityId, nlf.entityId, 0), bobsBoost, "Bob's boost should increase");

        nayms.unstake(nlf.entityId);
        assertEq(stakeBalance(bob.entityId, nlf.entityId, 0), 0, "Bob's stake[0] should decrease");
        assertEq(stakeBalance(bob.entityId, nlf.entityId, 1), 0, "Bob's stake[0] should decrease");
        assertEq(stakeBoost(bob.entityId, nlf.entityId, 0), 0, "Bob's boost[1] should decrease");
        assertEq(stakeBoost(bob.entityId, nlf.entityId, 1), 0, "Bob's boost[1] should decrease");

        vm.warp(40 days);
        nayms.stake(nlf.entityId, bobStakeAmount);

        uint64 currentInterval = nayms.currentInterval(nlf.entityId);
        uint256 startCurrent = nayms.calculateStartTimeOfInterval(nlf.entityId, currentInterval);

        uint256 bobsBoost2 = (bobsBoost * (block.timestamp - startCurrent)) / I;
        uint256 bobsBoost1 = bobsBoost - bobsBoost2;

        assertEq(stakeBalance(bob.entityId, nlf.entityId, 0), 0, "Bob's stake[0] should not change");
        assertEq(stakeBalance(bob.entityId, nlf.entityId, 1), bobStakeAmount, "Bob's stake[1] should increase");
        assertEq(stakeBalance(bob.entityId, nlf.entityId, 2), 0, "Bob's stake[2] should not change");
        assertEq(stakeBoost(bob.entityId, nlf.entityId, 0), 0, "Bob's boost[0] should not change");
        assertEq(stakeBoost(bob.entityId, nlf.entityId, 1), bobsBoost1, "Bob's boost[1] should increase");
        assertEq(stakeBoost(bob.entityId, nlf.entityId, 2), bobsBoost2, "Bob's boost[2] should increase");
    }

    function test_NAY2_stakingBalanceTotalAfterUnstake() public {
        initStaking(I);
        vm.warp(I + 10 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);

        assertEq(stakeBalance(bob.entityId, nlf.entityId, 0), bobStakeAmount, "Bob's balance[0] incorrect");
        assertEq(stakeBalance(nlf.entityId, nlf.entityId, 0), bobStakeAmount, "NLF's balance[0] incorrect");

        c.log(" -- bob staked --".yellow());
        c.log(" -- bob[0]: %s".blue(), stakeBalance(bob.entityId, nlf.entityId, 0));
        c.log("    bob[1]: %s".blue(), stakeBalance(bob.entityId, nlf.entityId, 1));
        c.log(" -- bob's reward[%s]: %s".blue(), 1, getRewards(bob.entityId, nlf.entityId));
        c.log(" ");
        c.log(" -- nlf[0]: %s".blue(), stakeBalance(nlf.entityId, nlf.entityId, 0));
        c.log("    nlf[1]: %s".blue(), stakeBalance(nlf.entityId, nlf.entityId, 1));

        startPrank(sue);
        nayms.stake(nlf.entityId, sueStakeAmount);

        assertEq(stakeBalance(sue.entityId, nlf.entityId, 0), sueStakeAmount, "Sue's balance[0] incorrect");
        assertEq(stakeBalance(nlf.entityId, nlf.entityId, 0), bobStakeAmount + sueStakeAmount, "NLF's balance[0] incorrect");

        c.log(" -- sue staked --".yellow());
        c.log(" -- bob[0]: %s".blue(), stakeBalance(bob.entityId, nlf.entityId, 0));
        c.log("    bob[1]: %s".blue(), stakeBalance(bob.entityId, nlf.entityId, 1));
        c.log(" -- bob's reward[%s]: %s".blue(), 0, getRewards(bob.entityId, nlf.entityId));
        c.log(" ");
        c.log(" -- sue[0]: %s".blue(), stakeBalance(sue.entityId, nlf.entityId, 0));
        c.log("    sue[1]: %s".blue(), stakeBalance(sue.entityId, nlf.entityId, 1));
        c.log(" -- sue's reward[%s]: %s".blue(), 0, getRewards(sue.entityId, nlf.entityId));
        c.log(" ");
        c.log(" -- nlf[0]: %s".blue(), stakeBalance(nlf.entityId, nlf.entityId, 0));
        c.log("    nlf[1]: %s".blue(), stakeBalance(nlf.entityId, nlf.entityId, 1));

        vm.warp(2 * I);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("r1")), nlf.entityId, usdcId, rewardAmount);

        vm.warp(2 * I + 1);

        assertEq(getRewards(bob.entityId, nlf.entityId), (rewardAmount * bobStakeAmount) / (bobStakeAmount + sueStakeAmount), "Bob's reward[1] incorrect");
        assertEq(getRewards(sue.entityId, nlf.entityId), (rewardAmount * sueStakeAmount) / (bobStakeAmount + sueStakeAmount), "Sue's reward[1] incorrect");

        c.log(" -- rewards payed out [1] --".yellow());
        c.log(" -- bob[0]: %s".blue(), stakeBalance(bob.entityId, nlf.entityId, 0));
        c.log("    bob[1]: %s".blue(), stakeBalance(bob.entityId, nlf.entityId, 1));
        c.log(" -- bob's reward[%s]: %s".blue(), 1, getRewards(bob.entityId, nlf.entityId));
        c.log(" ");
        c.log(" -- sue[0]: %s".blue(), stakeBalance(sue.entityId, nlf.entityId, 0));
        c.log("    sue[1]: %s".blue(), stakeBalance(sue.entityId, nlf.entityId, 1));
        c.log(" -- sue's reward[%s]: %s".blue(), 1, getRewards(sue.entityId, nlf.entityId));
        c.log(" ");
        c.log(" -- nlf[0]: %s".blue(), stakeBalance(nlf.entityId, nlf.entityId, 0));
        c.log("    nlf[1]: %s".blue(), stakeBalance(nlf.entityId, nlf.entityId, 1));

        startPrank(sue);
        nayms.unstake(nlf.entityId);

        assertEq(stakeBalance(sue.entityId, nlf.entityId, 1), 0, "Sue's balance[1] should be 0");
        assertEq(getRewards(sue.entityId, nlf.entityId), 0, "Sue's reward[1] should have been claimed and be zero now");

        assertEq(
            getRewards(bob.entityId, nlf.entityId),
            rewardAmount - (rewardAmount * sueStakeAmount) / (bobStakeAmount + sueStakeAmount), // this way we consider rounding error margin
            "Bob's reward[1] should not change after sue unstakes"
        );

        c.log(" -- sue unstaked --".yellow());
        c.log(" -- bob[0]: %s".blue(), stakeBalance(bob.entityId, nlf.entityId, 0));
        c.log("    bob[1]: %s".blue(), stakeBalance(bob.entityId, nlf.entityId, 1));
        c.log(" -- bob's reward[%s]: %s".blue(), 1, getRewards(bob.entityId, nlf.entityId));
        c.log(" ");
        c.log(" -- sue[0]: %s".blue(), stakeBalance(sue.entityId, nlf.entityId, 0));
        c.log("    sue[1]: %s".blue(), stakeBalance(sue.entityId, nlf.entityId, 1));
        c.log("    last collected: %s".blue(), nayms.lastCollectedInterval(nlf.entityId, sue.entityId));
        c.log(" ");
        c.log(" -- nlf[0]: %s".blue(), stakeBalance(nlf.entityId, nlf.entityId, 0));
        c.log("    nlf[1]: %s".blue(), stakeBalance(nlf.entityId, nlf.entityId, 1));

        assertEq(stakeBalance(nlf.entityId, nlf.entityId, 0), bobStakeAmount + sueStakeAmount, "NLF's balance[0] should not change");
        assertEq(stakeBalance(nlf.entityId, nlf.entityId, 1), bobStakeAmount + stakeBoost(bob.entityId, nlf.entityId, 0), "NLF's balance[1] should change");
    }

    function getRewards(bytes32 stakerId, bytes32 nlfId) private view returns (uint256) {
        (, uint256[] memory amounts) = nayms.getRewardsBalance(stakerId, nlfId);
        return amounts.length > 0 ? amounts[0] : 0;
    }

    function test_NAY3_nlfItselfCantStake() public {
        startPrank(nlf);
        naymToken.mint(nlf.addr, 10_000_000e18);
        naymToken.approve(address(nayms), 10_000_000e18);
        nayms.externalDeposit(address(naymToken), 10_000_000e18);

        vm.expectRevert("staking entity itself cannot stake");
        nayms.stake(nlf.entityId, 10 ether);
    }
}
