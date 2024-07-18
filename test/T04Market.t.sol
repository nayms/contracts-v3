// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { D03ProtocolDefaults, LibHelpers, LibObject, LC, c } from "./defaults/D03ProtocolDefaults.sol";
import { Vm } from "forge-std/Vm.sol";
import { StdStyle } from "forge-std/Test.sol";
import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { Entity, MarketInfo, FeeSchedule, SimplePolicy, Stakeholders, CalculatedFees } from "src/shared/FreeStructs.sol";

import { StdStyle } from "forge-std/StdStyle.sol";

/* 
    Terminology:
    wethId: bytes32 ID of WETH
    nENTITYx: bytes32 ID of entityx when referring to entityx's token (nENTITYx == entityx)
    entityx: bytes32 ID of entity
    nEntity0: nEntity0 == DEFAULT_ACCOUNT0_ENTITY_ID
*/

struct TestInfo {
    uint256 entity1StartingBal;
    uint256 entity2StartingBal;
    uint256 entity3StartingBal;
    uint256 entity1ExternalDepositAmt;
    uint256 entity2ExternalDepositAmt;
    uint256 entity3ExternalDepositAmt;
    uint256 entity1MintAndSaleAmt;
    uint256 entity2MintAndSaleAmt;
    uint256 entity3MintAndSaleAmt;
    uint256 entity1SalePrice;
    uint256 entity2SalePrice;
    uint256 entity3SalePrice;
}

