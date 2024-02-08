// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { StdStorage, stdStorage, StdStyle } from "forge-std/Test.sol";
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

contract StakingTest is D03ProtocolDefaults {
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
        bytes memory vTokenBytes = abi.encodePacked(bytes4(LC.OBJECT_TYPE_STAKED), _interval, _tokenId << 96);
        return bytes32(vTokenBytes);
    }

    function test_vtokenId() public {
        bytes20 entityId = bytes20(keccak256(bytes("test")));
        c.log(vm.toString(entityId));

        bytes32 tokenId = makeId2(LC.OBJECT_TYPE_ENTITY, entityId);
        uint64 interval = 1;
        bytes32 vId = vtokenId(tokenId, interval);

        c.logBytes32(vId);
        c.logBytes32(vId << 32);
        c.logBytes32(vId << 96);
        c.log(vm.toString(entityId));

        uint64 intervalExtracted = uint64(bytes8((vId << 32)));
        c.log(vm.toString(intervalExtracted));

        assertEq(bytes4(vId), LC.OBJECT_TYPE_STAKED);
        assertEq(intervalExtracted, interval);

        bytes20 entityIdExtracted = bytes20(vId << 96);
        assertEq(entityIdExtracted, entityId);
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
        vm.warp(1);
        nayms.updateStakingParamsWithDefaults(NAYMSID);
        nayms.initStaking(NAYMSID);

        c.log("Bob's balance:".green(), nayms.internalBalanceOf(bob.id, NAYMSID));
        nayms.stake(NAYMSID, 1 ether);
    }

    /// @dev Add consecutive boosts.
    // function addBoosts(bytes32 tokenId, bytes32 ownerId, uint64 startingInterval) internal view returns (uint256 totalBoost) {
    //     totalBoost = nayms.stakeBoost(tokenId, ownerId, startingInterval) + nayms.stakeBoost(tokenId, ownerId, startingInterval + 1);
    // }

    // function printBoosts(bytes32 tokenId, bytes32 ownerId) internal view {
    //     c.log("~~~ Boosts ~~~".blue().bold());
    //     c.log(string.concat("   Current Timestamp: ", vm.toString(block.timestamp / 1 days), " days"));
    //     if (nayms.stakeConfigs(tokenId).initDate != 0) {
    //         c.log(string.concat("  Days Since Staking: ", vm.toString((block.timestamp - nayms.stakeConfigs(tokenId).initDate) / 1 days), " days"));
    //     }
    //     // todo fix the token id
    //     c.log("         Total Staked", nayms.internalTokenSupply(VTOKENID0));
    //     c.log("     Current Interval", nayms.currentInterval(tokenId));
    //     c.log("  Boost at Interval 1", nayms.stakeBoost(tokenId, ownerId, nayms.currentInterval(tokenId) + 1));
    //     c.log("  Boost at Interval 2", nayms.stakeBoost(tokenId, ownerId, nayms.currentInterval(tokenId) + 2));
    //     // c.log("          Boost Total", addBoosts(tokenId, ownerId, nayms.currentInterval(tokenId) + 1));
    // }

    function calculateBoost(uint256 amountStaked) internal view returns (uint256 boost) {
        boost = (nayms.stakeConfigs(NAYMSID).a * amountStaked) / nayms.stakeConfigs(NAYMSID).divider;
    }

    // function test_StakeBeforeInitStaking() public {
    //     vm.warp(1);
    //     nayms.updateStakingParamsWithDefaults(NAYMSID);
    //     startPrank(bob);
    //     nayms.stake(NAYMSID, 100);
    //     printBoosts(NAYMSID, NAYMSID);
    //     assertEq(nayms.internalBalanceOf(bob.entityId, VTOKENID0), 100);
    //     assertEq(nayms.internalTokenSupply(VTOKENID0), 100);
    //     // Check boosts for bob
    //     assertEq(addBoosts(NAYMSID, bob.entityId, 1), calculateBoost(100));
    //     // Check overall total boosts for NAYMSID
    //     assertEq(addBoosts(NAYMSID, NAYMSID, 1), calculateBoost(100));
    //     vm.warp(10 days);
    //     startPrank(sue);
    //     nayms.stake(NAYMSID, 200);
    //     printBoosts(NAYMSID, NAYMSID);
    //     assertEq(nayms.internalBalanceOf(sue.entityId, VTOKENID0), 200);
    //     assertEq(nayms.internalTokenSupply(VTOKENID0), 100 + 200);
    //     // Check boosts for sue
    //     assertEq(addBoosts(NAYMSID, sue.entityId, 1), calculateBoost(200));
    //     // Check overall total boosts for NAYMSID
    //     assertEq(addBoosts(NAYMSID, NAYMSID, 1), calculateBoost(300)); // note total staked
    //     vm.warp(20 days);
    //     // todo set permissions for initStaking
    //     nayms.initStaking(NAYMSID);
    //     c.log(" ~~ Staking has STARTED".blue());
    //     vm.warp(40 days);
    //     startPrank(lou);
    //     nayms.stake(NAYMSID, 400);
    //     printBoosts(NAYMSID, NAYMSID);
    //     assertEq(nayms.internalBalanceOf(lou.entityId, VTOKENID0), 400);
    //     assertEq(nayms.internalTokenSupply(VTOKENID0), 100 + 200 + 400);
    //     assertEq(nayms.stakeBoost(NAYMSID, lou.entityId, 1), 20);
    //     assertEq(nayms.stakeBoost(NAYMSID, lou.entityId, 2), 40);
    //     assertEq(addBoosts(NAYMSID, lou.entityId, 1), calculateBoost(400));
    //     // Check overall total boosts for NAYMSID
    //     assertEq(nayms.stakeBoost(NAYMSID, NAYMSID, 1), 65);
    //     assertEq(nayms.stakeBoost(NAYMSID, NAYMSID, 2), 40);
    //     assertEq(addBoosts(NAYMSID, NAYMSID, 1), calculateBoost(700)); // note total staked
    //     vm.warp(50 days);
    //     startPrank(sm);
    //     assertEq(nayms.lastIntervalPaid(NAYMSID), 0);
    //     (uint256 owedBoost, uint256 currentBoost) = nayms.overallOwedBoost(NAYMSID, nayms.currentInterval(NAYMSID));
    //     c.log("overallOwedBoost", owedBoost);
    //     c.log("overallCurrentBoost", currentBoost);
    //     // todo the IDs of distributions should have a different ID prefix. Currently it's the same as dividends
    //     nayms.payDistribution(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")), NAYMSID, usdcId, 100e6);
    //     c.log(" ~~ 1st Dist Paid".blue());
    //     printBoosts(NAYMSID, NAYMSID);
    //     assertEq(nayms.lastIntervalPaid(NAYMSID), 1);
    //     c.log("total token supply of NAYMSID", nayms.internalTokenSupply(NAYMSID));
    //     c.log("total token supply of VTOKENID0", nayms.internalTokenSupply(VTOKENID0));
    //     c.log("total token supply of VTOKENID1", nayms.internalTokenSupply(VTOKENID1));
    //     // vm.warp(80 days);
    //     // nayms.payDistribution(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x2")), NAYMSID, usdcId, 100e6);
    //     // nayms.currentOwedBoost(NAYMSID, bob.entityId);
    // }
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
