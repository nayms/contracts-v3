// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, SimplePolicy, Stakeholders, MarketInfo, FeeReceiver, FeeAllocation, CalculatedFees } from "../src/diamonds/nayms/AppStorage.sol";

// import { DSILib } from "./utils/DSILib.sol";

// todo test when the CR is changed for an entity

import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { AppStorage, LibAppStorage } from "src/diamonds/nayms/AppStorage.sol";

// contract Getters {
//     function getFirstLockedAmount(bytes32 id, bytes32 tokenId) public view returns (uint256) {
//         AppStorage storage s = LibAppStorage.diamondStorage();
//         FirstSaleAmount lockedFirstBalance = s.lockedFirstBalances[id][tokenId];

//         return abi.decode(abi.encodePacked(lockedFirstBalance), (uint256));
//     }
// }

contract NewFeesTest is D03ProtocolDefaults {
    using stdStorage for StdStorage;
    // using DSILib for address;
    Entity entityInfo;

    NaymsAccount acc1 = makeNaymsAcc("acc1");
    NaymsAccount acc2 = makeNaymsAcc("acc2");

    function setUp() public virtual override {
        super.setUp();

        entityInfo = Entity({ assetId: wethId, collateralRatio: LibConstants.BP_FACTOR, maxCapacity: 1 ether, utilizedCapacity: 0, simplePolicyEnabled: true });

        // IDiamondCut.FacetCut[] memory _cut = new IDiamondCut.FacetCut[](1);
        // bytes4[] memory selectors = new bytes4[](1);
        // selectors[0] = Getters.getFirstLockedAmount.selector;
        // _cut[0] = IDiamondCut.FacetCut({ facetAddress: address(new Getters()), action: IDiamondCut.FacetCutAction.Add, functionSelectors: selectors });
        // scheduleAndUpgradeDiamond(_cut);

        changePrank(systemAdmin);
        nayms.createEntity(acc1.entityId, acc1.id, entityInfo, "entity test hash");
        nayms.createEntity(acc2.entityId, acc2.id, entityInfo, "entity test hash");
        nayms.enableEntityTokenization(acc1.entityId, "ESPT", "Entity Selling Par Tokens");
    }

    function test_setFeeSchedule_OnlySystemAdmin() public {
        changePrank(address(0xdead));
        FeeReceiver[] memory feeReceivers = new FeeReceiver[](1);
        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        vm.expectRevert("not a system admin");
        nayms.addFeeSchedule(LibConstants.PREMIUM_FEE_SCHEDULE_DEFAULT, feeReceivers);
    }

    function test_removeFeeSchedule() public {
        FeeReceiver[] memory feeReceivers = nayms.getFeeSchedule(LibConstants.PREMIUM_FEE_SCHEDULE_DEFAULT);

        feeReceivers = new FeeReceiver[](0);
        nayms.addFeeSchedule(LibConstants.PREMIUM_FEE_SCHEDULE_DEFAULT, feeReceivers);

        assertEq(nayms.getFeeSchedule(LibConstants.PREMIUM_FEE_SCHEDULE_DEFAULT).length, 0, "fee receivers length should be 0");
    }

    function test_getPremiumCommissionScheduleID_Default() public {
        bytes32 entityWithDefault = keccak256("entity with default");
        uint256 feeScheduleId = nayms.getPremiumFeeScheduleId(entityWithDefault);

        assertEq(feeScheduleId, LibConstants.PREMIUM_FEE_SCHEDULE_DEFAULT, "default premium fee schedule id is incorrect");
    }

    function test_getPremiumCommissionScheduleID_Custom() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        uint256 feeScheduleId = nayms.getPremiumFeeScheduleId(entityWithCustom);

        // Should be default before setting a custom fee schedule
        assertEq(feeScheduleId, LibConstants.PREMIUM_FEE_SCHEDULE_DEFAULT, "default premium fee schedule id is incorrect");

        FeeReceiver[] memory feeReceivers = new FeeReceiver[](1);
        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        nayms.addFeeSchedule(uint256(entityWithCustom), feeReceivers);

        feeScheduleId = nayms.getPremiumFeeScheduleId(entityWithCustom);
        assertEq(feeScheduleId, uint256(entityWithCustom), "custom premium fee schedule id is incorrect");
    }

    function test_getTradingCommissionScheduleID_Default() public {
        bytes32 entityWithDefault = keccak256("entity with default");
        uint256 feeScheduleId = nayms.getTradingFeeScheduleId(entityWithDefault);

        assertEq(feeScheduleId, LibConstants.MARKET_FEE_SCHEDULE_DEFAULT, "default market fee schedule id is incorrect");
    }

    function test_getTradingCommissionScheduleID_Custom() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        uint256 feeScheduleId = nayms.getTradingFeeScheduleId(entityWithCustom);

        // Should be default before setting a custom fee schedule
        assertEq(feeScheduleId, LibConstants.MARKET_FEE_SCHEDULE_DEFAULT, "default market fee schedule id is incorrect");

        FeeReceiver[] memory feeReceivers = new FeeReceiver[](1);
        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        nayms.addFeeSchedule(uint256(entityWithCustom) - LibConstants.STORAGE_OFFSET_FOR_CUSTOM_MARKET_FEES, feeReceivers);

        feeScheduleId = nayms.getTradingFeeScheduleId(entityWithCustom);
        assertEq(feeScheduleId, uint256(entityWithCustom) - LibConstants.STORAGE_OFFSET_FOR_CUSTOM_MARKET_FEES, "custom market fee schedule id is incorrect");
    }

    function test_calculateTradingFees_SingleReceiver() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        uint256 feeScheduleId = nayms.getTradingFeeScheduleId(entityWithCustom);

        FeeReceiver[] memory feeReceivers = new FeeReceiver[](1);
        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        nayms.addFeeSchedule(uint256(entityWithCustom) - LibConstants.STORAGE_OFFSET_FOR_CUSTOM_MARKET_FEES, feeReceivers);

        uint256 _buyAmount = 1e18;
        CalculatedFees memory cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        uint256 expectedValue = (_buyAmount * feeReceivers[0].basisPoints) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, feeReceivers[0].basisPoints, "total bp is incorrect");
    }

    function test_calculateTradingFees_MultipleReceivers() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        uint256 startingFeeScheduleId = nayms.getTradingFeeScheduleId(entityWithCustom);

        FeeReceiver[] memory feeReceivers = new FeeReceiver[](3);

        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 150 });
        feeReceivers[1] = FeeReceiver({ receiver: NDF_IDENTIFIER, basisPoints: 75 });
        feeReceivers[2] = FeeReceiver({ receiver: STM_IDENTIFIER, basisPoints: 75 });

        nayms.addFeeSchedule(uint256(entityWithCustom) - LibConstants.STORAGE_OFFSET_FOR_CUSTOM_MARKET_FEES, feeReceivers);

        uint256 currentFeeScheduleId = nayms.getTradingFeeScheduleId(entityWithCustom);

        assertGt(currentFeeScheduleId, startingFeeScheduleId, "custom fee schedule ID should be greater than default fee schedule ID");

        uint256 _buyAmount = 1e18;
        CalculatedFees memory cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        uint256 expectedValue = (_buyAmount * (feeReceivers[0].basisPoints + feeReceivers[1].basisPoints + feeReceivers[2].basisPoints)) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, (feeReceivers[0].basisPoints + feeReceivers[1].basisPoints + feeReceivers[2].basisPoints), "total bp is incorrect");

        // Update the same fee schedule: 3 receivers to 1 receiver
        feeReceivers = new FeeReceiver[](1);
        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        nayms.addFeeSchedule(uint256(entityWithCustom) - LibConstants.STORAGE_OFFSET_FOR_CUSTOM_MARKET_FEES, feeReceivers);
        cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        expectedValue = (_buyAmount * feeReceivers[0].basisPoints) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, feeReceivers[0].basisPoints, "total bp is incorrect");

        // Clear out custom fee schedule
        feeReceivers = new FeeReceiver[](0);
        nayms.addFeeSchedule(uint256(entityWithCustom) - LibConstants.STORAGE_OFFSET_FOR_CUSTOM_MARKET_FEES, feeReceivers);

        // Should be back to default market fee schedule
        cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        uint256 totalBP;
        for (uint256 i; i < nayms.getFeeSchedule(LibConstants.MARKET_FEE_SCHEDULE_DEFAULT).length; ++i) {
            totalBP += nayms.getFeeSchedule(LibConstants.MARKET_FEE_SCHEDULE_DEFAULT)[i].basisPoints;
        }

        expectedValue = (_buyAmount * totalBP) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, totalBP, "total bp is incorrect");
    }

    // function test_calculateTrade() public {
    //     CalculatedFees memory cf = nayms.calculateTrade(acc1.entityId, wethId, 1 ether, LibConstants.MARKET_FEE_SCHEDULE_INITIAL_OFFER);

    //     nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

    //     nayms.calculateTrade(acc1.entityId, wethId, 1 ether, LibConstants.MARKET_FEE_SCHEDULE_INITIAL_OFFER);
    // }
    function test_calculatePremiumFees_SingleReceiver() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        uint256 feeScheduleId = nayms.getPremiumFeeScheduleId(entityWithCustom);

        FeeReceiver[] memory feeReceivers = new FeeReceiver[](1);
        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        nayms.addFeeSchedule(uint256(entityWithCustom), feeReceivers);

        uint256 _premiumPaid = 1e18;
        CalculatedFees memory cf = nayms.calculatePremiumFees(entityWithCustom, _premiumPaid);

        uint256 expectedValue = (_premiumPaid * feeReceivers[0].basisPoints) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, feeReceivers[0].basisPoints, "total bp is incorrect");
    }

    function test_calculatePremiumFees_MultipleReceivers() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        uint256 startingFeeScheduleId = nayms.getPremiumFeeScheduleId(entityWithCustom);

        FeeReceiver[] memory feeReceivers = new FeeReceiver[](3);

        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 150 });
        feeReceivers[1] = FeeReceiver({ receiver: NDF_IDENTIFIER, basisPoints: 75 });
        feeReceivers[2] = FeeReceiver({ receiver: STM_IDENTIFIER, basisPoints: 75 });

        nayms.addFeeSchedule(uint256(entityWithCustom), feeReceivers);

        uint256 currentFeeScheduleId = nayms.getPremiumFeeScheduleId(entityWithCustom);

        assertGt(currentFeeScheduleId, startingFeeScheduleId, "custom fee schedule ID should be greater than default fee schedule ID");

        uint256 _premiumPaid = 1e18;
        CalculatedFees memory cf = nayms.calculatePremiumFees(entityWithCustom, _premiumPaid);

        uint256 expectedValue = (_premiumPaid * (feeReceivers[0].basisPoints + feeReceivers[1].basisPoints + feeReceivers[2].basisPoints)) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, (feeReceivers[0].basisPoints + feeReceivers[1].basisPoints + feeReceivers[2].basisPoints), "total bp is incorrect");

        // Update the same fee schedule: 3 receivers to 1 receiver
        feeReceivers = new FeeReceiver[](1);
        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        nayms.addFeeSchedule(uint256(entityWithCustom), feeReceivers);
        cf = nayms.calculatePremiumFees(entityWithCustom, _premiumPaid);

        expectedValue = (_premiumPaid * feeReceivers[0].basisPoints) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, feeReceivers[0].basisPoints, "total bp is incorrect");
    }

    function test_startTokenSale_FirstTokenSale() public {
        // acc1 is the par token seller
        // acc2 is the par token buyer

        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

        assertEq(nayms.internalBalanceOf(acc1.entityId, acc1.entityId), 1 ether, "entity selling par balance is incorrect");

        changePrank(acc1.addr);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.internalTransferFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, acc1.entityId, 1);

        deal(address(weth), acc2.addr, 1 ether);
        changePrank(acc2.addr);
        weth.approve(address(nayms), 1 ether);
        nayms.externalDeposit(address(weth), 1 ether);
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 1 ether, "entity's weth balance is incorrect");

        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        FeeReceiver[] memory feeReceivers = nayms.getFeeSchedule(LibConstants.MARKET_FEE_SCHEDULE_INITIAL_OFFER);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), 0.5 ether, "par token seller's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), 0.5 ether, "par token buyer's par token (acc1.entityId) balance is incorrect");

        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (0.5 ether * feeReceivers[0].basisPoints) / LibConstants.BP_FACTOR;
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 0.5 ether - commission, "entity's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId), commission, "nayms ltd weth balance is incorrect");
    }

    function test_startTokenSale_PlaceOrderBeforeStartTokenSale() public {
        deal(address(weth), acc2.addr, 1 ether);
        changePrank(acc2.addr);
        weth.approve(address(nayms), 1 ether);
        nayms.externalDeposit(address(weth), 1 ether);
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 1 ether, "entity's weth balance is incorrect");

        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        changePrank(systemAdmin);
        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

        FeeReceiver[] memory feeReceivers = nayms.getFeeSchedule(LibConstants.MARKET_FEE_SCHEDULE_INITIAL_OFFER);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), 0.5 ether, "par token seller's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), 0.5 ether, "par token buyer's par token (acc1.entityId) balance is incorrect");
        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (0.5 ether * feeReceivers[0].basisPoints) / LibConstants.BP_FACTOR;
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 0.5 ether - commission, "par token buyer's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId), commission, "nayms ltd weth balance is incorrect");
    }

    function test_startTokenSale_LockedBalancesAfterUpdatingCollateralRatio() public {
        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

        deal(address(weth), acc2.addr, 1 ether);
        changePrank(acc2.addr);
        weth.approve(address(nayms), 1 ether);
        nayms.externalDeposit(address(weth), 1 ether);
        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        Entity memory entityInfo = nayms.getEntityInfo(acc1.entityId);
        entityInfo.collateralRatio = LibConstants.BP_FACTOR / 2; // Can
        changePrank(systemAdmin);
        nayms.updateEntity(acc1.entityId, entityInfo);

        nayms.getLockedBalance(acc1.entityId, acc1.entityId);
    }

    function test_startTokenSale_TwoFirstTokenSales() public {}
}
