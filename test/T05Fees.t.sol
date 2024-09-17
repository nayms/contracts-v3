// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// solhint-disable no-console
import { console2 as c } from "forge-std/console2.sol";
import { StdStyle } from "forge-std/Test.sol";

import { D03ProtocolDefaults, LC } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, FeeSchedule, CalculatedFees } from "../src/shared/AppStorage.sol";
import { SimplePolicy, SimplePolicyInfo, Stakeholders } from "../src/shared/FreeStructs.sol";
import "src/shared/CustomErrors.sol";
import { LibHelpers } from "src/libs/LibHelpers.sol";

import { LibFeeRouterFixture } from "test/fixtures/LibFeeRouterFixture.sol";

// solhint-disable state-visibility

contract T05FeesTest is D03ProtocolDefaults {
    using LibHelpers for *;
    using StdStyle for *;

    Entity entityInfo;

    NaymsAccount acc1 = makeNaymsAcc("acc1");
    NaymsAccount acc2 = makeNaymsAcc("acc2");
    NaymsAccount acc3 = makeNaymsAcc("acc3");

    Stakeholders internal stakeholders;
    SimplePolicy internal simplePolicy;

    bytes32 internal testHash = 0x00a420601de63bf726c0be38414e9255d301d74ad0d820d633f3ab75effd6f5b;

    function setUp() public {
        // prettier-ignore
        entityInfo = Entity({ 
            assetId: wethId, 
            collateralRatio: LC.BP_FACTOR, 
            maxCapacity: 1 ether, 
            utilizedCapacity: 0, 
            simplePolicyEnabled: true 
        });

        changePrank(sm.addr);

        nayms.createEntity(acc1.entityId, acc1.id, entityInfo, testHash);
        nayms.createEntity(acc2.entityId, acc2.id, entityInfo, testHash);
        nayms.createEntity(acc3.entityId, acc3.id, entityInfo, testHash);

        nayms.enableEntityTokenization(acc1.entityId, "ESPT", "Entity Selling Par Tokens", 1e6);

        (stakeholders, simplePolicy) = initPolicy(testHash);

        changePrank(sa.addr);
    }

    function test_setFeeSchedule_OnlySystemAdmin() public {
        changePrank(address(0xdead));

        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, address(0xdead)._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_ADMINS));
        nayms.addFeeSchedule(LC.DEFAULT_FEE_SCHEDULE, LC.FEE_TYPE_PREMIUM, defaultFeeRecipients, defaultPremiumFeeBPs);
    }

    function test_removeFeeSchedule() public {
        bytes32 entityId = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256("anything")));

        changePrank(sm);
        nayms.createEntity(entityId, acc1.id, entityInfo, testHash);

        (bytes32[] memory defaultReceiver, uint16[] memory defaultBasisPoints) = nayms.getFeeSchedule(entityId, LC.FEE_TYPE_PREMIUM);

        bytes32[] memory customRecipient = b32Array1("recipient");
        uint16[] memory customFeeBP = u16Array1(42);

        changePrank(sa);
        nayms.addFeeSchedule(entityId, LC.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        (bytes32[] memory storedReceiver, uint16[] memory storedBasisPoints) = nayms.getFeeSchedule(entityId, LC.FEE_TYPE_PREMIUM);
        assertEq(storedReceiver[0], customRecipient[0], "fee receiver is not custom");
        assertEq(storedBasisPoints[0], customFeeBP[0], "fee basis points not custom");

        nayms.removeFeeSchedule(entityId, LC.FEE_TYPE_PREMIUM);
        (storedReceiver, storedBasisPoints) = nayms.getFeeSchedule(entityId, LC.FEE_TYPE_PREMIUM);
        assertEq(storedReceiver[0], defaultReceiver[0], "fee receiver is not custom");
        assertEq(storedBasisPoints[0], defaultBasisPoints[0], "fee basis points not custom");
    }

    function test_getPremiumCommissionSchedule_Default() public {
        bytes32 entityWithDefault = keccak256("entity with default fee schedule");
        (bytes32[] memory receiver, uint16[] memory basisPoints) = nayms.getFeeSchedule(entityWithDefault, LC.FEE_TYPE_PREMIUM);
        assertEq(FeeSchedule({ receiver: receiver, basisPoints: basisPoints }), premiumFeeScheduleDefault);
    }

    function test_AddFeeSchedule_EntityDoesNotExist() public {
        bytes32 entityWithCustom = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256("entity with CUSTOM fee schedule")));

        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint16[] memory customFeeBP = u16Array1(301);

        vm.expectRevert(abi.encodeWithSelector(EntityDoesNotExist.selector, entityWithCustom));
        nayms.addFeeSchedule(entityWithCustom, LC.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);
    }
    function test_getPremiumCommissionSchedule_Custom() public {
        bytes32 entityWithCustom = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256("entity with CUSTOM fee schedule")));

        changePrank(sm);
        nayms.createEntity(entityWithCustom, acc1.id, entityInfo, testHash);

        (bytes32[] memory receiver, uint16[] memory basisPoints) = nayms.getFeeSchedule(entityWithCustom, LC.FEE_TYPE_PREMIUM);
        assertEq(FeeSchedule({ receiver: receiver, basisPoints: basisPoints }), premiumFeeScheduleDefault);

        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint16[] memory customFeeBP = u16Array1(301);

        changePrank(sa);
        nayms.addFeeSchedule(entityWithCustom, LC.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);
        (bytes32[] memory storedReceiver, uint16[] memory storedBasisPoints) = nayms.getFeeSchedule(entityWithCustom, LC.FEE_TYPE_PREMIUM);
        assertEq(FeeSchedule({ receiver: storedReceiver, basisPoints: storedBasisPoints }), customFeeSchedule);
    }

    function test_getTradingCommissionSchedule_Default() public {
        bytes32 entityWithDefault = keccak256("entity with default");
        (bytes32[] memory receiver, uint16[] memory basisPoints) = nayms.getFeeSchedule(entityWithDefault, LC.FEE_TYPE_TRADING);
        assertEq(FeeSchedule({ receiver: receiver, basisPoints: basisPoints }), tradingFeeScheduleDefault);
    }

    function test_getTradingCommissionSchedule_Custom() public {
        bytes32 entityWithCustom = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256("entity with CUSTOM")));

        changePrank(sm);
        nayms.createEntity(entityWithCustom, acc1.id, entityInfo, testHash);

        (bytes32[] memory receiver, uint16[] memory basisPoints) = nayms.getFeeSchedule(entityWithCustom, LC.FEE_TYPE_TRADING);
        assertEq(FeeSchedule({ receiver: receiver, basisPoints: basisPoints }), tradingFeeScheduleDefault);

        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint16[] memory customFeeBP = u16Array1(31);

        changePrank(sa);
        nayms.addFeeSchedule(entityWithCustom, LC.FEE_TYPE_TRADING, customRecipient, customFeeBP);

        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);
        (bytes32[] memory storedReceiver, uint16[] memory storedBasisPoints) = nayms.getFeeSchedule(entityWithCustom, LC.FEE_TYPE_TRADING);
        assertEq(FeeSchedule({ receiver: storedReceiver, basisPoints: storedBasisPoints }), customFeeSchedule);
    }

    function test_calculateTradingFees_SingleReceiver() public {
        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint16[] memory customFeeBP = u16Array1(900);
        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(acc2.entityId, LC.FEE_TYPE_INITIAL_SALE, customRecipient, customFeeBP);

        uint256 _buyAmount = 10 ether;
        (uint256 totalFees_, uint256 totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, _buyAmount);

        uint256 expectedValue = (_buyAmount * customFeeSchedule.basisPoints[0]) / LC.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, customFeeSchedule.basisPoints[0], "total bp is incorrect");
    }

    function test_calculateTradingFees_BuyExternal() public {
        uint256 _buyAmount = 10 ether;
        (uint256 totalFees_, uint256 totalBP_) = nayms.calculateTradingFees(acc2.entityId, acc1.entityId, wethId, _buyAmount);

        (, uint16[] memory basisPoints) = nayms.getFeeSchedule(acc2.entityId, LC.FEE_TYPE_INITIAL_SALE);
        uint256 expectedValue = (_buyAmount * basisPoints[0]) / LC.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, basisPoints[0], "total bp is incorrect");
    }

    function test_calculateTradingFees_MultipleReceivers() public {
        bytes32[] memory customRecipient = b32Array3(NAYMS_LTD_IDENTIFIER, NDF_IDENTIFIER, STM_IDENTIFIER);
        uint16[] memory customFeeBP = u16Array3(150, 75, 75);
        FeeSchedule memory customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(acc2.entityId, LC.FEE_TYPE_INITIAL_SALE, customRecipient, customFeeBP);

        uint256 _buyAmount = 1e18;
        (uint256 totalFees_, uint256 totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, _buyAmount);

        uint256 expectedValue = (_buyAmount * (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2])) / LC.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, (customFeeSchedule.basisPoints[0] + customFeeSchedule.basisPoints[1] + customFeeSchedule.basisPoints[2]), "total bp is incorrect");

        // Update the same fee schedule: 3 receivers to 1 receiver
        customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        customFeeBP = u16Array1(300);
        customFeeSchedule = feeSched(customRecipient, customFeeBP);

        nayms.addFeeSchedule(acc2.entityId, LC.FEE_TYPE_INITIAL_SALE, customRecipient, customFeeBP);

        (totalFees_, totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, _buyAmount);

        expectedValue = (_buyAmount * customFeeSchedule.basisPoints[0]) / LC.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, customFeeSchedule.basisPoints[0], "total bp is incorrect");

        // Clear out custom fee schedule
        nayms.removeFeeSchedule(acc2.entityId, LC.FEE_TYPE_INITIAL_SALE);

        // Should be back to default market fee schedule
        (totalFees_, totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, _buyAmount);

        (bytes32[] memory storedReceiver, uint16[] memory storedBasisPoints) = nayms.getFeeSchedule(acc2.entityId, LC.FEE_TYPE_INITIAL_SALE);
        uint256 totalBP;
        for (uint256 i; i < storedReceiver.length; ++i) {
            totalBP += storedBasisPoints[i];
        }

        expectedValue = (_buyAmount * totalBP) / LC.BP_FACTOR;

        assertEq(totalFees_, expectedValue, "total fees is incorrect");
        assertEq(totalBP_, totalBP, "total bp is incorrect");
    }

    function test_calculatePremiumFees_SingleReceiver(uint16 _fee) public {
        vm.assume(0 <= _fee && _fee <= LC.BP_FACTOR / 2);
        bytes32[] memory customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        uint16[] memory customFeeBP = u16Array1(_fee);
        nayms.addFeeSchedule(acc1.entityId, LC.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        fundEntityWeth(acc1, 1 ether);

        changePrank(su.addr);
        bytes32 policyId = makeId(LC.OBJECT_TYPE_POLICY, bytes20("policy1"));
        nayms.createSimplePolicy(policyId, acc1.entityId, stakeholders, simplePolicy, testHash);

        uint256 premiumPaid = 1e18;
        CalculatedFees memory cf = nayms.calculatePremiumFees(policyId, premiumPaid);

        uint256 expectedTotalPremiumFeeBP = totalPremiumFeeBP(simplePolicy, customFeeBP);
        uint256 expectedPremiumAmount = (premiumPaid * expectedTotalPremiumFeeBP) / LC.BP_FACTOR;

        assertEq(cf.totalFees, expectedPremiumAmount, "total fees is incorrect");
        assertEq(cf.totalBP, expectedTotalPremiumFeeBP, "total bp is incorrect");
        assertEq(cf.feeAllocations.length, simplePolicy.commissionReceivers.length + customRecipient.length, "fee allocation length incorrect");
    }

    function test_calculatePremiumFees_MultipleReceivers(uint16 _fee, uint16 _fee1, uint16 _fee2, uint16 _fee3) public {
        vm.assume(0 <= _fee && _fee <= LC.BP_FACTOR / 2);
        vm.assume(_fee1 < LC.BP_FACTOR / 2 && _fee2 < LC.BP_FACTOR / 2 && _fee3 < LC.BP_FACTOR / 2);
        vm.assume(0 <= (_fee1 + _fee2 + _fee3) && (_fee1 + _fee2 + _fee3) <= LC.BP_FACTOR / 2);

        bytes32[] memory customRecipient = b32Array3(NAYMS_LTD_IDENTIFIER, NDF_IDENTIFIER, STM_IDENTIFIER);
        uint16[] memory customFeeBP = u16Array3(_fee1, _fee2, _fee3);
        nayms.addFeeSchedule(acc1.entityId, LC.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        fundEntityWeth(acc1, 1 ether);

        changePrank(su.addr);
        bytes32 policyId = makeId(LC.OBJECT_TYPE_POLICY, bytes20("policy1"));
        nayms.createSimplePolicy(policyId, acc1.entityId, stakeholders, simplePolicy, testHash);

        uint256 _premiumPaid = 1e18;
        CalculatedFees memory cf = nayms.calculatePremiumFees(policyId, _premiumPaid);

        uint256 expectedTotalPremiumFeeBP = totalPremiumFeeBP(simplePolicy, customFeeBP);
        uint256 expectedValue = (_premiumPaid * expectedTotalPremiumFeeBP) / LC.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, expectedTotalPremiumFeeBP, "total bp is incorrect");
        assertEq(cf.feeAllocations.length, simplePolicy.commissionReceivers.length + customRecipient.length, "fee allocation count incorrect");

        changePrank(systemAdmin);

        // Update the same fee schedule: 3 receivers to 1 receiver
        customRecipient = b32Array1(NAYMS_LTD_IDENTIFIER);
        customFeeBP = u16Array1(_fee);
        nayms.addFeeSchedule(acc1.entityId, LC.FEE_TYPE_PREMIUM, customRecipient, customFeeBP);

        cf = nayms.calculatePremiumFees(policyId, _premiumPaid);

        expectedTotalPremiumFeeBP = totalPremiumFeeBP(simplePolicy, customFeeBP);
        expectedValue = (_premiumPaid * expectedTotalPremiumFeeBP) / LC.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "total fees is incorrect");
        assertEq(cf.totalBP, expectedTotalPremiumFeeBP, "total bp is incorrect");
        assertEq(cf.feeAllocations.length, simplePolicy.commissionReceivers.length + customRecipient.length, "fee allocation count incorrect");
    }

    function test_zeroPremiumFees() public {
        nayms.addFeeSchedule(acc1.entityId, LC.FEE_TYPE_PREMIUM, b32Array1(NAYMS_LTD_IDENTIFIER), u16Array1(0));

        fundEntityWeth(acc1, 1 ether);

        changePrank(su.addr);
        bytes32 policyId = makeId(LC.OBJECT_TYPE_POLICY, bytes20("policy1"));
        nayms.createSimplePolicy(policyId, acc1.entityId, stakeholders, simplePolicy, testHash);

        uint256 premiumAmount = 1 ether;
        CalculatedFees memory cf = nayms.calculatePremiumFees(policyId, premiumAmount);

        uint256 expectedTotalPremiumFeeBP = totalPremiumFeeBP(simplePolicy, u16Array1(0));
        uint256 expectedValue = (premiumAmount * expectedTotalPremiumFeeBP) / LC.BP_FACTOR;

        assertEq(cf.totalFees, expectedValue, "Invalid total fees!");

        (, uint16[] memory basisPoints) = nayms.getFeeSchedule(acc1.entityId, LC.FEE_TYPE_PREMIUM);
        assertEq(basisPoints.length, 1);
        assertEq(basisPoints[0], 0);
    }

    function totalPremiumFeeBP(SimplePolicy memory _simplePolicy, uint16[] memory customFeeBP) private pure returns (uint256 totalBP_) {
        for (uint256 i; i < _simplePolicy.commissionBasisPoints.length; i++) {
            totalBP_ += _simplePolicy.commissionBasisPoints[i];
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
        uint256 defaultFeeScheduleTotalBP = defaultInitSaleFee;
        uint16 makerBP = 10;
        nayms.replaceMakerBP(makerBP);

        uint256 sellAmount = 1 ether;
        uint256 buyAmount = 0.5 ether;

        changePrank(sm.addr);
        nayms.assignRole(acc2.id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.startTokenSale(acc1.entityId, sellAmount, sellAmount);

        fundEntityWeth(acc2, sellAmount);

        nayms.executeLimitOffer(wethId, buyAmount, acc1.entityId, buyAmount);

        (uint256 totalFees_, uint256 totalBP_) = nayms.calculateTradingFees(acc2.entityId, wethId, acc1.entityId, buyAmount);

        assertEq(defaultFeeScheduleTotalBP + makerBP, totalBP_, "total BP is incorrect");

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), buyAmount + ((buyAmount * makerBP) / LC.BP_FACTOR), "makers's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), (sellAmount - buyAmount - totalFees_), "taker's weth balance is incorrect");
    }

    function test_startTokenSale_FirstTokenSale() public {
        // acc1 is the par token seller (maker)
        // acc2 is the par token buyer (taker)

        uint256 saleAmount = 1 ether;
        uint256 buyAmount = 0.5 ether;

        changePrank(sm.addr);
        nayms.assignRole(acc2.id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.startTokenSale(acc1.entityId, saleAmount, saleAmount);

        assertEq(nayms.internalBalanceOf(acc1.entityId, acc1.entityId), saleAmount, "maker balance is incorrect");

        changePrank(acc1.addr);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.internalTransferFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, acc1.entityId, 1);

        fundEntityWeth(acc2, saleAmount);

        nayms.executeLimitOffer(wethId, buyAmount, acc1.entityId, buyAmount);

        (, uint16[] memory basisPoints) = nayms.getFeeSchedule(acc1.entityId, LC.FEE_TYPE_INITIAL_SALE);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), buyAmount, "maker's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), buyAmount, "taker's par token (acc1.entityId) balance is incorrect");

        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (buyAmount * basisPoints[0]) / LC.BP_FACTOR;
        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), buyAmount - commission, "entity's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId), commission, "nayms ltd weth balance is incorrect");
    }

    function test_overrideDefaultFeeSchedule() public {
        // acc1 is the par token seller (maker)
        // acc2 is the par token buyer (taker)

        uint256 saleAmount = 1 ether;
        uint256 buyAmount = 0.5 ether;

        changePrank(sm.addr);
        nayms.assignRole(acc2.id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.startTokenSale(acc1.entityId, saleAmount, saleAmount);

        assertEq(nayms.internalBalanceOf(acc1.entityId, acc1.entityId), saleAmount, "maker balance is incorrect");

        uint16 customFee = 50;
        changePrank(sa.addr);
        nayms.addFeeSchedule(acc2.entityId, LC.FEE_TYPE_INITIAL_SALE, b32Array1(NAYMS_LTD_IDENTIFIER), u16Array1(customFee));

        fundEntityWeth(acc2, saleAmount);
        nayms.executeLimitOffer(wethId, buyAmount, acc1.entityId, buyAmount);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), buyAmount, "maker's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), buyAmount, "taker's par token (acc1.entityId) balance is incorrect");

        uint256 commission = (buyAmount * customFee) / LC.BP_FACTOR;

        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), buyAmount - commission, "entity's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId), commission, "nayms ltd weth balance is incorrect");
    }

    function test_startTokenSale_PlaceOrderBeforeStartTokenSale() public {
        changePrank(sm.addr);
        nayms.assignRole(acc2.id, systemContext, LC.ROLE_ENTITY_CP);

        fundEntityWeth(acc2, 1 ether);

        nayms.executeLimitOffer(wethId, 0.5 ether, acc1.entityId, 0.5 ether);

        changePrank(sm.addr);
        nayms.startTokenSale(acc1.entityId, 1 ether, 1 ether);

        (, uint16[] memory basisPoints) = nayms.getFeeSchedule(acc1.entityId, LC.FEE_TYPE_INITIAL_SALE);

        assertEq(nayms.internalBalanceOf(acc1.entityId, wethId), 0.5 ether, "par token seller's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(acc2.entityId, acc1.entityId), 0.5 ether, "par token buyer's par token (acc1.entityId) balance is incorrect");

        uint256 halfEther = 0.5 ether;

        // For FIRST_OFFER, the commission should be paid by the buyer of the par tokens
        uint256 commission = (halfEther * basisPoints[0]) / LC.BP_FACTOR;

        assertEq(nayms.internalBalanceOf(acc2.entityId, wethId), 0.5 ether - commission, "par token buyer's weth balance is incorrect");
        assertEq(nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId), commission, "nayms ltd weth balance is incorrect");
    }

    function test_startTokenSale_StartingWithMultipleExecuteLimitOffers() public {
        uint256 totalAmount = 2 ether;
        uint256 singleOrderAmount = 0.5 ether;
        uint256 singleSaleAmount = 1 ether;

        uint256 defaultTotalBP = defaultInitSaleFee;
        changePrank(sm.addr);
        nayms.assignRole(acc2.id, systemContext, LC.ROLE_ENTITY_CP);

        fundEntityWeth(acc2, totalAmount + ((totalAmount * defaultTotalBP) / LC.BP_FACTOR));

        changePrank(acc2.addr);
        nayms.executeLimitOffer(wethId, singleOrderAmount, acc1.entityId, singleOrderAmount);
        nayms.executeLimitOffer(wethId, singleOrderAmount, acc1.entityId, singleOrderAmount);

        changePrank(sm.addr);
        nayms.startTokenSale(acc1.entityId, singleSaleAmount, singleSaleAmount);
        changePrank(acc2.addr);
        nayms.executeLimitOffer(wethId, singleOrderAmount, acc1.entityId, singleOrderAmount);

        changePrank(systemAdmin);
        nayms.assignRole(acc3.id, systemContext, LC.ROLE_SYSTEM_MANAGER);

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

        changePrank(sm.addr);
        nayms.assignRole(acc2.id, systemContext, LC.ROLE_ENTITY_CP);

        uint256 saleAmount = 1 ether;
        nayms.startTokenSale(acc1.entityId, saleAmount, saleAmount);
        assertEq(nayms.internalBalanceOf(acc1.entityId, acc1.entityId), saleAmount, "entity selling par balance is incorrect");

        changePrank(sa.addr);
        nayms.addFeeSchedule(acc2.entityId, LC.FEE_TYPE_INITIAL_SALE, b32Array1(NAYMS_LTD_IDENTIFIER), u16Array1(0));

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
