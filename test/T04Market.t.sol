// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { Vm } from "forge-std/Vm.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { Entity, FeeRatio, MarketInfo, TradingCommissions, SimplePolicy, SimplePolicyInfo, Stakeholders } from "src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { IERC20 } from "src/erc20/IERC20.sol";

import { LibFeeRouterFixture } from "test/fixtures/LibFeeRouterFixture.sol";
import { TradingCommissionsFixture, TradingCommissionsConfig } from "test/fixtures/TradingCommissionsFixture.sol";

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
    bytes32 internal dividendBankId;

    bytes32 internal entity1 = bytes32("e5");
    bytes32 internal entity2 = bytes32("e6");
    bytes32 internal entity3 = bytes32("e7");
    bytes32 internal entity4 = bytes32("e8");

    uint256 internal constant testBalance = 100_000 ether;

    uint256 internal constant dividendAmount = 1000;

    uint256 internal constant collateralRatio_500 = 5000;
    uint256 internal constant maxCapital_2000eth = 2_000 ether;
    uint256 internal constant maxCapital_3000eth = 3_000 ether;
    uint256 internal constant totalLimit_2000eth = 2_000 ether;

    bytes32 public testPolicyDataHash = "test";

    TradingCommissionsFixture internal tradingCommissionsFixture;

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

    TradingCommissionsConfig internal c;

    function setUp() public virtual override {
        super.setUp();

        // whitelist WBTC as well
        nayms.addSupportedExternalToken(wbtcAddress);

        dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        // setup trading commissions fixture
        tradingCommissionsFixture = new TradingCommissionsFixture();
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = tradingCommissionsFixture.getCommissionsConfig.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(tradingCommissionsFixture), action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        nayms.diamondCut(cut, address(0), "");

        c = getCommissions();
    }

    function getCommissions() internal returns (TradingCommissionsConfig memory) {
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(tradingCommissionsFixture.getCommissionsConfig.selector));
        require(success, "Should get commissions from app storage");
        return abi.decode(result, (TradingCommissionsConfig));
    }

    function testStartTokenSale() public {
        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        // mint weth for account0
        writeTokenBalance(account0, naymsAddress, wethAddress, dt.entity1StartingBal);

        // note: when using writeTokenBalance, this does not update the total supply!
        // assertEq(weth.totalSupply(), naymsAddress, 10_000, "weth total supply after mint should INCREASE (mint)");

        nayms.externalDeposit(wethAddress, dt.entity1ExternalDepositAmt);
        // deposit into nayms vaults
        // note: the entity creator can deposit funds into an entity

        vm.startPrank(signer1);
        writeTokenBalance(signer1, naymsAddress, wethAddress, dt.entity1StartingBal);
        nayms.externalDeposit(wethAddress, dt.entity1ExternalDepositAmt);
        vm.stopPrank();

        nayms.enableEntityTokenization(entity1, "e1token", "e1token");

        // start a token sale: sell entity tokens for nWETH
        // when a token sale starts: entity tokens are minted to the entity,
        // 2nd param is the sell amount, 3rd param is the buy amount
        vm.recordLogs();
        // putting an offer on behalf of entity1 to sell their nENTITY1 for the entity's associated asset
        // 500 nENTITY1 for 500 WETH, 1:1 ratio
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "InternalTokenSupplyUpdate: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("InternalTokenSupplyUpdate(bytes32,uint256,string,address)"), "InternalTokenSupplyUpdate: Invalid event signature");
        assertEq(entries[0].topics[1], entity1, "InternalTokenSupplyUpdate: incorrect tokenID"); // assert entity token
        (uint256 newSupply, string memory fName, ) = abi.decode(entries[0].data, (uint256, string, address));
        assertEq(fName, "_internalMint", "InternalTokenSupplyUpdate: invalid function name");
        assertEq(newSupply, dt.entity1MintAndSaleAmt, "InternalTokenSupplyUpdate: invalid token supply");

        assertEq(entries[1].topics.length, 2, "InternalTokenBalanceUpdate: topics length incorrect");
        assertEq(entries[1].topics[0], keccak256("InternalTokenBalanceUpdate(bytes32,bytes32,uint256,string,address)"), "InternalTokenBalanceUpdate: Invalid event signature");
        assertEq(entries[1].topics[1], entity1, "InternalTokenBalanceUpdate: incorrect tokenID"); // assert entity token
        (bytes32 tokenId, uint256 newSupply2, string memory fName2, ) = abi.decode(entries[1].data, (bytes32, uint256, string, address));
        assertEq(fName2, "_internalMint", "InternalTokenBalanceUpdate: invalid function name");
        assertEq(tokenId, entity1, "InternalTokenBalanceUpdate: invalid token");
        assertEq(newSupply2, dt.entity1MintAndSaleAmt, "InternalTokenBalanceUpdate: invalid balance");

        assertEq(entries[2].topics.length, 4, "OrderAdded: topics length incorrect");
        assertEq(entries[2].topics[0], keccak256("OrderAdded(uint256,bytes32,bytes32,uint256,uint256,bytes32,uint256,uint256,uint256)"), "OrderAdded: Invalid event signature");
        assertEq(abi.decode(LibHelpers._bytes32ToBytes(entries[2].topics[1]), (uint256)), 1, "OrderAdded: invalid offerId"); // assert offerId
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
        assertEq(state, LibConstants.OFFER_STATE_ACTIVE, "OrderAdded: invalid offer state");

        assertEq(entries[3].topics.length, 2, "TokenSaleStarted: topics length incorrect");
        assertEq(entries[3].topics[0], keccak256("TokenSaleStarted(bytes32,uint256,string,string)"));
        assertEq(entries[3].topics[1], entity1, "TokenSaleStarted: incorrect entity"); // assert entity
        (uint256 offerId, string memory tokenSymbol, string memory tokenName) = abi.decode(entries[3].data, (uint256, string, string));
        assertEq(offerId, 1, "TokenSaleStarted: invalid offerId");
        assertEq(tokenSymbol, "e1token", "TokenSaleStarted: invalid token symbol");
        assertEq(tokenName, "e1token", "TokenSaleStarted: invalid token name");

        // note: the token balance for sale is not escrowed in the marketplace anymore, instead we keep track of another balance (user's tokens for sale)
        // in order to ensure a user cannot transfer the token balance that they have for sale
        assertEq(nayms.internalBalanceOf(entity1, entity1), 0 + dt.entity1MintAndSaleAmt, "entity1 internalTokenSupply after startTokenSale should INCREASE (mint)");
        assertEq(nayms.internalTokenSupply(entity1), 0 + dt.entity1MintAndSaleAmt, "nEntity1 total supply after startTokenSale should INCREASE (mint)");

        assertEq(nayms.getLastOfferId(), 1, "lastOfferId after startTokenSale should INCREASE");

        MarketInfo memory marketInfo1 = nayms.getOffer(1);
        assertEq(marketInfo1.creator, entity1);
        assertEq(marketInfo1.sellToken, entity1);
        assertEq(marketInfo1.sellAmount, dt.entity1MintAndSaleAmt);
        assertEq(marketInfo1.sellAmountInitial, dt.entity1MintAndSaleAmt);
        assertEq(marketInfo1.buyToken, wethId);
        assertEq(marketInfo1.buyAmount, dt.entity1SalePrice);
        assertEq(marketInfo1.buyAmountInitial, dt.entity1SalePrice);
        assertEq(marketInfo1.state, LibConstants.OFFER_STATE_ACTIVE);

        // a user should NOT be able to transfer / withdraw their tokens for sale
        // transfer to invalid entity check?
        assertEq(nayms.getLockedBalance(entity1, entity1), dt.entity1MintAndSaleAmt, "entity1 nEntity1 balance of tokens for sale should INCREASE (lock)");

        // try transfering nEntity1 from entity1 to entity0 - this should REVERT!
        vm.startPrank(signer1);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.internalTransferFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, entity1, 1);
        vm.stopPrank();

        assertTrue(nayms.isActiveOffer(1), "Token sale offer should be active");
    }

    function testCommissionsPayed() public {
        testStartTokenSale();

        // init and fund taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        nayms.createEntity(entity3, signer3Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        vm.startPrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, dt.entity2ExternalDepositAmt);
        nayms.externalDeposit(wethAddress, dt.entity2ExternalDepositAmt);
        vm.stopPrank();

        vm.startPrank(signer3);
        writeTokenBalance(signer3, naymsAddress, wethAddress, dt.entity3ExternalDepositAmt);
        nayms.externalDeposit(wethAddress, dt.entity3ExternalDepositAmt);
        vm.stopPrank();

        uint256 naymsBalanceBeforeTrade = nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), wethId);

        vm.startPrank(signer2);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);
        assertEq(nayms.getLastOfferId(), 2, "lastOfferId should INCREASE after executeLimitOffer");
        vm.stopPrank();

        assertEq(nayms.internalBalanceOf(entity1, wethId), dt.entity1ExternalDepositAmt + dt.entity1MintAndSaleAmt, "Maker should not pay commisisons");

        // assert trading commisions payed
        uint256 totalCommissions = (dt.entity1MintAndSaleAmt * c.tradingCommissionTotalBP) / LibConstants.BP_FACTOR; // see AppStorage: 4 => s.tradingCommissionTotalBP
        assertEq(nayms.internalBalanceOf(entity2, wethId), dt.entity2ExternalDepositAmt - dt.entity1MintAndSaleAmt - totalCommissions, "Taker should pay commissions");

        uint256 naymsBalanceAfterTrade = naymsBalanceBeforeTrade + ((totalCommissions * c.tradingCommissionNaymsLtdBP) / LibConstants.BP_FACTOR);
        uint256 ndfBalanceAfterTrade = naymsBalanceBeforeTrade + ((totalCommissions * c.tradingCommissionNDFBP) / LibConstants.BP_FACTOR);
        uint256 stmBalanceAfterTrade = naymsBalanceBeforeTrade + ((totalCommissions * c.tradingCommissionSTMBP) / LibConstants.BP_FACTOR);
        assertEq(
            nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), wethId),
            naymsBalanceAfterTrade,
            "Nayms should receive half of trading commissions"
        );
        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), wethId), ndfBalanceAfterTrade, "NDF should get a trading commission");
        assertEq(
            nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), wethId),
            stmBalanceAfterTrade,
            "Staking mechanism should get a trading commission"
        );

        // assert Entity1 holds `buyAmount` of nE1
        assertEq(nayms.internalBalanceOf(entity2, entity1), dt.entity1MintAndSaleAmt);

        // test commission payed by taker on "secondary market"
        uint256 e2WethBeforeTrade = nayms.internalBalanceOf(entity2, wethId);
        uint256 e3WethBeforeTrade = nayms.internalBalanceOf(entity3, wethId);

        vm.startPrank(signer2);
        nayms.executeLimitOffer(entity1, dt.entity1MintAndSaleAmt, wethId, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        vm.startPrank(signer3);
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        assertEq(nayms.internalBalanceOf(entity2, wethId), e2WethBeforeTrade + dt.entity1MintAndSaleAmt, "Maker pays no commissions, on secondary market");
        assertEq(nayms.internalBalanceOf(entity3, wethId), e3WethBeforeTrade - dt.entity1MintAndSaleAmt - totalCommissions, "Taker should pay commissions, on secondary market");
    }

    function testMatchMakerPriceWithTakerBuyAmount() public {
        testStartTokenSale();

        // init and fund taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");

        vm.startPrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, dt.entity2ExternalDepositAmt);
        nayms.externalDeposit(wethAddress, dt.entity2ExternalDepositAmt);

        nayms.executeLimitOffer(wethId, 1_000 ether, entity1, 500 ether);
        vm.stopPrank();

        assertEq(nayms.internalBalanceOf(entity2, entity1), 500 ether, "should match takers buy amount, not sell amount");

        uint256 offerId = nayms.getLastOfferId();
        MarketInfo memory offer = nayms.getOffer(offerId);
        assertEq(offer.state, LibConstants.OFFER_STATE_FULFILLED, "offer should be closed");
    }

    function testCancelOffer() public {
        testStartTokenSale();

        vm.startPrank(signer3);
        vm.expectRevert("only member of entity can cancel");
        nayms.cancelOffer(1);
        vm.stopPrank();

        vm.recordLogs();

        vm.startPrank(signer1);
        nayms.cancelOffer(1);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 3, "OrderCancelled: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("OrderCancelled(uint256,bytes32,bytes32)"), "OrderCancelled: Invalid event signature");
        assertEq(abi.decode(LibHelpers._bytes32ToBytes(entries[0].topics[1]), (uint256)), 1, "OrderCancelled: incorrect order ID"); // assert entity token
        assertEq(entries[0].topics[2], entity1, "OrderCancelled: incorrect taker ID"); // assert entity token

        bytes32 sellToken = abi.decode(entries[0].data, (bytes32));

        assertEq(sellToken, entity1, "OrderCancelled: invalid sell token");

        vm.expectRevert("offer not active");
        nayms.cancelOffer(1);

        MarketInfo memory offer = nayms.getOffer(1);
        assertEq(offer.rankNext, 0, "Next sibling not blank");
        assertEq(offer.rankPrev, 0, "Prevoius sibling not blank");
        assertEq(offer.state, LibConstants.OFFER_STATE_CANCELLED, "offer state != Cancelled");
    }

    function testFuzzMatchingOffers(uint256 saleAmount, uint256 salePrice) public {
        // avoid over/underflow issues
        vm.assume(1_000 < saleAmount && saleAmount < type(uint128).max);
        vm.assume(1_000 < salePrice && salePrice < type(uint128).max);

        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, salePrice, true), "test");
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, salePrice, true), "test");

        // init test funds to maxint
        writeTokenBalance(account0, naymsAddress, wethAddress, ~uint256(0));
        nayms.enableEntityTokenization(entity1, "e1token", "e1token");

        if (saleAmount == 0) {
            vm.expectRevert("mint amount must be > 0");
            nayms.startTokenSale(entity1, saleAmount, salePrice);
        } else if (salePrice == 0) {
            vm.expectRevert("_internalMint: mint zero tokens");
            nayms.externalDeposit(wethAddress, salePrice);
        } else {
            uint256 e2Balance = (salePrice * (LibConstants.BP_FACTOR + c.tradingCommissionTotalBP)) / LibConstants.BP_FACTOR;

            vm.startPrank(signer2);
            writeTokenBalance(signer2, naymsAddress, wethAddress, e2Balance);
            nayms.externalDeposit(wethAddress, e2Balance);
            vm.stopPrank();

            // sell x nENTITY1 for y WETH
            nayms.startTokenSale(entity1, saleAmount, salePrice);

            MarketInfo memory marketInfo1 = nayms.getOffer(1);
            assertEq(marketInfo1.creator, entity1, "creator");
            assertEq(marketInfo1.sellToken, entity1, "sell token");
            assertEq(marketInfo1.sellAmount, saleAmount, "sell amount");
            assertEq(marketInfo1.sellAmountInitial, saleAmount, "sell amount initial");
            assertEq(marketInfo1.buyToken, wethId, "buy token");
            assertEq(marketInfo1.buyAmount, salePrice, "buy amount");
            assertEq(marketInfo1.buyAmountInitial, salePrice, "buy amount initial");
            assertEq(marketInfo1.state, LibConstants.OFFER_STATE_ACTIVE, "state");

            vm.prank(signer2);
            nayms.executeLimitOffer(wethId, salePrice, entity1, saleAmount);

            assertOfferFilled(1, entity1, entity1, saleAmount, wethId, salePrice);
        }
    }

    function testFuzzMatchingSellOffer(uint256 saleAmount, uint256 salePrice) public {
        // avoid over/underflow issues
        vm.assume(1_000 < saleAmount && saleAmount < type(uint128).max);
        vm.assume(1_000 < salePrice && salePrice < type(uint128).max);

        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, salePrice, true), "test");
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, salePrice, true), "test");

        // init test funds to maxint

        writeTokenBalance(signer1, naymsAddress, wethAddress, ~uint256(0));
        nayms.enableEntityTokenization(entity1, "e1token", "e1token");

        if (saleAmount == 0) {
            vm.expectRevert("mint amount must be > 0");
            nayms.startTokenSale(entity1, saleAmount, salePrice);
        } else if (salePrice == 0) {
            vm.expectRevert("_internalMint: mint zero tokens");
            nayms.externalDeposit(wethAddress, salePrice);
        } else {
            vm.startPrank(signer2);
            writeTokenBalance(signer2, naymsAddress, wethAddress, salePrice);
            nayms.externalDeposit(wethAddress, salePrice);
            assertEq(nayms.internalBalanceOf(entity2, LibHelpers._getIdForAddress(wethAddress)), salePrice, "Entity2: invalid balance");

            // buy x nENTITY1 for y WETH

            nayms.executeLimitOffer(wethId, salePrice, entity1, saleAmount);
            vm.stopPrank();

            // taker needs balance for trading commissions
            uint256 e1Balance = ((salePrice * (LibConstants.BP_FACTOR + c.tradingCommissionTotalBP)) / LibConstants.BP_FACTOR) - salePrice;
            vm.startPrank(signer1);
            writeTokenBalance(signer1, naymsAddress, wethAddress, e1Balance);
            nayms.externalDeposit(wethAddress, e1Balance);
            vm.stopPrank();
            assertEq(nayms.internalBalanceOf(entity1, LibHelpers._getIdForAddress(wethAddress)), e1Balance, "Entity1: invalid balance");

            // sell x nENTITY1 for y WETH
            nayms.startTokenSale(entity1, saleAmount, salePrice);

            assertOfferFilled(1, entity2, wethId, salePrice, entity1, saleAmount);
            assertOfferFilled(2, entity1, entity1, saleAmount, wethId, salePrice);
        }
    }

    function testUserCannotTransferFundsLockedInAnOffer() public {
        testStartTokenSale();

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        // fund taker entity
        vm.startPrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, 1_000 ether);
        nayms.externalDeposit(wethAddress, 1_000 ether);

        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 200 ether, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("_internalBurn: insufficient balance available, funds locked");
        nayms.externalWithdrawFromEntity(entity2, signer2, wethAddress, 500 ether);

        uint256 lastOfferId = nayms.getLastOfferId();

        nayms.cancelOffer(lastOfferId);
        MarketInfo memory offer = nayms.getOffer(lastOfferId);
        assertEq(offer.state, LibConstants.OFFER_STATE_CANCELLED);

        nayms.externalWithdrawFromEntity(entity2, signer2, wethAddress, 500 ether);
        uint256 balanceAfterWithdraw = nayms.internalBalanceOf(entity2, wethId);
        assertEq(balanceAfterWithdraw, 500 ether);
    }

    function testGetBestOfferId() public {
        assertEq(nayms.getBestOfferId(wethId, entity1), 0, "invalid best offer, when no offer exists");

        testStartTokenSale();

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity4, signer4Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        // fund taker entity
        vm.startPrank(signer2);
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

        vm.startPrank(account9);
        vm.expectRevert("offer must be made by an existing entity");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        vm.startPrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, 1_000 ether);

        nayms.externalDeposit(wethAddress, 1_000 ether);

        vm.expectRevert("sell amount exceeds uint128 limit");
        nayms.executeLimitOffer(wethId, 2**128 + 1000, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy amount exceeds uint128 limit");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, 2**128 + 1000);

        vm.expectRevert("sell amount must be >0");
        nayms.executeLimitOffer(wethId, 0, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy amount must be >0");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, 0);

        vm.expectRevert("sell token must be valid");
        nayms.executeLimitOffer("", dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy token must be valid");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, "", dt.entity1MintAndSaleAmt);

        vm.expectRevert("must be one participation token and one external token"); // 2 non-platform tokens
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, wbtcId, dt.entity1MintAndSaleAmt);

        vm.expectRevert("cannot sell and buy same token");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, wethId, dt.entity1MintAndSaleAmt);

        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt - 10 ether, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("insufficient balance available, funds locked");
        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        uint256 lastOfferId = nayms.getLastOfferId();
        nayms.cancelOffer(lastOfferId);

        vm.stopPrank();

        nayms.enableEntityTokenization(entity2, "e2token", "e2token");
        nayms.startTokenSale(entity2, dt.entity2MintAndSaleAmt, dt.entity2SalePrice);

        vm.startPrank(signer3);
        vm.expectRevert("must be one participation token and one external token"); // 2 platform tokens
        nayms.executeLimitOffer(entity2, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        vm.stopPrank();
    }

    function testMatchingExternalTokenOnSellSide() public {
        writeTokenBalance(account0, naymsAddress, wethAddress, dt.entity1StartingBal);

        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        nayms.enableEntityTokenization(entity1, "e1token", "e1token");

        // start nENTITY1 token sale
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);

        // create (x2) counter offer
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        vm.startPrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, dt.entity2ExternalDepositAmt * 2);
        nayms.externalDeposit(wethAddress, dt.entity2ExternalDepositAmt * 2);

        nayms.executeLimitOffer(wethId, dt.entity1MintAndSaleAmt * 2, entity1, dt.entity1MintAndSaleAmt * 2);
        vm.stopPrank();

        assertOfferPartiallyFilled(2, entity2, wethId, dt.entity1MintAndSaleAmt, dt.entity1MintAndSaleAmt * 2, entity1, dt.entity1MintAndSaleAmt, dt.entity1MintAndSaleAmt * 2);

        // start another nENTITY1 token sale
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);

        assertOfferFilled(1, entity1, entity1, dt.entity1MintAndSaleAmt, wethId, dt.entity1SalePrice);
        assertOfferFilled(2, entity2, wethId, dt.entity1MintAndSaleAmt * 2, entity1, dt.entity1SalePrice * 2);
        assertOfferFilled(3, entity1, entity1, dt.entity1MintAndSaleAmt, wethId, dt.entity1SalePrice);
    }

    function testBestOffersWithCancel() public {
        testStartTokenSale();

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");
        nayms.createEntity(entity4, signer4Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "entity test hash");

        // fund taker entity
        vm.startPrank(signer2);
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
        nayms.cancelOffer(4);
        vm.stopPrank();

        assertEq(nayms.getBestOfferId(wethId, entity1), 2, "invalid best offer ID");

        vm.startPrank(signer2);
        nayms.cancelOffer(2);
        vm.stopPrank();

        assertEq(nayms.getBestOfferId(wethId, entity1), 3, "invalid best offer ID");

        vm.startPrank(signer3);
        nayms.cancelOffer(3);
        vm.stopPrank();

        assertEq(nayms.getBestOfferId(wethId, entity1), 0, "invalid best offer ID");
    }

    function assertOfferFilled(
        uint256 offerId,
        bytes32 creator,
        bytes32 sellToken,
        uint256 initSellAmount,
        bytes32 buyToken,
        uint256 initBuyAmount
    ) private {
        MarketInfo memory offer = nayms.getOffer(offerId);
        assertEq(offer.creator, creator, "offer creator invalid");
        assertEq(offer.sellToken, sellToken, "invalid sell token");
        assertEq(offer.sellAmount, 0, "invalid sell amount");
        assertEq(offer.sellAmountInitial, initSellAmount, "invalid initial sell amount");
        assertEq(offer.buyToken, buyToken, "invalid buy token");
        assertEq(offer.buyAmount, 0, "invalid buy amount");
        assertEq(offer.buyAmountInitial, initBuyAmount, "invalid initial buy amount");
        assertEq(offer.state, LibConstants.OFFER_STATE_FULFILLED, "invalid state");
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
        assertEq(marketInfo1.state, LibConstants.OFFER_STATE_ACTIVE, "invalid state");
    }

    function testLibFeeRouter() public {
        // Deploy the LibFeeRouterFixture
        LibFeeRouterFixture libFeeRouterFixture = new LibFeeRouterFixture();
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = libFeeRouterFixture.payPremiumCommissions.selector;
        functionSelectors[1] = libFeeRouterFixture.payTradingCommissions.selector;
        functionSelectors[2] = libFeeRouterFixture.calculateTradingCommissionsFixture.selector;
        functionSelectors[3] = libFeeRouterFixture.getTradingCommissionsBasisPointsFixture.selector;

        // Diamond cut this fixture contract into our nayms diamond in order to test against the diamond
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(libFeeRouterFixture), action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        nayms.diamondCut(cut, address(0), "");

        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(libFeeRouterFixture.calculateTradingCommissionsFixture.selector, 10_000));

        TradingCommissions memory tc = nayms.calculateTradingCommissions(10_000);

        testStartTokenSale();
        bytes32 makerId = account0Id;
        bytes32 takerId = entity1;
        bytes32 tokenId = wethId;
        uint256 requestedBuyAmount = 10_000;

        (success, result) = address(nayms).call(abi.encodeWithSelector(libFeeRouterFixture.payTradingCommissions.selector, makerId, takerId, tokenId, requestedBuyAmount));
        assertTrue(success);

        bytes32 naymsLtdId = LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER);
        bytes32 ndfId = LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER);
        bytes32 stakingId = LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER);

        assertEq(nayms.internalBalanceOf(naymsLtdId, wethId), tc.commissionNaymsLtd, "balance of naymsLtd should have INCREASED (trading commissions)");
        assertEq(nayms.internalBalanceOf(ndfId, wethId), tc.commissionNDF, "balance of ndfId should have INCREASED (trading commissions)");
        assertEq(nayms.internalBalanceOf(stakingId, wethId), tc.commissionSTM, "balance of stakingId should have INCREASED (trading commissions)");

        (success, result) = address(nayms).call(abi.encodeWithSelector(libFeeRouterFixture.getTradingCommissionsBasisPointsFixture.selector));
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
        writeTokenBalance(account0, naymsAddress, wethAddress, e1balance);
        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        nayms.enableEntityTokenization(entity1, "e1token", "e1token");

        nayms.startTokenSale(entity1, offer1sell, offer1buy);

        // OFFER 2 (x2) counter offer: 4000 WETH -> 4000 pTokens
        // we have to do this as the protocol does not allow us to create an offer to buy pTokens before they are minted!
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_2000eth, true), "test");
        vm.startPrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, e2balance);
        nayms.externalDeposit(wethAddress, e2balance);
        nayms.executeLimitOffer(wethId, offer2sell, entity1, offer2buy);
        vm.stopPrank();

        // half should match so we should be left with offer 2 partially matched
        // 2000 WETH -> 2000 pTokens
        assertOfferPartiallyFilled(2, entity2, wethId, offer1buy, offer2sell, entity1, offer1sell, offer2buy);

        // OFFER 3: 2000 pTokens -> 1000 WETH
        nayms.startTokenSale(entity1, offer3sell, offer3buy);

        assertOfferFilled(1, entity1, entity1, offer1sell, wethId, offer1buy);
        assertOfferFilled(2, entity2, wethId, offer2sell, entity1, offer2buy);
        assertOfferFilled(3, entity1, entity1, offer3sell, wethId, offer3buy);
    }

    function testNotAbleToTradeWithLockedFunds() public {
        uint256 salePrice = 100 ether;
        uint256 saleAmount = 100 ether;

        bytes32 e1Id = DEFAULT_UNDERWRITER_ENTITY_ID;

        // init test funds to maxint
        writeTokenBalance(account0, naymsAddress, wethAddress, ~uint256(0));

        uint256 e2Balance = (salePrice * (LibConstants.BP_FACTOR + c.tradingCommissionTotalBP)) / LibConstants.BP_FACTOR;

        vm.startPrank(signer2);
        writeTokenBalance(signer2, naymsAddress, wethAddress, e2Balance);
        nayms.externalDeposit(wethAddress, e2Balance);
        vm.stopPrank();

        // sell x nENTITY1 for y WETH
        nayms.enableEntityTokenization(e1Id, "e1token", "e1token");
        nayms.startTokenSale(e1Id, saleAmount, salePrice);

        vm.prank(signer2);
        nayms.executeLimitOffer(wethId, salePrice, e1Id, saleAmount);

        assertOfferFilled(1, e1Id, e1Id, saleAmount, wethId, salePrice);
        assertEq(nayms.internalBalanceOf(e1Id, wethId), saleAmount, "balance should have INCREASED"); // has 100 weth

        assertEq(nayms.getLockedBalance(e1Id, wethId), 0, "locked balance should be 0");

        bytes32 policyId1 = "policy1";
        uint256 policyLimit = 85 ether;

        (Stakeholders memory stakeholders, SimplePolicy memory policy) = initPolicyWithLimit(testPolicyDataHash, policyLimit);
        nayms.createSimplePolicy(policyId1, e1Id, stakeholders, policy, testPolicyDataHash);

        uint256 lockedBalance = nayms.getLockedBalance(e1Id, wethId);
        assertEq(lockedBalance, policyLimit, "locked balance should increase");

        vm.expectRevert("insufficient balance");
        vm.prank(signer1);
        nayms.executeLimitOffer(e1Id, salePrice, wethId, saleAmount);
    }
}
