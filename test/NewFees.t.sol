// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, LibConstants } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, FeeReceiver, CalculatedFees } from "../src/diamonds/nayms/AppStorage.sol";

contract NewFeesTest is D03ProtocolDefaults {
    Entity entityInfo;

    NaymsAccount acc1 = makeNaymsAcc("acc1");
    NaymsAccount acc2 = makeNaymsAcc("acc2");
    NaymsAccount acc3 = makeNaymsAcc("acc3");

    function setUp() public virtual override {
        super.setUp();

        entityInfo = Entity({ assetId: wethId, collateralRatio: LibConstants.BP_FACTOR, maxCapacity: 1 ether, utilizedCapacity: 0, simplePolicyEnabled: true });

        changePrank(systemAdmin);
        nayms.createEntity(acc1.entityId, acc1.id, entityInfo, "entity test hash");
        nayms.createEntity(acc2.entityId, acc2.id, entityInfo, "entity test hash");
        nayms.createEntity(acc3.entityId, acc3.id, entityInfo, "entity test hash");
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

        assertGt(nayms.getTradingFeeScheduleId(entityWithCustom), feeScheduleId, "custom fee schedule ID should be greater than default fee schedule ID");

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

    function test_calculatePremiumFees_SingleReceiver() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        uint256 feeScheduleId = nayms.getPremiumFeeScheduleId(entityWithCustom);

        FeeReceiver[] memory feeReceivers = new FeeReceiver[](1);
        feeReceivers[0] = FeeReceiver({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        nayms.addFeeSchedule(uint256(entityWithCustom), feeReceivers);

        assertGt(nayms.getPremiumFeeScheduleId(entityWithCustom), feeScheduleId, "custom fee schedule ID should be greater than default fee schedule ID");

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

    function test_replaceMakerBP() public {
        uint16 makerBP = 10;
        nayms.replaceMakerBP(makerBP);

        assertEq(nayms.getMakerBP(), makerBP);
        makerBP = 5001;
        vm.expectRevert();
        nayms.replaceMakerBP(makerBP);
    }

    function test_payTradingFees_MarketMakerFees() public {
        uint16 makerBP = 10;
        nayms.replaceMakerBP(makerBP);

        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

        deal(address(weth), acc2.addr, 1 ether);
        changePrank(acc2.addr);
        weth.approve(address(nayms), 1 ether);
        nayms.externalDeposit(address(weth), 1 ether);
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 1 ether, "entity's weth balance is incorrect");

        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        CalculatedFees memory cf = nayms.calculateTradingFees(acc2.entityId, 0.5 ether);

        assertEq(makerBP, cf.feeAllocations[0].basisPoints, "maker bp is incorrect");

        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 0.5 ether - cf.totalFees, "entity's weth balance is incorrect");
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

    function test_startTokenSale_StartingWithMultipleExecuteLimitOffers() public {
        CalculatedFees memory cf = nayms.calculateTradingFees(acc2.entityId, 2 ether);
        deal(address(weth), acc2.addr, 2 ether + cf.totalFees);
        changePrank(acc2.addr);
        weth.approve(address(nayms), 2 ether + cf.totalFees);
        nayms.externalDeposit(address(weth), 2 ether + cf.totalFees);

        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);
        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        changePrank(systemAdmin);
        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);
        changePrank(acc2.addr);
        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        changePrank(systemAdmin);
        nayms.assignRole(acc3.id, systemContext, LibConstants.ROLE_SYSTEM_MANAGER);

        // Switch up who starts the token sale
        changePrank(acc3.addr);
        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

        changePrank(acc2.addr);
        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), 2 ether, "acc2 should have all of the 2e18 par tokens");
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 0, "acc2 should have spent all their weth");
    }
}
