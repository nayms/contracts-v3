// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, LibConstants } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, FeeSchedule, CalculatedFees } from "../src/diamonds/nayms/AppStorage.sol";

import { LibFeeRouterFixture } from "test/fixtures/LibFeeRouterFixture.sol";

// solhint-disable state-visibility

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

        FeeSchedule memory feeSchedule = feeSched1(NAYMS_LTD_IDENTIFIER, 300);

        vm.expectRevert("not a system admin");
        nayms.addFeeSchedule(LibConstants.DEFAULT_PREMIUM_FEE_SCHEDULE, LibConstants.FEE_TYPE_PREMIUM, feeSchedule);
    }

    function test_removeFeeSchedule() public {
        bytes32 entityId = "anything";
        FeeSchedule memory feeSchedule = nayms.getPremiumFeeSchedule(entityId);
        delete feeSchedule.receiver;
        nayms.addFeeSchedule(entityId, LibConstants.FEE_TYPE_PREMIUM, feeSchedule);

        assertEq(nayms.getPremiumFeeSchedule(entityId).receiver.length, 0, "fee receivers length should be 0");
    }

    function test_getPremiumCommissionSchedule_Default() public {
        bytes32 entityWithDefault = keccak256("entity with default fee schedule");
        FeeSchedule memory feeSchedule = nayms.getPremiumFeeSchedule(entityWithDefault);

        assertEq(feeSchedule, premiumFeeScheduleDefault);
    }

    function test_getPremiumCommissionSchedule_Custom() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM fee schedule");
        FeeSchedule memory feeSchedule = nayms.getPremiumFeeSchedule(entityWithCustom);

        assertEq(feeSchedule, premiumFeeScheduleDefault);

        FeeSchedule memory customFeeSchedule = feeSched1(NAYMS_LTD_IDENTIFIER, 301);
        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_PREMIUM, customFeeSchedule);

        FeeSchedule memory storedFeeSchedule = nayms.getPremiumFeeSchedule(entityWithCustom);
        assertEq(storedFeeSchedule, customFeeSchedule);
    }

    function test_getTradingCommissionSchedule_Default() public {
        bytes32 entityWithDefault = keccak256("entity with default");
        FeeSchedule memory feeSchedule = nayms.getTradingFeeSchedule(entityWithDefault);

        assertEq(feeSchedule, tradingFeeScheduleDefault);
    }

    function test_getTradingCommissionSchedule_Custom() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        FeeSchedule memory feeSchedule = nayms.getTradingFeeSchedule(entityWithCustom);

        assertEq(feeSchedule, tradingFeeScheduleDefault);

        FeeSchedule memory customFeeSchedule = feeSched1(NAYMS_LTD_IDENTIFIER, 31);
        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customFeeSchedule);

        FeeSchedule memory storedFeeSchedule = nayms.getTradingFeeSchedule(entityWithCustom);
        assertEq(storedFeeSchedule, customFeeSchedule);
    }

    function test_calculateTradingFees_SingleReceiver() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        FeeSchedule memory customFeeSchedule = feeSched1(NAYMS_LTD_IDENTIFIER, 300);
        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customFeeSchedule);

        uint256 _buyAmount = 1e18;
        CalculatedFees memory cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        uint256 expectedValue = (_buyAmount * customFeeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, customFeeSchedule.basisPoints[0], "total bp is incorrect");
    }

    function test_calculateTradingFees_MultipleReceivers() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");

        FeeSchedule memory customFeeSchedule = feeSched3(NAYMS_LTD_IDENTIFIER, NDF_IDENTIFIER, STM_IDENTIFIER, 150, 75, 75);

        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customFeeSchedule);

        uint256 _buyAmount = 1e18;
        CalculatedFees memory cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        uint256 expectedValue = (_buyAmount * (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2])) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2]), "total bp is incorrect");

        // Update the same fee schedule: 3 receivers to 1 receiver
        customFeeSchedule = feeSched1(NAYMS_LTD_IDENTIFIER, 300);
        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customFeeSchedule);

        cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        expectedValue = (_buyAmount * customFeeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, customFeeSchedule.basisPoints[0], "total bp is incorrect");

        // Clear out custom fee schedule
        bytes32[] memory r;
        uint256[] memory bp;
        customFeeSchedule = FeeSchedule({ receiver: r, basisPoints: bp });
        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customFeeSchedule);

        // Should be back to default market fee schedule
        cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        FeeSchedule memory storedFeeSchedule = nayms.getTradingFeeSchedule(entityWithCustom);
        uint256 totalBP;
        for (uint256 i; i < storedFeeSchedule.receiver.length; ++i) {
            totalBP += storedFeeSchedule.basisPoints[i];
        }

        expectedValue = (_buyAmount * totalBP) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, totalBP, "total bp is incorrect");
    }

    function test_calculatePremiumFees_SingleReceiver() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");

        FeeSchedule memory customFeeSchedule = feeSched1(NAYMS_LTD_IDENTIFIER, 300);
        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_PREMIUM, customFeeSchedule);

        uint256 _premiumPaid = 1e18;
        CalculatedFees memory cf = nayms.calculatePremiumFees(entityWithCustom, _premiumPaid);

        uint256 expectedValue = (_premiumPaid * customFeeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, customFeeSchedule.basisPoints[0], "total bp is incorrect");
    }

    function test_calculatePremiumFees_MultipleReceivers() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        FeeSchedule memory customFeeSchedule = feeSched3(NAYMS_LTD_IDENTIFIER, NDF_IDENTIFIER, STM_IDENTIFIER, 150, 75, 75);

        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_PREMIUM, customFeeSchedule);

        uint256 _premiumPaid = 1e18;
        CalculatedFees memory cf = nayms.calculatePremiumFees(entityWithCustom, _premiumPaid);

        uint256 expectedValue = (_premiumPaid * (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2])) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2]), "total bp is incorrect");

        // Update the same fee schedule: 3 receivers to 1 receiver
        customFeeSchedule = feeSched1(NAYMS_LTD_IDENTIFIER, 300);
        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_PREMIUM, customFeeSchedule);

        cf = nayms.calculatePremiumFees(entityWithCustom, _premiumPaid);

        expectedValue = (_premiumPaid * customFeeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, customFeeSchedule.basisPoints[0], "total bp is incorrect");
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

        FeeSchedule memory feeSchedule = nayms.getInitialSaleFeeSchedule(acc1.entityId);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), 0.5 ether, "par token seller's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), 0.5 ether, "par token buyer's par token (acc1.entityId) balance is incorrect");

        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (0.5 ether * feeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;
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

        FeeSchedule memory feeSchedule = nayms.getInitialSaleFeeSchedule(acc1.entityId);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), 0.5 ether, "par token seller's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), 0.5 ether, "par token buyer's par token (acc1.entityId) balance is incorrect");
        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (0.5 ether * feeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;
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

    function test_cov_LibFeeRouterFixture() public {
        // just for coverage sigh.
        LibFeeRouterFixture libFeeRouterFixture = new LibFeeRouterFixture();
        libFeeRouterFixture.exposed_calculatePremiumFees(bytes32("policy11"), 1e17);

        libFeeRouterFixture.exposed_payPremiumFees(bytes32("policy11"), 1e17);
    }

    function assertEq(FeeSchedule memory feeSchedule, FeeSchedule memory feeScheduleTarget) private {
        assertEq(feeSchedule.receiver.length, feeScheduleTarget.receiver.length, "fee schedule receivers count don't match");
        assertEq(feeSchedule.receiver[0], feeScheduleTarget.receiver[0], "fee schedule receivers don't match");
        assertEq(feeSchedule.basisPoints.length, feeScheduleTarget.basisPoints.length, "fee schedule basisPoints count don't match");
        assertEq(feeSchedule.basisPoints[0], feeScheduleTarget.basisPoints[0], "fee schedule basisPoints don't match");
    }
}
