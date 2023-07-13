// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable no-console
import { console2 } from "forge-std/console2.sol";

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

        // prettier-ignore
        entityInfo = Entity({ 
            assetId: wethId, 
            collateralRatio: LibConstants.BP_FACTOR, 
            maxCapacity: 1 ether, 
            utilizedCapacity: 0, 
            simplePolicyEnabled: true 
        });

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
        nayms.startTokenSale(acc1.entityId, 1000 ether, 1000 ether);

        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint256[] memory customFeeBP = u256Array1(900);
        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(acc2.entityId, LibConstants.FEE_TYPE_INITIAL_SALE, customRecipient, customFeeBP);

        uint256 _buyAmount = 10 ether;
        (uint256 totalFees_, uint256 totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, _buyAmount);

        uint256 expectedValue = (_buyAmount * customFeeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, customFeeSchedule.basisPoints[0], "total bp is incorrect");
    }

    function test_calculateTradingFees_BuyExternal() public {
        uint256 _buyAmount = 10 ether;
        (uint256 totalFees_, uint256 totalBP_) = nayms.calculateTradingFees(acc2.entityId, acc1.entityId, wethId, _buyAmount);

        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(acc2.entityId, LibConstants.FEE_TYPE_TRADING);
        uint256 expectedValue = (_buyAmount * feeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, feeSchedule.basisPoints[0], "total bp is incorrect");

    }

    function test_calculateTradingFees_MultipleReceivers() public {
        uint256 saleAmount = 1000 ether;
        nayms.startTokenSale(acc1.entityId, saleAmount, saleAmount);

        bytes32[] memory customRecipient = b32Array3(NAYMS_LTD_IDENTIFIER, NDF_IDENTIFIER, STM_IDENTIFIER);
        uint256[] memory customFeeBP = u256Array3(150, 75, 75);
        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(acc2.entityId, LibConstants.FEE_TYPE_INITIAL_SALE, customRecipient, customFeeBP);

        uint256 _buyAmount = 1e18;
        (uint256 totalFees_, uint256 totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, _buyAmount);

        uint256 expectedValue = (_buyAmount * (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2])) / LibConstants.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2]), "total bp is incorrect");

        // Update the same fee schedule: 3 receivers to 1 receiver
        customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        customFeeBP = u256Array1(300);
        customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(acc2.entityId, LibConstants.FEE_TYPE_INITIAL_SALE, customRecipient, customFeeBP);

        (totalFees_, totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, _buyAmount);

        expectedValue = (_buyAmount * customFeeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, customFeeSchedule.basisPoints[0], "total bp is incorrect");

        // Clear out custom fee schedule
        nayms.removeFeeSchedule(acc2.entityId, LibConstants.FEE_TYPE_INITIAL_SALE);

        // Should be back to default market fee schedule
        (totalFees_, totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, _buyAmount);

        FeeSchedule memory storedFeeSchedule = nayms.getFeeSchedule(acc2.entityId, LibConstants.FEE_TYPE_INITIAL_SALE);
        uint256 totalBP;
        for (uint256 i; i < storedFeeSchedule.receiver.length; ++i) {
            totalBP += storedFeeSchedule.basisPoints[i];
        }

        expectedValue = (_buyAmount * totalBP) / LibConstants.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, totalBP, "total bp is incorrect");
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
        uint256 defaultFeeScheduleTotalBP = 30;
        uint16 makerBP = 10;
        nayms.replaceMakerBP(makerBP);

        uint256 sellAmount = 1 ether;
        uint256 buyAmount = 0.5 ether;

        nayms.startTokenSale(acc1.entityId, sellAmount, sellAmount);

        fundEntityWeth(acc2, sellAmount);

        nayms.executeLimitOffer(wethId, buyAmount, acc1.entityId, buyAmount);

        (uint256 totalFees_, uint256 totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, buyAmount);

        assertEq(defaultFeeScheduleTotalBP + makerBP, totalBP_, "total BP is incorrect");

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), buyAmount + ((buyAmount * makerBP) / LibConstants.BP_FACTOR), "makers's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), (sellAmount - buyAmount - totalFees_), "taker's weth balance is incorrect");
    }

    function test_startTokenSale_FirstTokenSale() public {
        // acc1 is the par token seller (maker)
        // acc2 is the par token buyer (taker)

        uint256 saleAmount = 1 ether;
        uint256 buyAmount = 0.5 ether;

        nayms.startTokenSale(acc1.entityId, saleAmount, saleAmount);

        assertEq(nayms.internalBalanceOf(acc1.entityId, acc1.entityId), saleAmount, "maker balance is incorrect");

        changePrank(acc1.addr);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.internalTransferFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, acc1.entityId, 1);

        fundEntityWeth(acc2, saleAmount);

        nayms.executeLimitOffer(wethId, buyAmount, acc1.entityId, buyAmount);

        FeeSchedule memory feeSchedule = nayms.getFeeSchedule(acc1.entityId, LibConstants.FEE_TYPE_INITIAL_SALE);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), buyAmount, "maker's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), buyAmount, "taker's par token (acc1.entityId) balance is incorrect");

        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (buyAmount * feeSchedule.basisPoints[0]) / LibConstants.BP_FACTOR;
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), buyAmount - commission, "entity's weth balance is incorrect");
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
        uint256 totalAmount = 2 ether;
        uint256 singleOrderAmount = 0.5 ether;
        uint256 singleSaleAmount = 1 ether;

        uint256 defaultTotalBP = 30;
        fundEntityWeth(acc2, totalAmount + (totalAmount * defaultTotalBP / LibConstants.BP_FACTOR));
        
        changePrank(acc2.addr);
        nayms.executeLimitOffer(wethId, singleOrderAmount, acc1.entityId, singleOrderAmount);
        nayms.executeLimitOffer(wethId, singleOrderAmount, acc1.entityId, singleOrderAmount);

        changePrank(systemAdmin);
        nayms.startTokenSale(acc1.entityId, singleSaleAmount, singleSaleAmount);
        changePrank(acc2.addr);
        nayms.executeLimitOffer(wethId, singleOrderAmount, acc1.entityId, singleOrderAmount);

        changePrank(systemAdmin);
        nayms.assignRole(acc3.id, systemContext, LibConstants.ROLE_SYSTEM_MANAGER);

        // Switch up who starts the token sale
        changePrank(acc3.addr);
        nayms.startTokenSale(acc1.entityId, singleSaleAmount, singleSaleAmount);

        changePrank(acc2.addr);
        nayms.executeLimitOffer(wethId, singleOrderAmount, acc1.entityId, singleOrderAmount);

        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), totalAmount, "acc2 should have all of the 2e18 par tokens");
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 0, "acc2 should have spent all their weth");
    }

    function test_cov_LibFeeRouterFixture() public {
        // just for coverage sigh.
        LibFeeRouterFixture libFeeRouterFixture = new LibFeeRouterFixture();

        libFeeRouterFixture.exposed_calculatePremiumFees(bytes32("policy11"), 1e17);
        libFeeRouterFixture.exposed_payPremiumFees(bytes32("policy11"), 1e17);

        libFeeRouterFixture.exposed_calculateTradingFees(acc2.entityId, acc1.entityId, wethId, 1 ether);
        libFeeRouterFixture.exposed_payTradingFees(bytes32("entity11"), bytes32("entity11"), bytes32("entity21"), bytes32("entity21"), 1e17);
    }

    function test_zeroTradingFees() public {
        // acc1 is the par token seller
        // acc2 is the par token buyer

        uint256 saleAmount = 1 ether;
        nayms.startTokenSale(acc1.entityId, saleAmount, saleAmount);
        assertEq(nayms.internalBalanceOf(acc1.entityId, acc1.entityId), saleAmount, "entity selling par balance is incorrect");

        nayms.addFeeSchedule(acc2.entityId, LibConstants.FEE_TYPE_INITIAL_SALE, b32Array1(NAYMS_LTD_IDENTIFIER), u256Array1(0));

        fundEntityWeth(acc2, saleAmount);

        changePrank(acc1.addr);
        (uint256 totalFees_, ) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, saleAmount);

        assertEq(totalFees_, 0, "Invalid total fees!");
    }

    function assertEq(FeeSchedule memory feeSchedule, FeeSchedule memory feeScheduleTarget) private {
        assertEq(feeSchedule.receiver.length, feeScheduleTarget.receiver.length, "fee schedule receivers count don't match");
        for (uint256 i; i < feeSchedule.receiver.length; i++) {
            assertEq(feeSchedule.receiver[i], feeScheduleTarget.receiver[i], "fee schedule receivers don't match");
            assertEq(feeSchedule.basisPoints[i], feeScheduleTarget.basisPoints[i], "fee schedule basisPoints don't match");
        }
    }
}
