// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, LibConstants } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, FeeSchedule, CalculatedFees } from "../src/diamonds/nayms/AppStorage.sol";
import { SimplePolicy, SimplePolicyInfo, Stakeholders } from "src/diamonds/nayms/interfaces/FreeStructs.sol";

import { LibFeeRouterFixture } from "test/fixtures/LibFeeRouterFixture.sol";

// solhint-disable state-visibility

contract NewFeesTest is D03ProtocolDefaults {
    Entity entityInfo;

    NaymsAccount acc1 = makeNaymsAcc("acc1");
    NaymsAccount acc2 = makeNaymsAcc("acc2");
    NaymsAccount acc3 = makeNaymsAcc("acc3");

    Stakeholders internal stakeholders;
    SimplePolicy internal simplePolicy;

    bytes32 internal testHash = 0x00a420601de63bf726c0be38414e9255d301d74ad0d820d633f3ab75effd6f5b;

    function setUp() public virtual override {
        super.setUp();

        entityInfo = Entity({ assetId: wethId, collateralRatio: LibConstants.BP_FACTOR, maxCapacity: 1 ether, utilizedCapacity: 0, simplePolicyEnabled: true });

        changePrank(systemAdmin);

        nayms.createEntity(acc1.entityId, acc1.id, entityInfo, testHash);
        nayms.createEntity(acc2.entityId, acc2.id, entityInfo, testHash);
        nayms.createEntity(acc3.entityId, acc3.id, entityInfo, testHash);

        nayms.enableEntityTokenization(acc1.entityId, "ESPT", "Entity Selling Par Tokens");

        (stakeholders, simplePolicy) = initPolicy(testHash);
    }

    function fundEntityWeth(NaymsAccount memory acc, uint256 amount) private {
        deal(address(weth), acc.addr, amount);
        changePrank(acc.addr);
        weth.approve(address(nayms), amount);
        uint256 balanceBefore = nayms.internalBalanceOf(acc.entityId, wethId);
        nayms.externalDeposit(address(weth), amount);
        assertEq(nayms.internalBalanceOf(acc.entityId, wethId), balanceBefore + amount, "entity's weth balance is incorrect");
    }

    function test_setFeeSchedule_OnlySystemAdmin() public {
        changePrank(address(0xdead));

        vm.expectRevert("not a system admin");
        nayms.addFeeSchedule(LibConstants.DEFAULT_FEE_SCHEDULE, LibConstants.FEE_TYPE_PREMIUM, defaultFeeRecipients, defaultPremiumFeeBPs);
    }

    function test_removeFeeSchedule() public {
        bytes32 entityId = "anything";
        FeeSchedule memory defaultFeeSchedule = nayms.getFeeSchedule(entityId, LibConstants.FEE_TYPE_PREMIUM);

        bytes32[] memory customRecipient = b32Array1("recipient");
        uint256[] memory customFeeBP = u256Array1(42);

        nayms.addFeeSchedule(entityId, LibConstants.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        FeeSchedule memory storedFeeSchedule = nayms.getFeeSchedule(entityId, LibConstants.FEE_TYPE_PREMIUM);
        assertEq(storedFeeSchedule.receiver[0], customRecipient[0], "fee receiver is not custom");
        assertEq(storedFeeSchedule.basisPoints[0], customFeeBP[0], "fee basis points not custom");

        nayms.removeFeeSchedule(entityId, LibConstants.FEE_TYPE_PREMIUM);
        storedFeeSchedule = nayms.getFeeSchedule(entityId, LibConstants.FEE_TYPE_PREMIUM);
        assertEq(storedFeeSchedule.receiver[0], defaultFeeSchedule.receiver[0], "fee receiver is not custom");
        assertEq(storedFeeSchedule.basisPoints[0], defaultFeeSchedule.basisPoints[0], "fee basis points not custom");
    }

    function test_getPremiumCommissionSchedule_Default() public {
        bytes32 entityWithDefault = keccak256("entity with default fee schedule");
        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(entityWithDefault, LibConstants.FEE_TYPE_PREMIUM);
        assertEq(feeSchedule, premiumFeeScheduleDefault);
    }

    function test_getPremiumCommissionSchedule_Custom() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM fee schedule");
        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_PREMIUM);

        assertEq(feeSchedule, premiumFeeScheduleDefault);

        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint256[] memory customFeeBP = u256Array1(301);

        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);
        FeeSchedule memory storedFeeSchedule = nayms.getFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_PREMIUM);
        assertEq(storedFeeSchedule, customFeeSchedule);
    }

    function test_getTradingCommissionSchedule_Default() public {
        bytes32 entityWithDefault = keccak256("entity with default");
        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(entityWithDefault, LibConstants.FEE_TYPE_TRADING);
        assertEq(feeSchedule, tradingFeeScheduleDefault);
    }

    function test_getTradingCommissionSchedule_Custom() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");
        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING);

        assertEq(feeSchedule, tradingFeeScheduleDefault);

        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint256[] memory customFeeBP = u256Array1(31);

        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customRecipient, customFeeBP);

        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);
        FeeSchedule memory storedFeeSchedule = nayms.getFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING);

        assertEq(storedFeeSchedule, customFeeSchedule);
    }

    function test_calculateTradingFees_SingleReceiver() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");

        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint256[] memory customFeeBP = u256Array1(900);

        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customRecipient, customFeeBP);

        uint256 _buyAmount = 1e18;
        CalculatedFees memory cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        uint256 expectedValue = (_buyAmount * customFeeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, customFeeSchedule.basisPoints[0], "total bp is incorrect");
    }

    function test_calculateTradingFees_MultipleReceivers() public {
        bytes32 entityWithCustom = keccak256("entity with CUSTOM");

        bytes32[] memory customRecipient = b32Array3(NAYMS_LTD_IDENTIFIER, NDF_IDENTIFIER, STM_IDENTIFIER);
        uint256[] memory customFeeBP = u256Array3(150, 75, 75);
        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customRecipient, customFeeBP);

        uint256 _buyAmount = 1e18;
        CalculatedFees memory cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        uint256 expectedValue = (_buyAmount * (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2])) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2]), "total bp is incorrect");

        // Update the same fee schedule: 3 receivers to 1 receiver
        customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        customFeeBP = u256Array1(300);
        customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING, customRecipient, customFeeBP);

        cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        expectedValue = (_buyAmount * customFeeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, customFeeSchedule.basisPoints[0], "total bp is incorrect");

        // Clear out custom fee schedule
        nayms.removeFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING);

        // Should be back to default market fee schedule
        cf = nayms.calculateTradingFees(entityWithCustom, _buyAmount);

        FeeSchedule memory storedFeeSchedule = nayms.getFeeSchedule(entityWithCustom, LibConstants.FEE_TYPE_TRADING);
        uint256 totalBP;
        for (uint256 i; i < storedFeeSchedule.receiver.length; ++i) {
            totalBP += storedFeeSchedule.basisPoints[i];
        }

        expectedValue = (_buyAmount * totalBP) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, totalBP, "total bp is incorrect");
    }

    function test_calculatePremiumFees_SingleReceiver(uint256 _fee) public {
        vm.assume(0 <= _fee && _fee <= LibConstants.BP_FACTOR / 2);
        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint256[] memory customFeeBP = u256Array1(_fee);
        nayms.addFeeSchedule(acc1.entityId, LibConstants.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        fundEntityWeth(acc1, 1 ether);

        changePrank(systemAdmin);
        bytes32 policyId = "policy1";
        nayms.createSimplePolicy(policyId, acc1.entityId, stakeholders, simplePolicy, testHash);

        uint256 premiumPaid = 1e18;
        CalculatedFees memory cf = nayms.calculatePremiumFees(policyId, premiumPaid);

        uint256 expectedTotalPremiumFeeBP = totalPremiumFeeBP(simplePolicy, customFeeBP);
        uint256 expectedPremiumAmount = (premiumPaid * expectedTotalPremiumFeeBP) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedPremiumAmount, "total fees is incorrect");
        assertEq(cf.totalBP, expectedTotalPremiumFeeBP, "total bp is incorrect");
    }

    function test_calculatePremiumFees_MultipleReceivers(
        uint256 _fee,
        uint256 _fee1,
        uint256 _fee2,
        uint256 _fee3
    ) public {
        vm.assume(0 <= _fee && _fee <= LibConstants.BP_FACTOR / 2);
        vm.assume(_fee1 < LibConstants.BP_FACTOR / 2 && _fee2 < LibConstants.BP_FACTOR / 2 && _fee3 < LibConstants.BP_FACTOR / 2);
        vm.assume(0 <= (_fee1 + _fee2 + _fee3) && (_fee1 + _fee2 + _fee3) <= LibConstants.BP_FACTOR / 2);

        bytes32[] memory customRecipient = b32Array3(NAYMS_LTD_IDENTIFIER, NDF_IDENTIFIER, STM_IDENTIFIER);
        uint256[] memory customFeeBP = u256Array3(_fee1, _fee2, _fee3);
        nayms.addFeeSchedule(acc1.entityId, LibConstants.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        fundEntityWeth(acc1, 1 ether);

        changePrank(systemAdmin);
        bytes32 policyId = "policy1";
        nayms.createSimplePolicy(policyId, acc1.entityId, stakeholders, simplePolicy, testHash);

        uint256 _premiumPaid = 1e18;
        CalculatedFees memory cf = nayms.calculatePremiumFees(policyId, _premiumPaid);

        uint256 expectedTotalPremiumFeeBP = totalPremiumFeeBP(simplePolicy, customFeeBP);
        uint256 expectedValue = (_premiumPaid * expectedTotalPremiumFeeBP) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, expectedTotalPremiumFeeBP, "total bp is incorrect");

        // Update the same fee schedule: 3 receivers to 1 receiver
        customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        customFeeBP = u256Array1(_fee);
        nayms.addFeeSchedule(acc1.entityId, LibConstants.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        cf = nayms.calculatePremiumFees(policyId, _premiumPaid);

        expectedTotalPremiumFeeBP = totalPremiumFeeBP(simplePolicy, customFeeBP);
        expectedValue = (_premiumPaid * expectedTotalPremiumFeeBP) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, expectedTotalPremiumFeeBP, "total bp is incorrect");
    }

    function test_zeroPremiumFees() public {
        nayms.addFeeSchedule(acc1.entityId, LibConstants.FEE_TYPE_PREMIUM, b32Array1(NAYMS_LTD_IDENTIFIER), u256Array1(0));

        fundEntityWeth(acc1, 1 ether);

        changePrank(systemAdmin);
        bytes32 policyId = "policy1";
        nayms.createSimplePolicy(policyId, acc1.entityId, stakeholders, simplePolicy, testHash);

        uint256 premiumAmount = 1 ether;
        CalculatedFees memory cf = nayms.calculatePremiumFees(policyId, premiumAmount);

        uint256 expectedTotalPremiumFeeBP = totalPremiumFeeBP(simplePolicy, u256Array1(0));
        uint256 expectedValue = (premiumAmount * expectedTotalPremiumFeeBP) / LibConstants.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "Invalid total fees!");

        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(acc1.entityId, LibConstants.FEE_TYPE_PREMIUM);
        assertEq(feeSchedule.basisPoints.length, 1);
        assertEq(feeSchedule.basisPoints[0], 0);
    }

    function totalPremiumFeeBP(SimplePolicy memory simplePolicy, uint256[] memory customFeeBP) private returns (uint256 totalBP_) {
        for (uint256 i; i < simplePolicy.commissionBasisPoints.length; i++) {
            totalBP_ += simplePolicy.commissionBasisPoints[i];
        }
        for (uint256 i; i < customFeeBP.length; i++) {
            totalBP_ += customFeeBP[i];
        }
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

        fundEntityWeth(acc2, 1 ether);

        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        CalculatedFees memory cf = nayms.calculateTradingFees(acc2.entityId, 0.5 ether);

        assertEq(makerBP, cf.feeAllocations[0].basisPoints, "maker bp is incorrect");

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), 0.5 ether + ((0.5 ether * makerBP) / LibConstants.BP_FACTOR), "makers's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), (0.5 ether - cf.totalFees), "taker's weth balance is incorrect");
    }

    function test_startTokenSale_FirstTokenSale() public {
        // acc1 is the par token seller
        // acc2 is the par token buyer

        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

        assertEq(nayms.internalBalanceOf(acc1.entityId, acc1.entityId), 1 ether, "entity selling par balance is incorrect");

        changePrank(acc1.addr);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.internalTransferFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, acc1.entityId, 1);

        fundEntityWeth(acc2, 1 ether);

        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(acc1.entityId, LibConstants.FEE_TYPE_INITIAL_SALE);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), 0.5 ether, "par token seller's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), 0.5 ether, "par token buyer's par token (acc1.entityId) balance is incorrect");

        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (0.5 ether * feeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 0.5 ether - commission, "entity's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId), commission, "nayms ltd weth balance is incorrect");
    }

    function test_startTokenSale_PlaceOrderBeforeStartTokenSale() public {
        fundEntityWeth(acc2, 1 ether);

        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        changePrank(systemAdmin);
        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(acc1.entityId, LibConstants.FEE_TYPE_INITIAL_SALE);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), 0.5 ether, "par token seller's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), 0.5 ether, "par token buyer's par token (acc1.entityId) balance is incorrect");
        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (0.5 ether * feeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 0.5 ether - commission, "par token buyer's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId), commission, "nayms ltd weth balance is incorrect");
    }

    function test_startTokenSale_StartingWithMultipleExecuteLimitOffers() public {
        CalculatedFees memory cf = nayms.calculateTradingFees(acc2.entityId, 2 ether);
        fundEntityWeth(acc2, 2 ether + cf.totalFees);

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

        libFeeRouterFixture.exposed_calculateTradingFees(bytes32("entity11"), 1e17);
        libFeeRouterFixture.exposed_payTradingFees(bytes32("entity11"), bytes32("entity11"), bytes32("entity21"), bytes32("entity21"), 1e17);
    }

    function test_zeroTradingFees() public {
        // acc1 is the par token seller
        // acc2 is the par token buyer

        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);
        assertEq(nayms.internalBalanceOf(acc1.entityId, acc1.entityId), 1 ether, "entity selling par balance is incorrect");

        nayms.addFeeSchedule(acc2.entityId, LibConstants.FEE_TYPE_TRADING, b32Array1(NAYMS_LTD_IDENTIFIER), u256Array1(0));

        fundEntityWeth(acc2, 1 ether);

        changePrank(acc1.addr);
        CalculatedFees memory cf = nayms.calculateTradingFees(acc2.entityId, 1 ether);

        assertEq(cf.totalFees, 0, "Invalid total fees!");
    }

    function assertEq(FeeSchedule memory feeSchedule, FeeSchedule memory feeScheduleTarget) private {
        assertEq(feeSchedule.receiver.length, feeScheduleTarget.receiver.length, "fee schedule receivers count don't match");
        for (uint256 i; i < feeSchedule.receiver.length; i++) {
            assertEq(feeSchedule.receiver[i], feeScheduleTarget.receiver[i], "fee schedule receivers don't match");
            assertEq(feeSchedule.basisPoints[i], feeScheduleTarget.basisPoints[i], "fee schedule basisPoints don't match");
        }
    }
}