contract T04MarketTest is D03ProtocolDefaults, MockAccounts {
    using StdStyle for *;
    using LibHelpers for *;

    bytes32 internal dividendBankId;

    bytes32 internal entity1 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("e5"));
    bytes32 internal entity2 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("e6"));
    bytes32 internal entity3 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("e7"));
    bytes32 internal entity4 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("e8"));

    uint256 internal constant testBalance = 100_000 ether;

    uint256 internal constant dividendAmount = 1000;

    uint256 internal constant collateralRatio_500 = 5000;
    uint256 internal constant maxCapital_2000eth = 2_000 ether;
    uint256 internal constant maxCapital_3000eth = 3_000 ether;
    uint256 internal constant totalLimit_2000eth = 2_000 ether;

    bytes32 public testPolicyDataHash = "test";

    TestInfo public dt =
        TestInfo({
            entity1StartingBal: 10_000 ether,
            entity2StartingBal: 10_000 ether,
            entity3StartingBal: 10_000 ether,
            entity1ExternalDepositAmt: 1_000 ether,
            entity2ExternalDepositAmt: 2_000 ether,
            entity3ExternalDepositAmt: 3_000 ether,
            entity1MintAndSaleAmt: 1_000 ether,
            entity2MintAndSaleAmt: 1_000 ether,
            entity3MintAndSaleAmt: 1_500 ether,
            entity1SalePrice: 1_000 ether,
            entity2SalePrice: 1_000 ether,
            entity3SalePrice: 1_000 ether
        });

    function setUp() public {
        // whitelist WBTC as well
        nayms.addSupportedExternalToken(wbtcAddress, 1e13);

        dividendBankId = LibHelpers._stringToBytes32(LC.DIVIDEND_BANK_IDENTIFIER);
    }

    function testStartTokenSale() public {
        changePrank(sm.addr);
        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        // mint weth for account0
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, dt.entity1StartingBal);

        // note: when using writeTokenBalance, this does not update the total supply!
        // assertEq(weth.totalSupply(), naymsAddress, 10_000, "weth total supply after mint should INCREASE (mint)");

        nayms.externalDeposit(wethAddress, dt.entity1ExternalDepositAmt);
        // deposit into nayms vaults
        // note: the entity creator can deposit funds into an entity

        changePrank(signer1);
        writeTokenBalance(signer1, naymsAddress, wethAddress, dt.entity1StartingBal);
        nayms.externalDeposit(wethAddress, dt.entity1ExternalDepositAmt);

        changePrank(sm.addr);
        nayms.enableEntityTokenization(entity1, "e1token", "e1token", 1e6);

        // start a token sale: sell entity tokens for nWETH
        // when a token sale starts: entity tokens are minted to the entity,
        // 2nd param is the sell amount, 3rd param is the buy amount
        vm.recordLogs();
        // putting an offer on behalf of entity1 to sell their nENTITY1 for the entity's associated asset
        // 500 nENTITY1 for 500 WETH, 1:1 ratio
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 3, "InternalTokenSupplyUpdate: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("InternalTokenSupplyUpdate(bytes32,uint256,string,address)"), "InternalTokenSupplyUpdate: Invalid event signature");
        assertEq(entries[0].topics[1], entity1, "InternalTokenSupplyUpdate: incorrect tokenID"); // assert entity token
        assertEq(abi.decode(LibHelpers._bytes32ToBytes(entries[0].topics[2]), (address)), sm.addr, "InternalTokenSupplyUpdate: Invalid sender address");
        (uint256 newSupply, string memory fName) = abi.decode(entries[0].data, (uint256, string));
        assertEq(fName, "_internalMint", "InternalTokenSupplyUpdate: invalid function name");
        assertEq(newSupply, dt.entity1MintAndSaleAmt, "InternalTokenSupplyUpdate: invalid token supply");

        assertEq(entries[1].topics.length, 3, "InternalTokenBalanceUpdate: topics length incorrect");
        assertEq(entries[1].topics[0], keccak256("InternalTokenBalanceUpdate(bytes32,bytes32,uint256,string,address)"), "InternalTokenBalanceUpdate: Invalid event signature");
        assertEq(entries[1].topics[1], entity1, "InternalTokenBalanceUpdate: incorrect tokenID"); // assert entity token
        assertEq(abi.decode(LibHelpers._bytes32ToBytes(entries[0].topics[2]), (address)), sm.addr, "InternalTokenBalanceUpdate: Invalid sender address");
        (bytes32 tokenId, uint256 newSupply2, string memory fName2) = abi.decode(entries[1].data, (bytes32, uint256, string));
        assertEq(fName2, "_internalMint", "InternalTokenBalanceUpdate: invalid function name");
        assertEq(tokenId, entity1, "InternalTokenBalanceUpdate: invalid token");
        assertEq(newSupply2, dt.entity1MintAndSaleAmt, "InternalTokenBalanceUpdate: invalid balance");

        assertEq(entries[2].topics.length, 4, "OrderAdded: topics length incorrect");
        assertEq(entries[2].topics[0], keccak256("OrderAdded(uint256,bytes32,bytes32,uint256,uint256,bytes32,uint256,uint256,uint256)"), "OrderAdded: Invalid event signature");
        assertEq(abi.decode(LibHelpers._bytes32ToBytes(entries[2].topics[1]), (uint256)), nayms.getLastOfferId(), "OrderAdded: invalid offerId"); // assert offerId
        assertEq(entries[2].topics[2], entity1, "OrderAdded: invalid maker"); // assert maker
        assertEq(entries[2].topics[3], entity1, "OrderAdded: invalid sell token"); // assert entity token

        (uint256 sellAmount, uint256 sellAmountInitial, bytes32 buyToken, uint256 buyAmount, uint256 buyAmountInitial, uint256 state) = abi.decode(
            entries[2].data,
            (uint256, uint256, bytes32, uint256, uint256, uint256)
        );

        assertEq(sellAmount, dt.entity1MintAndSaleAmt, "OrderAdded: invalid sell amount");
        assertEq(sellAmountInitial, dt.entity1MintAndSaleAmt, "OrderAdded: invalid initial sell amount");
        assertEq(buyToken, wethId, "OrderAdded: invalid buy token");
        assertEq(buyAmount, dt.entity1SalePrice, "OrderAdded: invalid buy amount");
        assertEq(buyAmountInitial, dt.entity1SalePrice, "OrderAdded: invalid initial buy amount");
        assertEq(state, LC.OFFER_STATE_ACTIVE, "OrderAdded: invalid offer state");

        assertEq(entries[3].topics.length, 2, "TokenSaleStarted: topics length incorrect");
        assertEq(entries[3].topics[0], keccak256("TokenSaleStarted(bytes32,uint256,string,string)"));
        assertEq(entries[3].topics[1], entity1, "TokenSaleStarted: incorrect entity"); // assert entity
        (uint256 offerId, string memory tokenSymbol, string memory tokenName) = abi.decode(entries[3].data, (uint256, string, string));
        assertEq(offerId, nayms.getLastOfferId(), "TokenSaleStarted: invalid offerId");
        assertEq(tokenSymbol, "e1token", "TokenSaleStarted: invalid token symbol");
        assertEq(tokenName, "e1token", "TokenSaleStarted: invalid token name");

        // note: the token balance for sale is not escrowed in the marketplace anymore, instead we keep track of another balance (user's tokens for sale)
        // in order to ensure a user cannot transfer the token balance that they have for sale
        assertEq(nayms.internalBalanceOf(entity1, entity1), 0 + dt.entity1MintAndSaleAmt, "entity1 internalTokenSupply after startTokenSale should INCREASE (mint)");
        assertEq(nayms.internalTokenSupply(entity1), 0 + dt.entity1MintAndSaleAmt, "nEntity1 total supply after startTokenSale should INCREASE (mint)");

        // assertEq(nayms.getLastOfferId(), nayms.getLastOfferId() - 1, "lastOfferId after startTokenSale should INCREASE");

        MarketInfo memory marketInfo1 = nayms.getOffer(nayms.getLastOfferId());
        assertEq(marketInfo1.creator, entity1);
        assertEq(marketInfo1.sellToken, entity1);
        assertEq(marketInfo1.sellAmount, dt.entity1MintAndSaleAmt);
        assertEq(marketInfo1.sellAmountInitial, dt.entity1MintAndSaleAmt);
        assertEq(marketInfo1.buyToken, wethId);
        assertEq(marketInfo1.buyAmount, dt.entity1SalePrice);
        assertEq(marketInfo1.buyAmountInitial, dt.entity1SalePrice);
        assertEq(marketInfo1.state, LC.OFFER_STATE_ACTIVE);

        // a user should NOT be able to transfer / withdraw their tokens for sale
        // transfer to invalid entity check?
        assertEq(nayms.getLockedBalance(entity1, entity1), dt.entity1MintAndSaleAmt, "entity1 nEntity1 balance of tokens for sale should INCREASE (lock)");

        // try transferring nEntity1 from entity1 to entity0 - this should REVERT!
        changePrank(signer1);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.internalTransferFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, entity1, 1);

        assertTrue(nayms.isActiveOffer(nayms.getLastOfferId()), "Token sale offer should be active");

        // Change signer back to system admin for the other tests that call this test first
        changePrank(systemAdmin);
    }

    function testCommissionsPaid() public {
        testStartTokenSale();

        // scenario where marketplace fee strat is (% external tokens bought or sold)
        // 0.15% to nayms
        // 0.075% to ndf
        // 0.075% to stm

        bytes32[] memory customReceivers = b32Array3(NAYMS_LTD_IDENTIFIER, NDF_IDENTIFIER, STM_IDENTIFIER);
        uint16[] memory customBasisPoints = u16Array3(150, 75, 75);

        nayms.addFeeSchedule(LC.DEFAULT_FEE_SCHEDULE, LC.FEE_TYPE_INITIAL_SALE, customReceivers, customBasisPoints);
        nayms.addFeeSchedule(LC.DEFAULT_FEE_SCHEDULE, LC.FEE_TYPE_TRADING, customReceivers, customBasisPoints);

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer3Id, systemContext, LC.ROLE_ENTITY_CP);

        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        nayms.createEntity(entity3, signer3Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, dt.entity2ExternalDepositAmt);
        nayms.externalDeposit(wethAddress, dt.entity2ExternalDepositAmt);

        changePrank(signer3);
        writeTokenBalance(signer3, naymsAddress, wethAddress, dt.entity3ExternalDepositAmt);
        nayms.externalDeposit(wethAddress, dt.entity3ExternalDepositAmt);

        uint256 naymsBalanceBeforeTrade = nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId);

        uint256 lastOfferId = nayms.getLastOfferId();

        changePrank(signer2);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);
        assertEq(nayms.getLastOfferId(), lastOfferId + 1, "lastOfferId should INCREASE after executeLimitOffer");

        assertEq(nayms.internalBalanceOf(entity1, wethId), dt.entity1ExternalDepositAmt + dt.entity1MintAndSaleAmt, "Maker should not pay commissions");

        // assert trading commissions paid
        uint256 totalFees = (dt.entity1MintAndSaleAmt * 300) / LC.BP_FACTOR;
        assertEq(nayms.internalBalanceOf(entity2, wethId), dt.entity2ExternalDepositAmt - dt.entity1MintAndSaleAmt - totalFees, "Taker should pay commissions");

        uint256 naymsBalanceAfterTrade = naymsBalanceBeforeTrade + ((dt.entity1MintAndSaleAmt * customBasisPoints[0]) / LC.BP_FACTOR);
        uint256 ndfBalanceAfterTrade = naymsBalanceBeforeTrade + ((dt.entity1MintAndSaleAmt * customBasisPoints[1]) / LC.BP_FACTOR);
        uint256 stmBalanceAfterTrade = naymsBalanceBeforeTrade + ((dt.entity1MintAndSaleAmt * customBasisPoints[2]) / LC.BP_FACTOR);
        assertEq(nayms.internalBalanceOf(NAYMS_LTD_IDENTIFIER, wethId), naymsBalanceAfterTrade, "Nayms should receive half of trading commissions");
        assertEq(nayms.internalBalanceOf(NDF_IDENTIFIER, wethId), ndfBalanceAfterTrade, "NDF should get a trading commission");
        assertEq(nayms.internalBalanceOf(STM_IDENTIFIER, wethId), stmBalanceAfterTrade, "Staking mechanism should get a trading commission");

        // assert Entity1 holds `buyAmount` of nE1
        assertEq(nayms.internalBalanceOf(entity2, entity1), dt.entity1MintAndSaleAmt);

        // test commission paid by taker on "secondary market"
        uint256 e2WethBeforeTrade = nayms.internalBalanceOf(entity2, wethId); // 9.7e20
        uint256 e3WethBeforeTrade = nayms.internalBalanceOf(entity3, wethId); // 3e21

        changePrank(signer2);
        nayms.executeLimitOffer(entity1, dt.entity1MintAndSaleAmt, wethId, dt.entity1MintAndSaleAmt); // 1e21

        changePrank(signer3);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        (uint256 totalFees_, ) = nayms.calculateTradingFees(entity3, wethId, entity1, dt.entity1MintAndSaleAmt);
        assertEq(nayms.internalBalanceOf(entity2, wethId), e2WethBeforeTrade + dt.entity1MintAndSaleAmt, "Maker pays no commissions, on secondary market");
        assertEq(nayms.internalBalanceOf(entity3, wethId), e3WethBeforeTrade - dt.entity1MintAndSaleAmt - totalFees_, "Taker should pay commissions, on secondary market");

        // Use a custom fee schedule for entity3 (taker)
        // prettier-ignore
        bytes32[] memory receivers = b32Array3(
            keccak256("RANDOM FEE RECEIVER"),
            keccak256("RANDOM FEE RECEIVER 2"),
            keccak256("RANDOM FEE RECEIVER 3"));
        uint16[] memory basisPoints = u16Array3(150, 75, 75);

        changePrank(systemAdmin);
        nayms.addFeeSchedule(entity2, LC.FEE_TYPE_TRADING, receivers, basisPoints);

        // Signer3 place an order with to sell the par tokens purchased from signer1
        changePrank(signer3);
        nayms.executeLimitOffer(entity1, dt.entity1MintAndSaleAmt, wethId, dt.entity1MintAndSaleAmt);

        changePrank(signer2);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);
    }

    function testMatchMakerPriceWithTakerBuyAmount() public {
        testStartTokenSale(); // sell 1000 e1token for 1000 WETH

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);

        // init and fund taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");

        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, 2_000 ether);
        nayms.externalDeposit(wethAddress, 2_000 ether);

        nayms.executeLimitOffer(wethId, 1_000 ether, entity1, 500 ether);
        vm.stopPrank();

        assertEq(nayms.internalBalanceOf(entity2, entity1), 500 ether, "should match takers buy amount, not sell amount");

        uint256 offerId = nayms.getLastOfferId();
        MarketInfo memory offer = nayms.getOffer(offerId);
        assertEq(offer.state, LC.OFFER_STATE_FULFILLED, "offer should be closed");
    }

    function testCancelOffer() public {
        testStartTokenSale();

        changePrank(sm.addr);
        nayms.assignRole(signer3Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_ENTITY_CP);

        changePrank(signer3);
        uint256 lastOfferId = nayms.getLastOfferId();
        vm.expectRevert("only member of entity can cancel");
        nayms.cancelOffer(lastOfferId);

        vm.recordLogs();

        changePrank(signer1);
        nayms.cancelOffer(nayms.getLastOfferId());

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 3, "OrderCancelled: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("OrderCancelled(uint256,bytes32,bytes32)"), "OrderCancelled: Invalid event signature");
        assertEq(abi.decode(LibHelpers._bytes32ToBytes(entries[0].topics[1]), (uint256)), nayms.getLastOfferId(), "OrderCancelled: incorrect order ID"); // assert entity token
        assertEq(entries[0].topics[2], entity1, "OrderCancelled: incorrect taker ID"); // assert entity token

        bytes32 sellToken = abi.decode(entries[0].data, (bytes32));

        assertEq(sellToken, entity1, "OrderCancelled: invalid sell token");

        lastOfferId = nayms.getLastOfferId();
        vm.expectRevert("offer not active");
        nayms.cancelOffer(lastOfferId + 1);

        MarketInfo memory offer = nayms.getOffer(nayms.getLastOfferId());
        assertEq(offer.rankNext, 0, "Next sibling not blank");
        assertEq(offer.rankPrev, 0, "Prevoius sibling not blank");
        assertEq(offer.state, LC.OFFER_STATE_CANCELLED, "offer state != Cancelled");
    }

    function testFuzzMatchingOffers(uint256 saleAmount, uint256 salePrice) public {
        // avoid over/underflow issues
        vm.assume(1_000 < saleAmount && saleAmount < type(uint128).max);
        vm.assume(1_000 < salePrice && salePrice < type(uint128).max);

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, salePrice, true), "test");
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, salePrice, true), "test");

        // init test funds to maxint
        writeTokenBalance(account0, naymsAddress, wethAddress, ~uint256(0));
        nayms.enableEntityTokenization(entity1, "e1token", "e1token", 1);

        if (saleAmount == 0) {
            vm.expectRevert("mint amount must be > 0");
            nayms.startTokenSale(entity1, saleAmount, salePrice);
        } else if (salePrice == 0) {
            vm.expectRevert("_internalMint: mint zero tokens");
            nayms.externalDeposit(wethAddress, salePrice);
        } else {
            (, uint256 totalBP_) = nayms.calculateTradingFees(entity2, wethId, entity1, saleAmount);
            uint256 e2Balance = (salePrice * (LC.BP_FACTOR + totalBP_)) / LC.BP_FACTOR;

            changePrank(signer2);
            writeTokenBalance(signer2, naymsAddress, wethAddress, e2Balance);
            nayms.externalDeposit(wethAddress, e2Balance);

            changePrank(sm.addr);

            // sell x nENTITY1 for y WETH
            nayms.startTokenSale(entity1, saleAmount, salePrice);

            MarketInfo memory marketInfo1 = nayms.getOffer(nayms.getLastOfferId());
            assertEq(marketInfo1.creator, entity1, "creator");
            assertEq(marketInfo1.sellToken, entity1, "sell token");
            assertEq(marketInfo1.sellAmount, saleAmount, "sell amount");
            assertEq(marketInfo1.sellAmountInitial, saleAmount, "sell amount initial");
            assertEq(marketInfo1.buyToken, wethId, "buy token");
            assertEq(marketInfo1.buyAmount, salePrice, "buy amount");
            assertEq(marketInfo1.buyAmountInitial, salePrice, "buy amount initial");
            assertEq(marketInfo1.state, LC.OFFER_STATE_ACTIVE, "state");

            changePrank(signer2);
            nayms.executeLimitOffer(wethId, salePrice, entity1, saleAmount);

            assertOfferFilled(nayms.getLastOfferId() - 1, entity1, entity1, saleAmount, wethId, salePrice);
        }
    }

    function testFuzzMatchingSellOffer(uint256 saleAmount, uint256 salePrice) public {
        // avoid over/underflow issues
        vm.assume(1_000 < saleAmount && saleAmount < type(uint128).max);
        vm.assume(1_000 < salePrice && salePrice < type(uint128).max);

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, salePrice, true), "test");
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, salePrice, true), "test");

        // init test funds to maxint
        nayms.enableEntityTokenization(entity1, "e1token", "e1token", 1);
        changePrank(signer1);
        writeTokenBalance(signer1, naymsAddress, wethAddress, ~uint256(0));

        if (saleAmount == 0) {
            vm.expectRevert("mint amount must be > 0");
            nayms.startTokenSale(entity1, saleAmount, salePrice);
        } else if (salePrice == 0) {
            vm.expectRevert("_internalMint: mint zero tokens");
            nayms.externalDeposit(wethAddress, salePrice);
        } else {
            changePrank(signer2);
            writeTokenBalance(signer2, naymsAddress, wethAddress, salePrice);
            nayms.externalDeposit(wethAddress, salePrice);
            assertEq(nayms.internalBalanceOf(entity2, LibHelpers._getIdForAddress(wethAddress)), salePrice, "Entity2: invalid balance");

            // buy x nENTITY1 for y WETH

            nayms.executeLimitOffer(wethId, salePrice, entity1, saleAmount);

            // the BUYER of the first time par tokens needs balance for trading fees
            (uint256 totalFees_, ) = nayms.calculateTradingFees(entity2, wethId, entity1, saleAmount);
            uint256 feeAmount = salePrice + totalFees_;
            writeTokenBalance(signer2, naymsAddress, wethAddress, feeAmount);
            nayms.externalDeposit(wethAddress, feeAmount);

            assertEq(nayms.internalBalanceOf(entity2, LibHelpers._getIdForAddress(wethAddress)), salePrice + feeAmount, "Entity2: invalid balance");

            changePrank(sm.addr);
            // note: entity2 pays for the trading fees since this is a first time par token sale by entity1,

            // sell x nENTITY1 for y WETH
            nayms.startTokenSale(entity1, saleAmount, salePrice);

            assertOfferFilled(nayms.getLastOfferId() - 1, entity2, wethId, salePrice, entity1, saleAmount);
            assertOfferFilled(nayms.getLastOfferId(), entity1, entity1, saleAmount, wethId, salePrice);
        }
    }

    function testUserCannotTransferFundsLockedInAnOffer() public {
        testStartTokenSale();

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        // fund taker entity
        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, 1_000 ether);
        nayms.externalDeposit(wethAddress, 1_000 ether);

        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 200 ether, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("_internalBurn: insufficient balance available, funds locked");
        nayms.externalWithdrawFromEntity(entity2, signer2, wethAddress, 500 ether);

        uint256 lastOfferId = nayms.getLastOfferId();

        nayms.cancelOffer(lastOfferId);
        MarketInfo memory offer = nayms.getOffer(lastOfferId);
        assertEq(offer.state, LC.OFFER_STATE_CANCELLED);

        nayms.externalWithdrawFromEntity(entity2, signer2, wethAddress, 500 ether);
        uint256 balanceAfterWithdraw = nayms.internalBalanceOf(entity2, wethId);
        assertEq(balanceAfterWithdraw, 500 ether);
    }

    function testGetBestOfferId() public {
        assertEq(nayms.getBestOfferId(wethId, entity1), 0, "invalid best offer, when no offer exists");

        testStartTokenSale();

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer3Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer4Id, systemContext, LC.ROLE_ENTITY_CP);

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity4, signer4Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        // fund taker entity
        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, 1_000 ether);
        nayms.externalDeposit(wethAddress, 1_000 ether);
        vm.stopPrank();

        vm.startPrank(signer3);
        writeTokenBalance(signer3, naymsAddress, wethAddress, 1_000 ether);
        nayms.externalDeposit(wethAddress, 1_000 ether);
        vm.stopPrank();

        vm.startPrank(signer4);
        writeTokenBalance(signer4, naymsAddress, wethAddress, 1_000 ether);
        nayms.externalDeposit(wethAddress, 1_000 ether);
        vm.stopPrank();

        vm.startPrank(signer2);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 200 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        vm.startPrank(signer3);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 150 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();
        // last offer at this point will be the actual best offer
        uint256 bestOfferID = nayms.getLastOfferId();

        vm.startPrank(signer4);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 190 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        // confirm best offer
        assertEq(bestOfferID, nayms.getBestOfferId(wethId, entity1), "Not the best offer");
    }

    function testOfferValidation() public {
        testStartTokenSale();

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer3Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer4Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(account9._getIdForAddress(), systemContext, LC.ROLE_ENTITY_CP);

        changePrank(account9);
        vm.expectRevert("offer must be made by an existing entity");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        // init taker entity
        changePrank(sm.addr);

        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, 1_000 ether);

        nayms.externalDeposit(wethAddress, 1_000 ether);

        vm.expectRevert("sell amount exceeds uint128 limit");
        nayms.executeLimitOffer(wethId, 2 ** 128 + 1000, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy amount exceeds uint128 limit");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, 2 ** 128 + 1000);

        vm.expectRevert("sell amount must be >0");
        nayms.executeLimitOffer(wethId, 0, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy amount must be >0");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, 0);

        vm.expectRevert("sell token must be valid");
        nayms.executeLimitOffer("", dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy token must be valid");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, "", dt.entity1MintAndSaleAmt);

        vm.expectRevert("must trade external token"); // 2 p-tokens
        nayms.executeLimitOffer(entity1, dt.entity1MintAndSaleAmt, entity2, dt.entity1MintAndSaleAmt);

        vm.expectRevert("cannot sell and buy same token");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, wethId, dt.entity1MintAndSaleAmt);

        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 10 ether, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("insufficient balance available, funds locked");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        uint256 lastOfferId = nayms.getLastOfferId();
        nayms.cancelOffer(lastOfferId);

        changePrank(sm.addr);
        nayms.enableEntityTokenization(entity2, "e2token", "e2token", 1e6);
        nayms.startTokenSale(entity2, dt.entity2MintAndSaleAmt, dt.entity2SalePrice);

        vm.stopPrank();
    }

    function testMatchingExternalTokenOnSellSide() public {
        writeTokenBalance(account0, naymsAddress, wethAddress, dt.entity1StartingBal);

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);

        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        nayms.enableEntityTokenization(entity1, "e1token", "e1token", 1e6);

        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);

        // create (x2) counter offer
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, dt.entity2ExternalDepositAmt * 2);
        nayms.externalDeposit(wethAddress, dt.entity2ExternalDepositAmt * 2);

        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt * 2, entity1, dt.entity1MintAndSaleAmt * 2);

        assertOfferPartiallyFilled(
            nayms.getLastOfferId(),
            entity2,
            wethId,
            dt.entity1MintAndSaleAmt,
            dt.entity1MintAndSaleAmt * 2,
            entity1,
            dt.entity1MintAndSaleAmt,
            dt.entity1MintAndSaleAmt * 2
        );

        changePrank(sm.addr);
        // start another nENTITY1 token sale
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);

        assertOfferFilled(nayms.getLastOfferId() - 2, entity1, entity1, dt.entity1MintAndSaleAmt, wethId, dt.entity1SalePrice);
        assertOfferFilled(nayms.getLastOfferId() - 1, entity2, wethId, dt.entity1MintAndSaleAmt * 2, entity1, dt.entity1SalePrice * 2);
        assertOfferFilled(nayms.getLastOfferId(), entity1, entity1, dt.entity1MintAndSaleAmt, wethId, dt.entity1SalePrice);
    }

    function testSecondaryTradeWithBetterThanAskPrice() public {
        uint256 tokenAmount = 1000 ether;

        writeTokenBalance(account0, naymsAddress, wethAddress, dt.entity1StartingBal);

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);

        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        nayms.enableEntityTokenization(entity1, "e1token", "e1token", 1e13);

        // SELL: P 1000 / E 1000  (price = 1)
        nayms.startTokenSale(entity1, tokenAmount, tokenAmount);

        // create two counter offers
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, dt.entity2ExternalDepositAmt * 6);
        nayms.externalDeposit(wethAddress, dt.entity2ExternalDepositAmt * 6);

        // BUY: P 1000 / E 1000  (price = 1)
        nayms.executeLimitOffer(wethId, tokenAmount * 1, entity1, tokenAmount * 1);
        assertOfferFilled(1, entity1, entity1, tokenAmount, wethId, tokenAmount);
        assertOfferFilled(2, entity2, wethId, tokenAmount, entity1, tokenAmount);

        // BUY: P 1000 / E 5000 (price = 5)
        nayms.executeLimitOffer(wethId, tokenAmount * 5, entity1, tokenAmount * 1);

        // SELL: P 2000 / E 2000 (price = 1)
        changePrank(sm.addr);
        nayms.startTokenSale(entity1, tokenAmount * 2, tokenAmount * 2);
        assertOfferFilled(3, entity2, wethId, tokenAmount * 5, entity1, tokenAmount);
        assertOfferPartiallyFilled(4, entity1, entity1, tokenAmount, tokenAmount * 2, wethId, tokenAmount, tokenAmount * 2);

        // logOfferDetails(1); // should be filled 100%
        // logOfferDetails(2); // should be filled 100%
        // logOfferDetails(3); // should be filled 100%
        // logOfferDetails(4); // should be filled 50%
    }

    function testBestOffersWithCancel() public {
        testStartTokenSale();

        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer3Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer4Id, systemContext, LC.ROLE_ENTITY_CP);

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity4, signer4Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        // fund taker entity
        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, 1_000 ether);
        nayms.externalDeposit(wethAddress, 1_000 ether);
        vm.stopPrank();

        vm.startPrank(signer3);
        writeTokenBalance(signer3, naymsAddress, wethAddress, 1_000 ether);
        nayms.externalDeposit(wethAddress, 1_000 ether);
        vm.stopPrank();

        vm.startPrank(signer4);
        writeTokenBalance(signer4, naymsAddress, wethAddress, 1_000 ether);
        nayms.externalDeposit(wethAddress, 1_000 ether);
        vm.stopPrank();

        vm.startPrank(signer2);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 200 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        vm.startPrank(signer3);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 300 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        vm.startPrank(signer4);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 400 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        vm.startPrank(signer4);
        nayms.cancelOffer(nayms.getLastOfferId());
        vm.stopPrank();

        assertEq(nayms.getBestOfferId(wethId, entity1), nayms.getLastOfferId() - 2, "invalid best offer ID");

        vm.startPrank(signer2);
        nayms.cancelOffer(nayms.getLastOfferId() - 2);
        vm.stopPrank();

        assertEq(nayms.getBestOfferId(wethId, entity1), nayms.getLastOfferId() - 1, "invalid best offer ID");

        vm.startPrank(signer3);
        nayms.cancelOffer(nayms.getLastOfferId() - 1);
        vm.stopPrank();

        assertEq(nayms.getBestOfferId(wethId, entity1), 0, "invalid best offer ID");
    }

    function assertOfferFilled(uint256 offerId, bytes32 creator, bytes32 sellToken, uint256 initSellAmount, bytes32 buyToken, uint256 initBuyAmount) private {
        MarketInfo memory offer = nayms.getOffer(offerId);
        assertEq(offer.creator, creator, "offer creator invalid");
        assertEq(offer.sellToken, sellToken, "invalid sell token");
        assertEq(offer.sellAmount, 0, "invalid sell amount");
        assertEq(offer.sellAmountInitial, initSellAmount, "invalid initial sell amount");
        assertEq(offer.buyToken, buyToken, "invalid buy token");
        assertEq(offer.buyAmount, 0, "invalid buy amount");
        assertEq(offer.buyAmountInitial, initBuyAmount, "invalid initial buy amount");
        assertEq(offer.state, LC.OFFER_STATE_FULFILLED, "invalid state");
    }

    function assertOfferPartiallyFilled(
        uint256 offerId,
        bytes32 creator,
        bytes32 sellToken,
        uint256 sellAmount,
        uint256 initSellAmount,
        bytes32 buyToken,
        uint256 buyAmount,
        uint256 initBuyAmount
    ) private {
        MarketInfo memory marketInfo1 = nayms.getOffer(offerId);
        assertEq(marketInfo1.creator, creator, "offer creator invalid");
        assertEq(marketInfo1.sellToken, sellToken, "invalid sell token");
        assertEq(marketInfo1.sellAmount, sellAmount, "invalid sell amount");
        assertEq(marketInfo1.sellAmountInitial, initSellAmount, "invalid initial sell amount");
        assertEq(marketInfo1.buyToken, buyToken, "invalid buy token");
        assertEq(marketInfo1.buyAmount, buyAmount, "invalid buy amount");
        assertEq(marketInfo1.buyAmountInitial, initBuyAmount, "invalid initial buy amount");
        assertEq(marketInfo1.state, LC.OFFER_STATE_ACTIVE, "invalid state");
    }

    function testQSP2() public {
        // maker:   sell 2 WETH    buy 2 pToken   => price = 1    ETH/pToken
        // taker:   sell 2 pToken  buy 1 WETH     => price = 0.5  ETH/pToken

        uint256 e1balance = 5000;
        uint256 e2balance = 5000;

        uint256 offer1sell = 2000;
        uint256 offer1buy = 2000;
        uint256 offer2sell = 4000;
        uint256 offer2buy = 4000;
        uint256 offer3sell = 2000;
        uint256 offer3buy = 1000;

        // OFFER 1: 2000 pTokens -> 2000 WETH
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, e1balance);
        changePrank(sm.addr);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);

        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        nayms.enableEntityTokenization(entity1, "e1token", "e1token", 1);

        nayms.startTokenSale(entity1, offer1sell, offer1buy);

        // OFFER 2 (x2) counter offer: 4000 WETH -> 4000 pTokens
        // we have to do this as the protocol does not allow us to create an offer to buy pTokens before they are minted!
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, e2balance);
        nayms.externalDeposit(wethAddress, e2balance);
        nayms.executeLimitOffer(wethId, offer2sell, entity1, offer2buy);

        // half should match so we should be left with offer 2 partially matched
        // 2000 WETH -> 2000 pTokens
        assertOfferPartiallyFilled(nayms.getLastOfferId(), entity2, wethId, offer1buy, offer2sell, entity1, offer1sell, offer2buy);

        // OFFER 3: 2000 pTokens -> 1000 WETH
        changePrank(sm.addr);
        nayms.startTokenSale(entity1, offer3sell, offer3buy);

        assertOfferFilled(nayms.getLastOfferId() - 1, entity2, wethId, offer2sell, entity1, offer2buy);
        assertOfferFilled(nayms.getLastOfferId() - 2, entity1, entity1, offer1sell, wethId, offer1buy);
        assertOfferFilled(nayms.getLastOfferId(), entity1, entity1, offer3sell, wethId, offer3buy);
    }

    function testNotAbleToTradeWithLockedFunds() public {
        uint256 salePrice = 100 ether;
        uint256 saleAmount = 100 ether;

        bytes32 e1Id = DEFAULT_UNDERWRITER_ENTITY_ID;

        // init test funds to maxint
        writeTokenBalance(account0, naymsAddress, wethAddress, ~uint256(0));

        (, uint256 totalBP_) = nayms.calculateTradingFees(entity2, wethId, entity1, saleAmount);
        uint256 e2Balance = (salePrice * (LC.BP_FACTOR + totalBP_)) / LC.BP_FACTOR;

        changePrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, e2Balance);
        nayms.externalDeposit(wethAddress, e2Balance);

        // sell x nENTITY1 for y WETH
        changePrank(sm.addr);
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_ENTITY_CP);
        nayms.assignRole(signer2Id, systemContext, LC.ROLE_ENTITY_CP);

        nayms.enableEntityTokenization(e1Id, "e1token", "e1token", 1e6);
        nayms.startTokenSale(e1Id, saleAmount, salePrice);
        vm.stopPrank();

        vm.prank(signer2);
        nayms.executeLimitOffer(wethId, salePrice, e1Id, saleAmount);

        assertOfferFilled(nayms.getLastOfferId() - 1, e1Id, e1Id, saleAmount, wethId, salePrice);
        assertEq(nayms.internalBalanceOf(e1Id, wethId), saleAmount, "balance should have INCREASED"); // has 100 weth

        assertEq(nayms.getLockedBalance(e1Id, wethId), 0, "locked balance should be 0");

        bytes32 policyId1 = makeId(LC.OBJECT_TYPE_POLICY, bytes20("simple_policy1"));
        uint256 policyLimit = 85 ether;

        vm.startPrank(su.addr);
        (Stakeholders memory stakeholders, SimplePolicy memory policy) = initPolicyWithLimit(testPolicyDataHash, policyLimit);
        nayms.createSimplePolicy(policyId1, e1Id, stakeholders, policy, testPolicyDataHash);

        uint256 lockedBalance = nayms.getLockedBalance(e1Id, wethId);
        assertEq(lockedBalance, policyLimit, "locked balance should increase");

        vm.expectRevert("insufficient balance");
        changePrank(signer1);
        nayms.executeLimitOffer(e1Id, salePrice, wethId, saleAmount);
    }

    function testMessUpOrderSorting_IM24299() public {
        assertEq(nayms.getBestOfferId(usdcId, entity1), 0, "invalid best offer, when no offer exists");

        vm.startPrank(sm.addr);
        nayms.createEntity(entity1, signer1Id, initEntity(usdcId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        vm.stopPrank();

        // mint usdc for account0
        vm.startPrank(account0);
        writeTokenBalance(account0, naymsAddress, usdcAddress, dt.entity1StartingBal);
        nayms.externalDeposit(usdcAddress, dt.entity1ExternalDepositAmt);
        vm.stopPrank();

        // deposit into nayms vaults
        // note: the entity creator can deposit funds into an entity
        vm.startPrank(signer1);
        writeTokenBalance(signer1, naymsAddress, usdcAddress, dt.entity1StartingBal);
        nayms.externalDeposit(usdcAddress, dt.entity1ExternalDepositAmt);
        vm.stopPrank();

        vm.startPrank(sm.addr);
        nayms.enableEntityTokenization(entity1, "E1", "Entity1", 1);
        nayms.startTokenSale(entity1, 550, 550);

        // init entities
        nayms.createEntity(entity2, signer2Id, initEntity(usdcId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(usdcId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity4, signer4Id, initEntity(usdcId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        vm.stopPrank();

        // fund taker entity
        vm.startPrank(signer2); // honest user
        writeTokenBalance(signer2, naymsAddress, usdcAddress, 1 ether);
        nayms.externalDeposit(usdcAddress, 1 ether);
        vm.stopPrank();

        vm.startPrank(signer3); // attacker
        writeTokenBalance(signer3, naymsAddress, usdcAddress, 1 ether);
        nayms.externalDeposit(usdcAddress, 1 ether);
        vm.stopPrank();

        vm.startPrank(signer4); // another entity of attacker
        writeTokenBalance(signer4, naymsAddress, usdcAddress, 1 ether);
        nayms.externalDeposit(usdcAddress, 1 ether);
        vm.stopPrank();

        // unassign entity admin role
        vm.startPrank(sa.addr);
        hUnassignRole(signer2Id, entity2);
        hUnassignRole(signer3Id, entity3);
        hUnassignRole(signer4Id, entity4);
        vm.stopPrank();

        // assign entity cp role
        vm.startPrank(sm.addr);
        hAssignRole(signer2Id, entity2, LC.ROLE_ENTITY_CP);
        hAssignRole(signer3Id, entity3, LC.ROLE_ENTITY_CP);
        hAssignRole(signer4Id, entity4, LC.ROLE_ENTITY_CP);
        vm.stopPrank();

        // signer 2 & 3 take all the ptokens
        vm.startPrank(signer2);
        nayms.executeLimitOffer(usdcId, 200, entity1, 200); // it will be the best offer
        vm.stopPrank();

        vm.startPrank(signer3);
        nayms.executeLimitOffer(usdcId, 350, entity1, 350); // it will be the best offer
        vm.stopPrank();
        // logOfferDetails(nayms.getLastOfferId());

        vm.startPrank(signer2); //honest user's offer (sellAmount1, buyAmount1) = (200, 101)
        nayms.executeLimitOffer(entity1, 200, usdcId, 101); // it will be the best offer
        vm.stopPrank();
        // logOfferDetails(nayms.getLastOfferId());

        vm.startPrank(signer3); //attacker adds a better offer (sellAmount2, buyAmount2) = (200, 100)
        nayms.executeLimitOffer(entity1, 200, usdcId, 100); // it will be the best offer now
        vm.stopPrank();
        // logOfferDetails(nayms.getLastOfferId());

        // this one causes rounding isseue and is incorrectly added to the order book
        vm.startPrank(signer4);
        nayms.executeLimitOffer(usdcId, 100, entity1, 199);
        vm.stopPrank();
        // logOfferDetails(nayms.getLastOfferId());

        vm.startPrank(signer3);
        nayms.executeLimitOffer(entity1, 150, usdcId, 100);
        vm.stopPrank();
        // logOfferDetails(nayms.getLastOfferId());

        uint256 bestId = nayms.getBestOfferId(entity1, usdcId);
        uint256 prev1 = nayms.getOffer(bestId).rankPrev;
        uint256 prev2 = nayms.getOffer(prev1).rankPrev;

        // c.log(" --------- ".red());
        logOfferDetails(bestId);
        logOfferDetails(prev1);
        logOfferDetails(prev2);

        MarketInfo memory o1 = nayms.getOffer(bestId);
        MarketInfo memory o2 = nayms.getOffer(prev1);
        MarketInfo memory o3 = nayms.getOffer(prev2);

        uint256 price1 = (o1.buyAmountInitial * 1000) / o1.sellAmountInitial;
        uint256 price2 = (o2.buyAmountInitial * 1000) / o2.sellAmountInitial;
        uint256 price3 = (o3.buyAmountInitial * 1000) / o3.sellAmountInitial;

        require(price1 < price2, string.concat("best order incorrect: ", vm.toString(price1)));
        require(price2 < price3, string.concat("second best order incorrect: ", vm.toString(price2)));
    }

    function testDoubleLockedBalance_IM24430() public {
        /// when creating a policy, available balance is checked to be used for collateral,
        /// previously no check was being performed, to see if any part of the balance is locked already
        /// attack consists of placing an order to lock the available balance
        ///  and then creating a policy locking the same funds again

        uint256 usdc1000 = 1000e6;
        uint256 pToken100 = 100e18;
        // uint256 pToken99 = 99e18;

        // prettier-ignore
        Entity memory entityData = Entity({ 
            assetId: usdcId, 
            collateralRatio: 5_000, 
            maxCapacity: 100_000 * 1e6,
            utilizedCapacity: 0,
            simplePolicyEnabled: true 
        });

        NaymsAccount memory attacker = makeNaymsAcc("Attacker");
        NaymsAccount memory userA = makeNaymsAcc("entityA");

        vm.startPrank(sm.addr);

        // createEntity for attacker
        hCreateEntity(attacker.entityId, attacker.id, entityData, "test entity");

        // Attacker deposits 1000 USDC + trading fee
        fundEntityUsdc(attacker, usdc1000 + 1e7);

        vm.startPrank(sm.addr);

        // userA startTokenSale with (1000 pToken for 1000.000001 USDC)
        hCreateEntity(userA.entityId, userA.id, entityData, "entity test hash");
        nayms.enableEntityTokenization(userA.entityId, "E1", "Entity 1 Token", 1e6);
        nayms.startTokenSale(userA.entityId, pToken100, usdc1000 * 2);

        /// Attack script
        /// place order and lock funds
        vm.startPrank(attacker.addr);
        nayms.executeLimitOffer(usdcId, usdc1000, userA.entityId, pToken100);

        vm.startPrank(su.addr);
        /// create policy (double lock?)
        uint256 policyLimitAmount = (usdc1000 * 10_000) / entityData.collateralRatio;
        (Stakeholders memory stakeholders, SimplePolicy memory simplePolicy) = initPolicyWithLimitAndAsset("offChainHash", policyLimitAmount, usdcId);

        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(bytes32("1"), attacker.entityId, stakeholders, simplePolicy, "offChainHash");

        uint256 lockedBalance = nayms.getLockedBalance(attacker.entityId, usdcId);
        uint256 internalBalance = nayms.internalBalanceOf(attacker.entityId, usdcId);
        require(lockedBalance <= internalBalance, "double lock balance attack successful");
    }

    function testMinimumSellAmounts_IM24703() public {
        vm.startPrank(sm.addr);
        nayms.setMinimumSell(usdcId, 1e6);
        assertEq(nayms.objectMinimumSell(usdcId), 1e6, "unexpected minimum sell amount");
        bytes32 e1Id = createTestEntity(ea.id);
        ea.entityId = e1Id;
        nayms.enableEntityTokenization(e1Id, "E1", "Entity 1", 1e12);

        hSetEntity(tcp, e1Id);
        // Selling 10 pTokens for 1_000_000 USDC
        nayms.startTokenSale(e1Id, 10e18, 1_000_000e6);

        hAssignRole(tcp.id, e1Id, LC.ROLE_ENTITY_CP);

        fundEntityUsdc(ea, 1_000_000e6);
        // If the amount being sold is less than the minimum sell amount, the offer is expected to go into the
        // "fulfilled" state
        vm.startPrank(tcp.addr);
        (uint256 lastOfferId, , ) = nayms.executeLimitOffer(usdcId, 1e6 - 1, e1Id, 10e18);
        MarketInfo memory m = logOfferDetails(lastOfferId);
        assertEq(m.state, LC.OFFER_STATE_FULFILLED, "unexpected offer state");
        (lastOfferId, , ) = nayms.executeLimitOffer(usdcId, 1e6, e1Id, 1e12 + 1);
        m = logOfferDetails(lastOfferId);
        assertEq(m.state, LC.OFFER_STATE_ACTIVE, "unexpected offer state");
        (lastOfferId, , ) = nayms.executeLimitOffer(usdcId, 1e6 + 1, e1Id, 1e12);
        m = logOfferDetails(lastOfferId);
        assertEq(m.state, LC.OFFER_STATE_ACTIVE, "unexpected offer state");
        (lastOfferId, , ) = nayms.executeLimitOffer(usdcId, 1e6, e1Id, 1e12 - 1);
        m = logOfferDetails(lastOfferId);
        assertEq(m.state, LC.OFFER_STATE_FULFILLED, "unexpected offer state");
    }
}
