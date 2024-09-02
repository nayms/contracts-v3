// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage, StdStyle, StdAssertions } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults, c, LC, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { StakingConfig, StakingState } from "src/shared/FreeStructs.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { StakingFixture } from "test/fixtures/StakingFixture.sol";
import { DummyToken } from "./utils/DummyToken.sol";
import { LibTokenizedVaultStaking } from "src/libs/LibTokenizedVaultStaking.sol";
import { IERC20 } from "src/interfaces/IERC20.sol";

import { IntervalRewardPayedOutAlready, InvalidTokenRewardAmount, InvalidStakingAmount, InvalidStaker, EntityDoesNotExist, StakingAlreadyStarted, StakingNotStarted } from "src/shared/CustomErrors.sol";

function makeId2(bytes12 _objecType, bytes20 randomBytes) pure returns (bytes32) {
    return bytes32((_objecType)) | (bytes32(randomBytes));
}

contract T06Staking is D03ProtocolDefaults {
    using LibHelpers for address;
    using stdStorage for StdStorage;
    using StdStyle for *;

    uint64 private constant SCALE_FACTOR = 1_000_000; // 6 digits because USDC
    uint64 private constant A = (15 * SCALE_FACTOR) / 100;
    uint64 private constant R = (85 * SCALE_FACTOR) / 100;
    uint64 private constant I = 30 days;

    bytes32 immutable VTOKENID = makeId2(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256(bytes("test"))));

    bytes32 VTOKENID1;
    bytes32 NAYM_ID;

    NaymsAccount bob;
    NaymsAccount sue;
    NaymsAccount lou;

    NaymsAccount nlf;
    DummyToken naymToken;

    uint256 private constant usdcTotal = 1_000_000e6;
    uint256 private constant wethTotal = 1_000_000e18;

    uint256 private constant bobStakeAmount = 100e6;
    uint256 private constant sueStakeAmount = 200e6;
    uint256 private constant louStakeAmount = 400e6;

    uint256 private constant totalStakeAmount = bobStakeAmount + sueStakeAmount + louStakeAmount;

    uint256 immutable rewardAmount = 100e6;

    uint256 constant stakingStart = 100 days;

    StakingFixture internal stakingFixture;

    mapping(bytes32 entityId => uint256) usdcBalance;
    mapping(bytes32 entityId => mapping(uint64 index => uint256)) unclaimedReward;

    uint256 bobCurrentReward;
    uint256 sueCurrentReward;
    uint256 louCurrentReward;

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

        NAYM_ID = address(naymToken)._getIdForAddress();

        VTOKENID1 = vtokenId(nlf.entityId, NAYM_ID, 1);

        bob = makeNaymsAcc("Bob");
        sue = makeNaymsAcc("Sue");
        lou = makeNaymsAcc("Lou");

        naymToken.mint(bob.addr, 10_000_000e18);
        naymToken.mint(sue.addr, 10_000_000e18);
        naymToken.mint(lou.addr, 10_000_000e18);

        startPrank(sa);
        nayms.addSupportedExternalToken(address(naymToken), 100);

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

    function vtokenId(bytes32 _entityId, bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32) {
        return LibTokenizedVaultStaking._vTokenId(_entityId, _tokenId, _interval);
    }

    function currentInterval() public view returns (uint64) {
        return nayms.currentInterval(nlf.entityId);
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

    function assertStakedAmount(bytes32 stakerId, uint256 amount, string memory message) private {
        (uint256 staked, ) = nayms.getStakingAmounts(stakerId, nlf.entityId);
        assertEq(staked, amount, message);
    }

    function getRewards(bytes32 stakerId, bytes32 nlfId) private view returns (uint256) {
        (, uint256[] memory amounts) = nayms.getRewardsBalance(stakerId, nlfId);
        return amounts.length > 0 ? amounts[0] : 0;
    }

    function printCurrentState(bytes32 entityId, bytes32 stakerId, string memory name) internal view {
        uint64 interval = currentInterval();
        (uint256 stakedAmount_, uint256 boostedAmount_) = nayms.getStakingAmounts(stakerId, entityId);
        c.log("");
        c.log("   ~~~~~~~  %s  ~~~~~~~".blue().bold(), name);
        c.log("     Balance[%s]:".green(), interval, stakedAmount_);
        c.log("     Boosted[%s]:".green(), interval, boostedAmount_);
        c.log("     Rewards[%s]:".green(), interval, getRewards(stakerId, entityId) / 1e6);
        c.log("");
    }

    function initStaking(uint256 initDate) internal {
        StakingConfig memory config = StakingConfig({
            tokenId: NAYM_ID,
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

    function calculateBoost(uint256 startTime, uint256 currentTime, uint256 r, uint256 tn, uint256 scaleFactor) public pure returns (uint256 multiplier) {
        uint256 startInterval = startTime / tn;
        uint256 currentIntervl = currentTime / tn;

        uint256 timeFromStartIntervalToCurrentInterval = (currentIntervl - startInterval) * tn;

        uint256 otherTime = 0;
        if (timeFromStartIntervalToCurrentInterval > tn) {
            otherTime = timeFromStartIntervalToCurrentInterval - tn;
        }

        uint256 timeAfterStartInterval = startTime - tn * startInterval;

        uint256 multiplier1 = (timeAfterStartInterval * scaleFactor) / tn;
        uint256 multiplier0 = scaleFactor - multiplier1;

        if (timeFromStartIntervalToCurrentInterval > otherTime) {
            multiplier = multiplier + multiplier0 * m(timeFromStartIntervalToCurrentInterval, tn, r, scaleFactor);

            if (timeFromStartIntervalToCurrentInterval > tn) {
                multiplier = multiplier + multiplier1 * m(otherTime, tn, r, scaleFactor);
            }
        }
    }

    function m(uint256 t, uint256 tn, uint256 Xr, uint256 scaleFactor) public pure returns (uint256 Xm) {
        // Xr is r * SCALE_FACTOR
        uint256 X = scaleFactor;
        uint256 n = t / tn;
        uint256 XrPowN = powN(Xr, n);
        uint256 XrPowNPlusOne = powN(Xr, n + 1);

        uint256 C0 = X - XrPowN;
        uint256 C1 = X - XrPowNPlusOne;

        Xm = (tn * (X + C0) + (C1 - C0) * (t - n * tn)) / tn;
    }

    function powN(uint256 Xr, uint256 n) public pure returns (uint) {
        uint result = Xr;

        for (uint i = 1; i < n; i++) {
            result = (result * Xr) / SCALE_FACTOR;
        }

        return result;
    }

    function test_initStaking() public {
        StakingConfig memory config;

        startPrank(sa);

        vm.expectRevert(abi.encodeWithSelector(EntityDoesNotExist.selector, bytes32(0)));
        nayms.initStaking(bytes32(0), config);
        vm.stopPrank();

        initStaking(block.timestamp + 1);

        config = StakingConfig({
            tokenId: NAYM_ID,
            initDate: block.timestamp + 2,
            a: A, // Amplification factor
            r: R, // Boost decay factor
            divider: SCALE_FACTOR,
            interval: I // Amount of time per interval in seconds
        });

        startPrank(sa);
        vm.expectRevert(abi.encodeWithSelector(StakingAlreadyStarted.selector, nlf.entityId, config.tokenId));
        nayms.initStaking(nlf.entityId, config);
        vm.stopPrank();
    }

    function test_vtokenId() public {
        c.log(" ~ vTokenID Test ~".green());

        uint64 interval = 1;

        bytes20 entityId = bytes20(keccak256(abi.encodePacked(nlf.entityId, NAYM_ID)));
        bytes32 vId = vtokenId(nlf.entityId, NAYM_ID, interval);

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

    function test_Stake_InvalidStakingAmount() public {
        uint256 start = block.timestamp + 1;

        initStaking(start);

        startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(InvalidStakingAmount.selector));
        nayms.stake(nlf.entityId, 0);
    }

    function test_stake() public {
        uint256 start = block.timestamp + 1;

        initStaking(start);

        StakingConfig memory config = nayms.getStakingConfig(nlf.entityId);

        assertEq(config.initDate, start);
        assertEq(config.a + config.r, config.divider);

        startPrank(bob);
        nayms.stake(nlf.entityId, 1 ether);
        assertStakedAmount(bob.entityId, 1 ether, "Bob's staked amount should increase");
    }

    function test_payRewardBeforeStakingStarted() public {
        uint256 start = block.timestamp + 10 days;

        initStaking(start);

        StakingConfig memory config = nayms.getStakingConfig(nlf.entityId);

        startPrank(nlf);

        vm.expectRevert(abi.encodeWithSelector(StakingNotStarted.selector, nlf.entityId, config.tokenId));
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1")), nlf.entityId, usdcId, 100 ether);
    }

    function test_StakingScenario1() public {
        initStaking(block.timestamp + stakingStart);

        vm.warp(stakingStart - 20 days);

        assertStakedAmount(bob.entityId, 0, "Bob's staked amount [1] should be zero");

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        assertStakedAmount(bob.entityId, bobStakeAmount, "Bob's staked amount [0] should increase");

        c.log("(TIME: -20)".blue(), " ~~~~~~~~~~~~~~ Bob Staked ~~~~~~~~~~~~~~".yellow());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        vm.warp(stakingStart - 10 days);
        startPrank(sue);
        nayms.stake(nlf.entityId, sueStakeAmount);
        assertStakedAmount(sue.entityId, sueStakeAmount, "Sue's staked amount [0] should increase");

        c.log("(TIME: -20)".blue(), " ~~~~~~~~~~~~~~ Sue Staked ~~~~~~~~~~~~~~".yellow());
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, nlf.entityId, "Nayms");

        c.log("(TIME: 0)".blue(), "   ~~~~~~~~~~~~~~ Staking Started ~~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart);

        vm.warp(stakingStart + 20 days);
        startPrank(lou);
        nayms.stake(nlf.entityId, louStakeAmount);
        assertStakedAmount(lou.entityId, louStakeAmount, "Lou's staked amount [0] should increase");

        c.log("(TIME: 20)".blue(), "  ~~~~~~~~~~~~~~ Lou Staked ~~~~~~~~~~~~~~".yellow());
        printCurrentState(nlf.entityId, lou.entityId, "Lou");
        printCurrentState(nlf.entityId, nlf.entityId, "Nayms");

        assertEq(nayms.lastPaidInterval(nlf.entityId), 0, "Last interval paid should be 0");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal, "USCD balance should not change");

        c.log("(TIME: 30)".blue(), "  ~~~~~~~~~~~~~~ Distribution[1] Paid ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 31 days);
        startPrank(nlf);

        {
            bytes32 guid = makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1"));
            vm.expectRevert(abi.encodeWithSelector(InvalidTokenRewardAmount.selector, guid, nlf.entityId, usdcId, 0));
            nayms.payReward(guid, nlf.entityId, usdcId, 0);
        }

        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1")), nlf.entityId, usdcId, rewardAmount);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 1, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount, "USDC balance should change");
        assertEq(nayms.internalBalanceOf(nayms.vTokenId(nlf.entityId, NAYM_ID, type(uint64).max), usdcId), rewardAmount, "NLF's USDC balance should increase");

        vm.expectRevert(abi.encodeWithSelector(IntervalRewardPayedOutAlready.selector, 1));
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1a")), nlf.entityId, usdcId, rewardAmount);

        printCurrentState(nlf.entityId, nlf.entityId, "Nayms");

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, lou.entityId, "Lou");

        {
            uint256 bobBoost = (calculateBoost(0, 31 days, R, I, SCALE_FACTOR) * bobStakeAmount) / totalStakeAmount;
            uint256 sueBoost = (calculateBoost(0, 31 days, R, I, SCALE_FACTOR) * sueStakeAmount) / totalStakeAmount;
            uint256 louBoost = (calculateBoost(20 days, 31 days, R, I, SCALE_FACTOR) * louStakeAmount) / totalStakeAmount;

            uint256 totalBoost = bobBoost + sueBoost + louBoost;

            bobCurrentReward = (rewardAmount * bobBoost) / totalBoost;
            sueCurrentReward = (rewardAmount * sueBoost) / totalBoost;
            louCurrentReward = (rewardAmount * louBoost) / totalBoost;

            assertEq(getRewards(bob.entityId, nlf.entityId), bobCurrentReward, "Bob's reward [1] should increase");
            assertEq(getRewards(sue.entityId, nlf.entityId), sueCurrentReward, "Sue's reward [1] should increase");
            assertEq(getRewards(lou.entityId, nlf.entityId), louCurrentReward, "Lou's reward [1] should increase");
        }

        c.log("(TIME: 60)".blue(), "  ~~~~~~~~~~~~~~ Distribution[2] Paid ~~~~~~~~~~~~~".yellow());
        vm.warp(stakingStart + 60 days);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 1, "Last interval paid should be 1");

        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward2")), nlf.entityId, usdcId, rewardAmount);
        assertEq(nayms.lastPaidInterval(nlf.entityId), 2, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount * 2, "USCD balance should change");
        assertEq(nayms.internalBalanceOf(nayms.vTokenId(nlf.entityId, NAYM_ID, type(uint64).max), usdcId), rewardAmount * 2, "NLF's USDC balance should increase");

        printCurrentState(nlf.entityId, nlf.entityId, "Nayms");
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        vm.warp(stakingStart + 62 days);

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, lou.entityId, "Lou");

        {
            uint256 bobBoost = (calculateBoost(0, 60 days, R, I, SCALE_FACTOR) * bobStakeAmount) / totalStakeAmount;
            uint256 sueBoost = (calculateBoost(0, 60 days, R, I, SCALE_FACTOR) * sueStakeAmount) / totalStakeAmount;
            uint256 louBoost = (calculateBoost(20 days, 60 days, R, I, SCALE_FACTOR) * louStakeAmount) / totalStakeAmount;

            uint256 totalBoost = bobBoost + sueBoost + louBoost;

            bobCurrentReward += (rewardAmount * (bobBoost)) / totalBoost;
            sueCurrentReward += (rewardAmount * (sueBoost)) / totalBoost;
            louCurrentReward += (rewardAmount * (louBoost)) / totalBoost;

            usdcBalance[bob.entityId] += bobCurrentReward;

            assertEq(getRewards(bob.entityId, nlf.entityId), bobCurrentReward, "Bob's reward [2] should increase".red());
            assertEq(getRewards(sue.entityId, nlf.entityId), sueCurrentReward, "Sue's reward [2] should increase".red());
            assertEq(getRewards(lou.entityId, nlf.entityId), louCurrentReward, "Lou's reward [2] should increase".red());
        }

        startPrank(bob);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), bobCurrentReward, "Bob's USDC balance should increase");
        assertStakedAmount(bob.entityId, bobStakeAmount, "Bob's staked amount [2] should not change");
        c.log("(TIME: 62)".blue(), "  ~~~~~~~~~~~~~~ Bob Claimed Rewards ~~~~~~~~~~~~~".yellow());

        assertEq(getRewards(bob.entityId, nlf.entityId), 0, "Bob's reward [2] should be zero".red());
        assertEq(getRewards(sue.entityId, nlf.entityId), sueCurrentReward, "Sue's reward [2] should not change".red());
        assertEq(getRewards(lou.entityId, nlf.entityId), louCurrentReward, "Lou's reward [2] should not change".red());

        c.log("(TIME: 90)".blue(), "  ~~~~~~~~~~~~~~ Distribution[3] Paid ~~~~~~~~~~~~~".yellow());
        startPrank(nlf);
        vm.warp(stakingStart + 90 days);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward3")), nlf.entityId, usdcId, rewardAmount);
        assertEq(nayms.lastPaidInterval(nlf.entityId), 3, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount * 3, "USCD balance should change");
        assertEq(
            nayms.internalBalanceOf(nayms.vTokenId(nlf.entityId, NAYM_ID, type(uint64).max), usdcId),
            rewardAmount * 3 - bobCurrentReward,
            "NLF's USDC balance should increase"
        );

        vm.warp(stakingStart + 91 days);

        {
            uint256 bobBoost = (calculateBoost(0, 90 days, R, I, SCALE_FACTOR) * bobStakeAmount) / totalStakeAmount;
            uint256 sueBoost = (calculateBoost(0, 90 days, R, I, SCALE_FACTOR) * sueStakeAmount) / totalStakeAmount;
            uint256 louBoost = (calculateBoost(20 days, 90 days, R, I, SCALE_FACTOR) * louStakeAmount) / totalStakeAmount;

            uint256 totalBoost = bobBoost + sueBoost + louBoost;

            bobCurrentReward = (rewardAmount * (bobBoost)) / totalBoost; // previosly collected the reward, so nothing to add to
            sueCurrentReward += (rewardAmount * (sueBoost)) / totalBoost;
            louCurrentReward += (rewardAmount * (louBoost)) / totalBoost;

            unclaimedReward[bob.entityId][5] = bobCurrentReward;

            assertEq(getRewards(bob.entityId, nlf.entityId), bobCurrentReward, "Bob's reward [3] should increase".red());
            assertEq(getRewards(sue.entityId, nlf.entityId), sueCurrentReward, "Sue's reward [3] should increase".red());
            assertEq(getRewards(lou.entityId, nlf.entityId), louCurrentReward, "Lou's reward [3] should increase".red());
        }

        startPrank(sue);
        nayms.collectRewards(nlf.entityId);
        c.log("(TIME: 91)".blue(), "  ~~~~~~~~~~~~~~ Sue Claimed Rewards ~~~~~~~~~~~~~".yellow());

        usdcBalance[sue.entityId] = sueCurrentReward;

        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance should increase");
        assertEq(getRewards(sue.entityId, nlf.entityId), 0, "Sue's reward [3] should be zero".red());

        assertEq(getRewards(bob.entityId, nlf.entityId), bobCurrentReward, "Bob's reward [3] should not change".red());
        assertEq(getRewards(lou.entityId, nlf.entityId), louCurrentReward, "Lou's reward [3] should not change".red());

        vm.warp(stakingStart + 92 days);

        startPrank(lou);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), louCurrentReward, "Lou's USDC balance should increase");
        assertEq(getRewards(lou.entityId, nlf.entityId), 0, "Lou's reward [3] should be zero".red());

        c.log("(TIME: 92)".blue(), "  ~~~~~~~~~~~~~~ Lou Claimed Rewards ~~~~~~~~~~~~~".yellow());

        usdcBalance[lou.entityId] = louCurrentReward; // used in extended scenario 1

        assertStakedAmount(bob.entityId, bobStakeAmount, "Incorrect Bob's original stake amount");
        assertStakedAmount(sue.entityId, sueStakeAmount, "Incorrect Sue's original stake amount");
        assertStakedAmount(lou.entityId, louStakeAmount, "Incorrect Lou's original stake amount");

        printCurrentState(nlf.entityId, nlf.entityId, "Nayms");
        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, lou.entityId, "Lou");
    }

    function test_scenario1Extended() public {
        test_StakingScenario1();

        c.log("(TIME: 121)".blue(), " ~~~~~~~~~~~~~~ S1 EXTENSION ~~~~~~~~~~~~~~");

        vm.warp(stakingStart + 121 days);

        assertEq(nayms.currentInterval(nlf.entityId), 4);
        assertEq(getRewards(bob.entityId, nlf.entityId), unclaimedReward[bob.entityId][5], "Bob's reward [3] should not change".red());
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId], "Bob's USDC balance should not change");

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        assertStakedAmount(bob.entityId, 2 * bobStakeAmount, "Bob's staked amount should increase");
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId] + unclaimedReward[bob.entityId][5], "Bob - staking should collect rewards");

        c.log("(TIME: 121)".blue(), " ~~~~~~~~~~~~~~ Bob Stakes ~~~~~~~~~~~~~~".yellow());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        assertEq(getRewards(sue.entityId, nlf.entityId), 0, "Sue's reward [3] should be zero".red());
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance should not change");

        startPrank(sue);
        nayms.stake(nlf.entityId, sueStakeAmount);
        assertStakedAmount(sue.entityId, 2 * sueStakeAmount, "Sue's staked amount should increase");
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance should not change");

        c.log("(TIME: 121)".blue(), " ~~~~~~~~~~~~~~ Sue Stakes ~~~~~~~~~~~~~~".yellow());
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        startPrank(lou);
        nayms.stake(nlf.entityId, louStakeAmount);
        assertStakedAmount(lou.entityId, 2 * louStakeAmount, "Lou's staked amount should increase");
        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), usdcBalance[lou.entityId], "Lou's USDC balance should not change");

        c.log("(TIME: 121)".blue(), " ~~~~~~~~~~~~~~ Lou Stakes ~~~~~~~~~~~~~~".yellow());
        printCurrentState(nlf.entityId, lou.entityId, "Lou");

        vm.warp(stakingStart + 151 days);
        assertEq(nayms.currentInterval(nlf.entityId), 5);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward4")), nlf.entityId, usdcId, rewardAmount);
        printCurrentState(nlf.entityId, nlf.entityId, "Nayms");
        assertEq(nayms.lastPaidInterval(nlf.entityId), 5, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount * 4, "USCD balance should change");
        c.log("(TIME: 151)".blue(), " ~~~~~~~~~~~~~~ Distribution[4] Paid ~~~~~~~~~~~~~~".yellow());

        {
            uint256 bobBoost1 = (calculateBoost(0, 150 days, R, I, SCALE_FACTOR) * bobStakeAmount) / (totalStakeAmount * 2);
            uint256 bobBoost2 = (calculateBoost(121 days, 150 days, R, I, SCALE_FACTOR) * bobStakeAmount) / (totalStakeAmount * 2);
            uint256 sueBoost1 = (calculateBoost(0, 150 days, R, I, SCALE_FACTOR) * sueStakeAmount) / (totalStakeAmount * 2);
            uint256 sueBoost2 = (calculateBoost(121 days, 150 days, R, I, SCALE_FACTOR) * sueStakeAmount) / (totalStakeAmount * 2);
            uint256 louBoost1 = (calculateBoost(20 days, 150 days, R, I, SCALE_FACTOR) * louStakeAmount) / (totalStakeAmount * 2);
            uint256 louBoost2 = (calculateBoost(121 days, 150 days, R, I, SCALE_FACTOR) * louStakeAmount) / (totalStakeAmount * 2);

            uint256 totalBoost = bobBoost1 + bobBoost2 + sueBoost1 + sueBoost2 + louBoost1 + louBoost2;

            bobCurrentReward = (rewardAmount * (bobBoost1 + bobBoost2)) / totalBoost; // previosly collected the reward, so nothing to add to
            sueCurrentReward = (rewardAmount * (sueBoost1 + sueBoost2)) / totalBoost;
            louCurrentReward = (rewardAmount * (louBoost1 + louBoost2)) / totalBoost;

            assertEq(getRewards(bob.entityId, nlf.entityId), bobCurrentReward, "Bob's reward [4] should increase".red());
            assertEq(getRewards(sue.entityId, nlf.entityId), sueCurrentReward, "Sue's reward [4] should increase".red());
            assertEq(getRewards(lou.entityId, nlf.entityId), louCurrentReward, "Lou's reward [4] should increase".red());
        }

        vm.warp(stakingStart + 181 days);
        assertEq(nayms.currentInterval(nlf.entityId), 6);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward5")), nlf.entityId, usdcId, rewardAmount);
        assertEq(nayms.lastPaidInterval(nlf.entityId), 6, "Last interval paid should increase");
        assertEq(nayms.internalBalanceOf(nlf.entityId, usdcId), usdcTotal - rewardAmount * 5, "USCD balance should change");
        c.log("(TIME: 151)".blue(), " ~~~~~~~~~~~~~~ Distribution[5] Paid ~~~~~~~~~~~~~~".yellow());

        vm.warp(stakingStart + 211 days);

        {
            uint256 bobBoost1 = (calculateBoost(0, 180 days, R, I, SCALE_FACTOR) * bobStakeAmount) / (totalStakeAmount * 2);
            uint256 bobBoost2 = (calculateBoost(121 days, 180 days, R, I, SCALE_FACTOR) * bobStakeAmount) / (totalStakeAmount * 2);
            uint256 sueBoost1 = (calculateBoost(0, 180 days, R, I, SCALE_FACTOR) * sueStakeAmount) / (totalStakeAmount * 2);
            uint256 sueBoost2 = (calculateBoost(121 days, 180 days, R, I, SCALE_FACTOR) * sueStakeAmount) / (totalStakeAmount * 2);
            uint256 louBoost1 = (calculateBoost(20 days, 180 days, R, I, SCALE_FACTOR) * louStakeAmount) / (totalStakeAmount * 2);
            uint256 louBoost2 = (calculateBoost(121 days, 180 days, R, I, SCALE_FACTOR) * louStakeAmount) / (totalStakeAmount * 2);

            uint256 totalBoost = bobBoost1 + bobBoost2 + sueBoost1 + sueBoost2 + louBoost1 + louBoost2;

            bobCurrentReward += (rewardAmount * (bobBoost1 + bobBoost2)) / totalBoost;
            sueCurrentReward += (rewardAmount * (sueBoost1 + sueBoost2)) / totalBoost;
            louCurrentReward += (rewardAmount * (louBoost1 + louBoost2)) / totalBoost;

            assertEq(getRewards(bob.entityId, nlf.entityId), bobCurrentReward, "Bob's reward [5] should increase".red());
            assertEq(getRewards(sue.entityId, nlf.entityId), sueCurrentReward - 1, "Sue's reward [5] should increase".red());
            assertEq(getRewards(lou.entityId, nlf.entityId), louCurrentReward + 1, "Lou's reward [5] should increase".red());
        }

        startPrank(bob);
        uint256 balBeforeCollecting = nayms.internalBalanceOf(bob.entityId, usdcId);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), balBeforeCollecting + bobCurrentReward, "Bob's USDC balance should increase");

        startPrank(sue);
        balBeforeCollecting = nayms.internalBalanceOf(sue.entityId, usdcId);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), balBeforeCollecting + sueCurrentReward - 1, "Sue's USDC balance should increase");

        startPrank(lou);
        balBeforeCollecting = nayms.internalBalanceOf(lou.entityId, usdcId);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), balBeforeCollecting + louCurrentReward + 1, "Lou's USDC balance should increase");
    }

    function test_simpleStakeUnstake() public {
        initStaking(I);
        vm.warp(2 * I + 10 days); // important not to stake at [0] interval!

        uint256 balanceBefore = nayms.internalBalanceOf(bob.entityId, usdcId);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);

        vm.warp(6 * I + 15 days);
        nayms.unstake(nlf.entityId);

        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), balanceBefore, "balance should be the same");
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
        assertEq(nayms.internalBalanceOf(bob.entityId, NAYM_ID), 10_000_000e18);
        assertEq(nayms.internalBalanceOf(sue.entityId, NAYM_ID), 10_000_000e18);
        assertEq(nayms.internalBalanceOf(lou.entityId, NAYM_ID), 10_000_000e18);

        assertStakedAmount(bob.entityId, 0, "Bob's staked amount should be zero".red());
        assertStakedAmount(sue.entityId, 0, "Sue's staked amount should be zero".red());
        assertStakedAmount(lou.entityId, 0, "Lou's staked amount should be zero".red());

        assertEq(getRewards(bob.entityId, nlf.entityId), 0, "Bob's reward [5] should be zero".red());
        assertEq(getRewards(sue.entityId, nlf.entityId), 0, "Sue's reward [5] should be zero".red());
        assertEq(getRewards(lou.entityId, nlf.entityId), 0, "Lou's reward [5] should be zero".red());
    }

    function test_stakeUnstakeBeforeInit() public {
        initStaking(4 * I);

        vm.warp(2 * I + 10 days);

        uint256 balanceBefore = nayms.internalBalanceOf(bob.entityId, usdcId);

        assertEq(nayms.currentInterval(nlf.entityId), 0, "should be interval zero"); // make sure staking has not started yet

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        startPrank(sue);
        nayms.stake(nlf.entityId, sueStakeAmount);
        startPrank(lou);
        nayms.stake(nlf.entityId, louStakeAmount);
        assertEq(nayms.currentInterval(nlf.entityId), 0, "should be interval zero"); // make sure staking has not started yet

        startPrank(bob);
        nayms.unstake(nlf.entityId);
        assertEq(nayms.currentInterval(nlf.entityId), 0, "should be interval zero"); // make sure staking has not started yet

        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), balanceBefore, "balance should be the same");
        assertStakedAmount(sue.entityId, sueStakeAmount, "Sue's staked amount should be the same".red());
        assertStakedAmount(lou.entityId, louStakeAmount, "Lou's staked amount should be the same".red());
    }

    function test_skipPayingAnInterval() public {
        uint256 startStaking = block.timestamp + 100 days;
        initStaking(startStaking);
        c.log(" ~ [%s] Staking start".blue(), currentInterval());

        vm.warp(startStaking + 31 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        assertStakedAmount(bob.entityId, bobStakeAmount, "Bob's stake should increase");
        c.log(" ~ [%s] Bob staked".blue(), currentInterval());

        vm.warp(startStaking + 61 days);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 0, "Last interval paid should be 0");

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1")), nlf.entityId, usdcId, rewardAmount); // 100 USDC
        c.log(" ~ [%s] Reward1 paid out".blue(), currentInterval());

        assertEq(nayms.lastPaidInterval(nlf.entityId), 2, "Last interval paid should be 2");

        vm.warp(startStaking + 151 days);
        assertEq(nayms.currentInterval(nlf.entityId), 5);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward2")), nlf.entityId, usdcId, rewardAmount); // 100 USDC
        c.log(" ~ [%s] Reward1 paid out".blue(), currentInterval());

        vm.warp(startStaking + 181 days);

        startPrank(bob);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), rewardAmount * 2);
    }

    function test_twoStakingRewardCurrencies() public {
        uint256 startStaking = block.timestamp + 100 days;
        initStaking(startStaking);

        c.log(" ~ [%s] Staking start".blue(), currentInterval());

        vm.warp(startStaking + 31 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        assertStakedAmount(bob.entityId, bobStakeAmount, "Bob's staking balance[1] should increase");
        c.log(" ~ [%s] Bob staked".blue(), currentInterval());

        vm.warp(startStaking + 61 days);

        assertEq(nayms.lastPaidInterval(nlf.entityId), 0, "Last interval paid should be 0");

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1")), nlf.entityId, usdcId, rewardAmount); // 100 USDC
        c.log(" ~ [%s] Reward paid out".blue(), currentInterval());
        assertEq(nayms.lastPaidInterval(nlf.entityId), 2, "Last interval paid should be 2");

        vm.warp(startStaking + 91 days);

        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward2")), nlf.entityId, wethId, 1 ether);
        c.log(" ~ [%s] Reward paid out".blue(), currentInterval());
        assertEq(nayms.lastPaidInterval(nlf.entityId), 3, "Last interval paid should be 3");

        vm.warp(startStaking + 121 days);

        startPrank(bob);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), rewardAmount);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 1 ether);
    }

    function test_NAY1_boostResetAfterUnstake() public {
        uint256 startStaking = block.timestamp + 100 days;
        initStaking(startStaking);

        vm.warp(startStaking + 10 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);

        assertStakedAmount(bob.entityId, bobStakeAmount, "Bob's stake should increase");
        (uint256 stakedAmount, uint256 boostedAmount) = nayms.getStakingAmounts(bob.entityId, nlf.entityId);
        assertEq(stakedAmount, boostedAmount, "Bob's boost[1] should be 1");

        vm.warp(startStaking + 40 days);

        nayms.unstake(nlf.entityId);
        assertStakedAmount(bob.entityId, 0, "Bob's stake should be zero");

        vm.warp(startStaking + 70 days);

        nayms.stake(nlf.entityId, bobStakeAmount);

        (uint256 stakedAmount2, uint256 boostedAmount2) = nayms.getStakingAmounts(bob.entityId, nlf.entityId);
        assertEq(stakedAmount2, boostedAmount2, "Bob's boost [2] should be 1");
    }
    /*
     *  [40] Bob stakes 100 NAYM => 100/100
     *  [40] Sue stakes 100 NAYM => 200/300
     *  [70] NLF pays reward1: 1000 USDC
     *  [71] Sue ustakes 100 NAYM
     */
    function test_NAY2_stakingBalanceTotalAfterUnstake() public {
        uint256 startStaking = block.timestamp + 100 days;
        initStaking(startStaking);

        vm.warp(startStaking + 40 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, bobStakeAmount);
        assertStakedAmount(bob.entityId, bobStakeAmount, "Bob's staked amount [1] should increase");
        c.log("~ [%s] Bob staked".blue(), currentInterval());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        startPrank(sue);
        nayms.stake(nlf.entityId, sueStakeAmount);
        assertStakedAmount(sue.entityId, sueStakeAmount, "Sue's staked amount [1] should increase");
        c.log("~ [%s] Sue staked".blue(), currentInterval());
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        vm.warp(startStaking + 70 days);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1")), nlf.entityId, usdcId, rewardAmount);
        c.log("~ [%s] Reward1 paid out: 100 USDC".blue(), currentInterval());

        vm.warp(startStaking + 71 days);

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        uint256 totalStakedAmount = bobStakeAmount + sueStakeAmount;

        uint256 bobBoost = (calculateBoost(40 days, 71 days, R, I, SCALE_FACTOR) * bobStakeAmount) / totalStakedAmount;
        uint256 sueBoost = (calculateBoost(40 days, 71 days, R, I, SCALE_FACTOR) * sueStakeAmount) / totalStakedAmount;
        uint256 totalBoost = bobBoost + sueBoost;

        bobCurrentReward = (rewardAmount * bobBoost) / totalBoost;
        sueCurrentReward = (rewardAmount * sueBoost) / totalBoost;

        assertEq(getRewards(bob.entityId, nlf.entityId), bobCurrentReward, "Bob's reward [2] should increase");
        assertEq(getRewards(sue.entityId, nlf.entityId), sueCurrentReward, "Sue's reward [2] should increase");

        startPrank(sue);
        nayms.unstake(nlf.entityId);
        c.log("~ [%s] Sue unstaked".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        assertEq(stakeBalance(sue.entityId, nlf.entityId, 1), 0, "Sue's balance[2] should be 0");
        assertEq(getRewards(sue.entityId, nlf.entityId), 0, "Sue's reward[2] should have been claimed and be zero now");

        assertEq(getRewards(bob.entityId, nlf.entityId), bobCurrentReward + 1, "Bob's reward[2] should not change after Sue unstakes"); // +1 is rounding imprecision
    }

    function test_NAY3_nlfItselfCantStake() public {
        startPrank(nlf);
        naymToken.mint(nlf.addr, 10_000_000e18);
        naymToken.approve(address(nayms), 10_000_000e18);
        nayms.externalDeposit(address(naymToken), 10_000_000e18);

        vm.expectRevert(abi.encodeWithSelector(InvalidStaker.selector, nlf.entityId));

        nayms.stake(nlf.entityId, 10 ether);
    }

    /*
     *  [40] Bob stakes 100 NAYM => 100/100
     *  [70] NLF pays reward1: 1000 USDC
     *  [70] Bob collects (collects: 100% reward1)
     *  [70] Sue stakes 100 NAYM => 100/200
     * [100] NLF pays reward2: 1000 USDC
     * [130] Bob unstakes (collects: 50% reward2)
     * [160] NLF pays reward3: 1000 USDC
     * [160] Sue collects (collects: 50% reward2 + 100% reward3)
     */
    function test_twoStakersAndRewards_BoostOverflow() public {
        uint256 stake100 = 100e18;
        uint256 reward1000usdc = 1_000_000000;

        uint256 startStaking = block.timestamp + 100 days;
        initStaking(startStaking);

        vm.warp(startStaking + 40 days);
        c.log("\n  ~ START Staking\n".blue());

        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), 0);
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), 0);

        startPrank(bob);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(bob.entityId, stake100, "Bob's staked amount [1] should increase");
        c.log("~ [%s] Bob staked 100 NAYM".blue(), currentInterval());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        vm.warp(startStaking + 70 days);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1")), nlf.entityId, usdcId, reward1000usdc);
        assertEq(getRewards(bob.entityId, nlf.entityId), reward1000usdc, "Bob's reward [2] should increase");
        c.log("~ [%s] NLF payed out 1000 USDC reward1".blue(), currentInterval());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        startPrank(bob);
        nayms.collectRewards(nlf.entityId);
        usdcBalance[bob.entityId] += reward1000usdc;
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId]);
        c.log("~ [%s] Bob collected reward1".blue(), currentInterval());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        startPrank(sue);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(sue.entityId, stake100, "Sue's staked amount [2] should increase");
        c.log("~ [%s] Sue staked 100 NAYM".blue(), currentInterval());
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        vm.warp(startStaking + 100 days);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward2")), nlf.entityId, usdcId, reward1000usdc);
        c.log("~ [%s] NLF payed out 1000 USDC reward2".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        uint256 totalStakedAmount = 2 * stake100;
        {
            uint256 bobBoost = (calculateBoost(40 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 sueBoost = (calculateBoost(70 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 totalBoost = bobBoost + sueBoost;

            uint256 bobReward = (reward1000usdc * bobBoost) / totalBoost;
            uint256 sueReward = (reward1000usdc * sueBoost) / totalBoost;

            unclaimedReward[bob.entityId][2] = bobReward;
            usdcBalance[bob.entityId] += bobReward;

            assertEq(getRewards(bob.entityId, nlf.entityId), bobReward, "Bob's reward [3] should increase");
            assertEq(getRewards(sue.entityId, nlf.entityId), sueReward, "Sue's reward [3] should increase");
        }

        vm.warp(startStaking + 130 days);

        startPrank(bob);
        nayms.unstake(nlf.entityId);
        assertStakedAmount(bob.entityId, 0, "Bob's staked amount [4] should be zero");
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId], "Bob's USDC balance[4] should increase");
        c.log("~ [%s] Bob unstaked 100 NAYM".blue(), currentInterval());

        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        vm.warp(startStaking + 160 days);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward3")), nlf.entityId, usdcId, reward1000usdc);
        c.log("~ [%s] NLF payed out 1000 USDC reward3".blue(), currentInterval());

        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        c.log("  Sue last collected: %s".green(), nayms.lastCollectedInterval(nlf.entityId, sue.entityId));

        {
            uint256 bobBoost1R2 = (calculateBoost(40 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 sueBoost1R2 = (calculateBoost(70 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 totalBoostR2 = bobBoost1R2 + sueBoost1R2;

            uint256 sueReward = ((reward1000usdc * sueBoost1R2) / totalBoostR2) + reward1000usdc;

            unclaimedReward[sue.entityId][5] = sueReward;
            usdcBalance[sue.entityId] += sueReward;

            assertEq(getRewards(sue.entityId, nlf.entityId), sueReward, "Sue's reward [5] should increase");
        }

        c.log("~ [%s] Sue collects rewards".blue(), currentInterval());
        startPrank(sue);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance [5] should increase");
    }

    /**
     *  [40] Bob stakes 100 NAYM => 100/100
     *  [40] Sue stakes 100 NAYM => 100/200
     *  [70] NLF pays reward1: 1000 USDC           (Bob: 100, Sue: 100, Total: 200)
     *  [70] Sue stakes 100 NAYM => 100/300 (collects: 50% reward1)
     *  [70] Lou stakes 100 NAYM => 100/400
     *  [70] Bob unstakes (collects 50% reward1)
     * [100] NLF pays reward2: 1000 USDC           (Sue: 200, Lou: 100, Total: 300)
     * [100] Sue collects (collects: 66% reward2)
     * [130] Bob stakes 100 NAYM => 100/400
     * [130] Sue stakes 100 NAYM => 300/500
     * [160] NLF pays reward3: 1000 USDC           (Bob: 100, Sue: 300, Lou: 100, Total: 500)
     * [160] Bob unstakes (collects ~20% reward3)
     * [160] Sue unstakes (collects ~60% reward3)
     * [160] Lou unstakes (collects: ~33% reward2, 20% reward3)
     */
    function test_threeStakersAndRewardsIntertwine() public {
        uint256 stake100 = 100e18;
        uint256 reward1000usdc = 1_000_000000;

        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId], "Bob's USDC balance should be zero");
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance should be zero");
        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), usdcBalance[lou.entityId], "Lou's USDC balance should be zero");

        assertStakedAmount(bob.entityId, 0, "Bob's staked amount [1] should be zero");
        assertStakedAmount(sue.entityId, 0, "Sue's staked amount [1] should be zero");
        assertStakedAmount(lou.entityId, 0, "Lou's staked amount [1] should be zero");

        uint256 startStaking = block.timestamp + 100 days;
        initStaking(startStaking);

        vm.warp(startStaking + 40 days);
        c.log("\n  ~ START Staking\n".blue());

        startPrank(bob);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(bob.entityId, stake100, "Bob's staked amount [1] should increase");

        c.log("~ [%s] Bob staked 100 NAYM".blue(), currentInterval());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        assertStakedAmount(sue.entityId, 0, "Sue's staked amount [1] should be zero");

        startPrank(sue);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(sue.entityId, stake100, "Sue's staked amount [1] should increase");

        c.log("~ [%s] Sue staked 100 NAYM".blue(), currentInterval());
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        vm.warp(startStaking + 70 days);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1")), nlf.entityId, usdcId, reward1000usdc);
        c.log("~ [%s] NLF payed out reward1: 1000 USDC".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        startPrank(sue);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(sue.entityId, stake100 * 2, "Sue's staked amount [2] should increase");
        usdcBalance[sue.entityId] += reward1000usdc / 2;
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance should increase");
        c.log("~ [%s] Sue staked 100 NAYM (collects 50% reward1)".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        c.log("     Sue's USDC balance: %s".green(), nayms.internalBalanceOf(sue.entityId, usdcId) / 1e6);

        assertStakedAmount(lou.entityId, 0, "Sue's staked amount [2] should be zero");

        startPrank(lou);
        nayms.stake(nlf.entityId, stake100);
        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), 0);
        assertStakedAmount(lou.entityId, stake100, "Lou's staked amount [2] should increase");
        c.log("~ [%s] Lou staked 100 NAYM".blue(), currentInterval());

        printCurrentState(nlf.entityId, lou.entityId, "Lou");
        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        startPrank(bob);
        nayms.unstake(nlf.entityId);
        usdcBalance[bob.entityId] += reward1000usdc / 2;
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId], "Bob's USDC balance [2] should increase");
        assertStakedAmount(bob.entityId, 0, "Bob's staked amount [2] should be zero");
        c.log("~ [%s] Bob unstaked (collects 50% reward1)".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        c.log("     Bob's USDC balance: %s".green(), nayms.internalBalanceOf(bob.entityId, usdcId) / 1e6);

        printCurrentState(nlf.entityId, lou.entityId, "Lou");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        vm.warp(startStaking + 100 days);
        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward2")), nlf.entityId, usdcId, reward1000usdc);
        c.log("~ [%s] NLF payed out reward2: 1000 USDC".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, lou.entityId, "Lou");

        {
            uint256 totalStakedAmount = 3 * stake100;

            uint256 sueBoost1 = (calculateBoost(40 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 sueBoost2 = (calculateBoost(70 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 louBoost1 = (calculateBoost(70 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 totalBoost = sueBoost1 + sueBoost2 + louBoost1;

            uint256 sueReward = (reward1000usdc * (sueBoost1 + sueBoost2)) / totalBoost;
            uint256 louRewardR2 = (reward1000usdc * louBoost1) / totalBoost;

            unclaimedReward[lou.entityId][2] = louRewardR2;

            assertEq(getRewards(sue.entityId, nlf.entityId), sueReward, "Sue's reward [3] should increase");
            assertEq(getRewards(lou.entityId, nlf.entityId), louRewardR2, "Lou's reward [3] should increase");

            usdcBalance[sue.entityId] += sueReward;
        }

        startPrank(sue);
        nayms.collectRewards(nlf.entityId);
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance [3] should increase");
        c.log("~ [%s] Sue collects rewards (collects: 66% reward2)".blue(), currentInterval());

        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        c.log("     Sue's USDC balance: %s".green(), nayms.internalBalanceOf(sue.entityId, usdcId) / 1e6);

        vm.warp(startStaking + 130 days);

        startPrank(bob);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(bob.entityId, stake100, "Bob's staked amount [3] should increase");
        c.log("~ [%s] Bob staked 100 NAYM".blue(), currentInterval());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        startPrank(sue);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(sue.entityId, 3 * stake100, "Sue's staked amount [3] should increase");
        c.log("~ [%s] Sue staked 100 NAYM".blue(), currentInterval());
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        vm.warp(startStaking + 160 days);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward3")), nlf.entityId, usdcId, reward1000usdc);
        c.log("~ [%s] NLF payed out reward3: 1000 USDC".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, lou.entityId, "Lou");

        {
            uint256 totalStakedAmount = 5 * stake100;

            uint256 sueBoost1R3 = (calculateBoost(40 days, 160 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 sueBoost2R3 = (calculateBoost(70 days, 160 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 sueBoost3R3 = (calculateBoost(130 days, 160 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 louBoost1R3 = (calculateBoost(70 days, 160 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 bobBoost1R3 = (calculateBoost(130 days, 160 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;

            uint256 totalBoostR3 = sueBoost1R3 + sueBoost2R3 + sueBoost3R3 + louBoost1R3 + bobBoost1R3;

            uint256 sueReward = (reward1000usdc * (sueBoost1R3 + sueBoost2R3 + sueBoost3R3)) / totalBoostR3;
            uint256 bobReward = (reward1000usdc * bobBoost1R3) / totalBoostR3;

            uint256 louReward = unclaimedReward[lou.entityId][2] + (reward1000usdc * louBoost1R3) / totalBoostR3;

            // consider rounding error
            assertEq(getRewards(bob.entityId, nlf.entityId), bobReward + 4, "Bob's reward [3] should increase");
            assertEq(getRewards(sue.entityId, nlf.entityId), sueReward - 11, "Sue's reward [3] should increase");
            assertEq(getRewards(lou.entityId, nlf.entityId), louReward + 7, "Lou's reward [3] should increase");

            usdcBalance[bob.entityId] += bobReward;
            usdcBalance[sue.entityId] += sueReward;
            usdcBalance[lou.entityId] += louReward;
        }

        vm.warp(startStaking + 190 days);

        startPrank(bob);
        nayms.unstake(nlf.entityId);
        c.log("~ [%s] Bob unstaked".blue(), currentInterval());
        c.log("      Bob's USDC balance: %s".green(), nayms.internalBalanceOf(bob.entityId, usdcId) / 1e6);

        startPrank(sue);
        nayms.unstake(nlf.entityId);
        c.log("~ [%s] Sue unstaked".blue(), currentInterval());
        c.log("      Sue's USDC balance: %s".green(), nayms.internalBalanceOf(sue.entityId, usdcId) / 1e6);

        startPrank(lou);
        nayms.unstake(nlf.entityId);
        c.log("~ [%s] Lou unstaked".blue(), currentInterval());
        c.log("      Lou's USDC balance: %s".green(), nayms.internalBalanceOf(lou.entityId, usdcId) / 1e6);

        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId] + 4, "Bob's USDC balance [6] should increase");
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId] - 11, "Sue's USDC balance [6] should increase");
        assertEq(nayms.internalBalanceOf(lou.entityId, usdcId), usdcBalance[lou.entityId] + 7, "Lou's USDC balance [6] should increase");

        assertEq(usdcBalance[bob.entityId] + usdcBalance[sue.entityId] + usdcBalance[lou.entityId], (3 * reward1000usdc) - 2, "All rewards should have been distributed");

        // printAppstorage();
    }

    /**
     *   [40] Bob stakes 100 NAYM => 100/100
     *   [40] Sue stakes 100 NAYM => 100/200
     *   [70] NLF pays reward1: 1000 USDC           (Bob: 100, Sue: 100, Total: 200)
     *  [100] Sue stakes 100 NAYM => 100/300        (collects: 50% reward1)
     *  [100] Bob stakes 100 NAYM => 100/400        (collects: 50% reward1)
     *  [100] NLF pays reward2: 1000 USDC           (Bob: 200, Sue: 200, Total: 400)
     *  [130] Sue collect
     *  [160] Bob unstake
     *  [160] NLF pays reward3: 1000 USDC
     */
    function test_stakeAndPayRewardAtSameIntervalThenUnstake() public {
        uint256 stake100 = 100e18;
        uint256 reward1000usdc = 1_000_000000;

        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId], "Bob's USDC balance should be zero");
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance should be zero");

        assertStakedAmount(bob.entityId, 0, "Bob's staked amount [1] should be zero");
        assertStakedAmount(sue.entityId, 0, "Sue's staked amount [1] should be zero");

        uint256 startStaking = block.timestamp + 100 days;
        initStaking(startStaking);

        vm.warp(startStaking + 40 days);
        c.log("\n  ~ START Staking\n".blue());

        startPrank(bob);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(bob.entityId, stake100, "Bob's staked amount [1] should increase");
        c.log("~ [%s] Bob staked 100 NAYM".blue(), currentInterval());
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        startPrank(sue);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(sue.entityId, stake100, "Sue's staked amount [1] should increase");
        c.log("~ [%s] Sue staked 100 NAYM".blue(), currentInterval());
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        vm.warp(startStaking + 70 days);

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward1")), nlf.entityId, usdcId, reward1000usdc);
        c.log("~ [%s] NLF payed out reward1: 1000 USDC".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        vm.warp(startStaking + 100 days);

        startPrank(sue);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(sue.entityId, stake100 * 2, "Sue's staked amount [2] should increase");
        usdcBalance[sue.entityId] += reward1000usdc / 2;
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance should increase");
        c.log("~ [%s] Sue staked 100 NAYM (collects 50% reward1)".blue(), currentInterval());

        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        c.log("     Sue's USDC: %s".green(), nayms.internalBalanceOf(sue.entityId, usdcId) / 1e6);
        printCurrentState(nlf.entityId, bob.entityId, "Bob");

        startPrank(bob);
        nayms.stake(nlf.entityId, stake100);
        assertStakedAmount(bob.entityId, 2 * stake100, "Bob's staked amount [2] should increase");
        usdcBalance[bob.entityId] += reward1000usdc / 2;
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId], "Bob's USDC balance should increase");
        c.log("~ [%s] Bob staked 100 NAYM (collects 50% reward1)".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        c.log("     Bob's USDC: %s".green(), nayms.internalBalanceOf(bob.entityId, usdcId) / 1e6);
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward2")), nlf.entityId, usdcId, reward1000usdc);
        c.log("~ [%s] NLF payed out reward2: 1000 USDC".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");

        {
            uint256 totalStakedAmount = 2 * stake100;

            uint256 sueBoost = (calculateBoost(40 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 bobBoost = (calculateBoost(40 days, 100 days, R, I, SCALE_FACTOR) * stake100) / totalStakedAmount;
            uint256 totalBoost = sueBoost + bobBoost;

            uint256 sueReward = (reward1000usdc * sueBoost) / totalBoost;
            uint256 bobReward = (reward1000usdc * bobBoost) / totalBoost;

            unclaimedReward[bob.entityId][3] = bobReward;
            unclaimedReward[sue.entityId][3] = sueReward;

            assertEq(getRewards(bob.entityId, nlf.entityId), bobReward, "Bob's reward [3] should increase");
            assertEq(getRewards(sue.entityId, nlf.entityId), sueReward, "Sue's reward [3] should increase");
        }

        vm.warp(startStaking + 130 days);

        startPrank(sue);
        nayms.collectRewards(nlf.entityId);
        usdcBalance[sue.entityId] += unclaimedReward[sue.entityId][3];
        assertEq(nayms.internalBalanceOf(sue.entityId, usdcId), usdcBalance[sue.entityId], "Sue's USDC balance should increase");
        c.log("~ [%s] Sue collects 50% reward2".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, nlf.entityId, "NLF");

        vm.warp(startStaking + 160 days);

        startPrank(bob);
        nayms.unstake(nlf.entityId);
        usdcBalance[bob.entityId] += unclaimedReward[bob.entityId][3];
        assertEq(nayms.internalBalanceOf(bob.entityId, usdcId), usdcBalance[bob.entityId], "Bob's USDC balance should increase");
        c.log("~ [%s] Bob unstaked (collects 50% reward2)".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, nlf.entityId, "NLF");

        startPrank(nlf);
        nayms.payReward(makeId(LC.OBJECT_TYPE_STAKING_REWARD, bytes20("reward3")), nlf.entityId, usdcId, reward1000usdc);
        c.log("~ [%s] NLF payed out reward3: 1000 USDC".blue(), currentInterval());

        printCurrentState(nlf.entityId, bob.entityId, "Bob");
        printCurrentState(nlf.entityId, sue.entityId, "Sue");
        printCurrentState(nlf.entityId, nlf.entityId, "NLF");

        assertEq(getRewards(sue.entityId, nlf.entityId), reward1000usdc, "Sue should get the entire reward3".red());
        c.log(" Sue's rewards: %s".green(), getRewards(sue.entityId, nlf.entityId) / 1e6);

        // printAppstorage();
    }

    function printAppstorage() public {
        uint64 interval = currentInterval() + 2;

        c.log();
        c.log(" -------- apstorage [%s] --------", currentInterval());
        c.log();

        c.log("  --   Bob  --");
        for (uint64 i = 0; i <= interval; i++) {
            logStateAt(i, bob.entityId, nlf.entityId);
        }
        c.log();

        c.log("  --   Sue  --");
        for (uint64 i = 0; i <= interval; i++) {
            logStateAt(i, sue.entityId, nlf.entityId);
        }
        c.log();

        // c.log("  --   Lou  --");
        // for (uint64 i = 0; i <= interval; i++) {
        //     logStateAt(i, lou.entityId, nlf.entityId);
        // }
        // c.log();

        c.log("  --   NLF  --");
        for (uint64 i = 0; i <= interval; i++) {
            logStateAt(i, nlf.entityId, nlf.entityId);
        }
        c.log();
        c.log(" -------------------------------");
        c.log();
    }

    function logStateAt(uint64 interval, bytes32 staker, bytes32 entityId) private {
        c.log("  [%s] balance: %s, boost: %s", interval, stakeBalance(staker, entityId, interval), stakeBoost(staker, entityId, interval));
    }
}
