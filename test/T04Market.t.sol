// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { initEntity, D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { Vm } from "forge-std/Vm.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { Entity, FeeRatio, MarketInfo } from "src/diamonds/nayms/AppStorage.sol";
import { INayms } from "src/diamonds/nayms/INayms.sol";
import { IERC20 } from "src/erc20/IERC20.sol";

/* 
    Terminology:
    nWETH: bytes32 ID of WETH
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
}

contract T04MarketTest is D03ProtocolDefaults, MockAccounts {
    bytes32 internal nWETH;
    bytes32 internal nWBTC;
    bytes32 internal dividendBankId;

    bytes32 internal entity1 = bytes32("e5");
    bytes32 internal entity2 = bytes32("e6");
    bytes32 internal entity3 = bytes32("e7");
    bytes32 internal entity4 = bytes32("e8");

    uint256 internal constant testBalance = 100_000 ether;

    uint256 internal constant dividendAmount = 1000;

    uint256 internal constant collateralRatio_500 = 500;
    uint256 internal constant maxCapital_2000eth = 2_000 ether;
    uint256 internal constant maxCapital_3000eth = 3_000 ether;
    uint256 internal constant totalLimit_2000eth = 2_000 ether;

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
            entity1SalePrice: 1_000 ether, // 1:1 ratio, todo 0:1, 1:0
            entity2SalePrice: 1_000 ether
        });

    function setUp() public virtual override {
        super.setUp();

        // init token IDs
        nWETH = LibHelpers._getIdForAddress(wethAddress);
        nWBTC = LibHelpers._getIdForAddress(wbtcAddress);

        // whitelist tokens
        nayms.addSupportedExternalToken(wethAddress);
        nayms.addSupportedExternalToken(wbtcAddress);

        dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);
    }

    function prettyGetOffer(uint256 offerId) public {
        MarketInfo memory marketInfo = nayms.getOffer(offerId);

        // console2.log("            creator", marketInfo.creator);
        // console2.log("         sell token", marketInfo.sellToken);
        console2.log("        sell amount", marketInfo.sellAmount);
        console2.log("sell amount initial", marketInfo.sellAmountInitial);
        // console2.log("          buy token", marketInfo.buyToken);
        console2.log("         buy amount", marketInfo.buyAmount);
        console2.log(" buy amount initial", marketInfo.buyAmountInitial);
        console2.log("              state", marketInfo.state);
        // assertEq(marketInfo.creator, entity1, "creator");
        // assertEq(marketInfo.sellToken, entity1, "sell token");
        // assertEq(marketInfo.sellAmount, dt.entity1MintAndSaleAmt, "sell amount");
        // assertEq(marketInfo.sellAmountInitial, dt.entity1MintAndSaleAmt, "sell amount initial");
        // assertEq(marketInfo.buyToken, nWETH, "buy token");
        // assertEq(marketInfo.buyAmount, dt.entity1SalePrice, "buy amount");
        // assertEq(marketInfo.buyAmountInitial, dt.entity1SalePrice, "buy amount initial");
        // assertEq(marketInfo.state, LibConstants.OFFER_STATE_ACTIVE, "state");
    }

    function testMarketStartTokenSale() public {
        nayms.createEntity(entity1, signer1Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");

        // mint weth for account0
        writeTokenBalance(account0, naymsAddress, wethAddress, dt.entity1StartingBal);

        // NOTE and maybe todo: when using writeTokenBalance, this does not update the total supply!
        // assertEq(weth.totalSupply(), naymsAddress, 10_000, "weth total supply after mint should INCREASE (mint)");

        // note: deposits must be an exisiting entity: s.existingEntities[_receiverId]
        vm.expectRevert("extDeposit: invalid receiver");
        nayms.externalDepositToEntity(dividendBankId, wethAddress, 1_000);

        nayms.externalDeposit(DEFAULT_ACCOUNT0_ENTITY_ID, wethAddress, dt.entity1ExternalDepositAmt);
        // deposit into nayms vaults
        // note: the entity creator can deposit funds into an entity
        nayms.externalDeposit(entity1, wethAddress, dt.entity1ExternalDepositAmt);

        // start a token sale: sell entity tokens for nWETH
        // when a token sale starts: entity tokens are minted to the entity,
        // 2nd param is the sell amount, 3rd param is the buy amount
        vm.recordLogs();
        // putting an offer on behalf of entity1 to sell their nENTITY1 for the entity's associated asset
        // 500 nENTITY1 for 500 nWETH, 1:1 ratio
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
        assertEq(buyToken, nWETH, "OrderAdded: invalid buy token");
        assertEq(buyAmount, dt.entity1SalePrice, "OrderAdded: invalid buy amount");
        assertEq(buyAmountInitial, dt.entity1SalePrice, "OrderAdded: invalid initial buy amount");
        assertEq(state, LibConstants.OFFER_STATE_ACTIVE, "OrderAdded: invalid offer state");

        assertEq(entries[3].topics.length, 2, "TokenSaleStarted: topics length incorrect");
        assertEq(entries[3].topics[0], keccak256("TokenSaleStarted(bytes32,uint256)"));
        assertEq(entries[3].topics[1], entity1, "TokenSaleStarted: incorrect entity"); // assert entity
        uint256 offerId = abi.decode(entries[3].data, (uint256));
        assertEq(offerId, 1, "TokenSaleStarted: invalid offerId");

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
        assertEq(marketInfo1.buyToken, nWETH);
        assertEq(marketInfo1.buyAmount, dt.entity1SalePrice);
        assertEq(marketInfo1.buyAmountInitial, dt.entity1SalePrice);
        assertEq(marketInfo1.state, LibConstants.OFFER_STATE_ACTIVE);

        // a user should NOT be able to transfer / withdraw their tokens for sale
        // transfer to invalid entity check?
        assertEq(nayms.getBalanceOfTokensForSale(entity1, entity1), dt.entity1MintAndSaleAmt, "entity1 nEntity1 balance of tokens for sale should INCREASE (lock)");

        // try transfering nEntity1 from entity1 to entity0 - this should REVERT!
        vm.startPrank(signer1);
        vm.expectRevert("_internalTransferFrom: tokens for sale in mkt");
        nayms.internalTransferFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, entity1, 1);
        vm.stopPrank();

        assertTrue(nayms.isActiveOffer(1), "Token sale offer should be active");
    }

    function testMarketOfferMatchedAndCommissionsPayed() public {
        testMarketStartTokenSale();

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");

        // fund taker entity
        nayms.externalDepositToEntity(entity2, wethAddress, dt.entity2ExternalDepositAmt);

        uint256 naymsBalanceBeforeTrade = nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), nWETH);

        vm.startPrank(signer2);
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt - 200, entity1, dt.entity1MintAndSaleAmt);
        assertEq(nayms.getLastOfferId(), 2, "lastOfferId should INCREASE after executeLimitOffer");
        vm.stopPrank();

        vm.startPrank(signer3);
        vm.expectRevert("only creator can cancel");
        nayms.cancelOffer(2);
        vm.stopPrank();

        vm.startPrank(signer2);
        nayms.cancelOffer(2);

        vm.expectRevert("offer not active");
        nayms.cancelOffer(2);

        MarketInfo memory offer = nayms.getOffer(2);
        assertEq(offer.rankNext, 0, "Next sibling not blank");
        assertEq(offer.rankPrev, 0, "Prevoius sibling not blank");
        assertEq(offer.state, LibConstants.OFFER_STATE_CANCELLED, "offer state != Cancelled");

        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        // assert trading commisions payed
        uint256 totalCommissions = (dt.entity1MintAndSaleAmt * 4) / 1000; // see AppStorage: 4 => s.tradingComissionTotalBP
        assertEq(nayms.internalBalanceOf(entity2, nWETH), dt.entity2ExternalDepositAmt - dt.entity1MintAndSaleAmt - totalCommissions, "Trading commisions should be payed");

        uint256 naymsBalanceAfterTrade = naymsBalanceBeforeTrade + (totalCommissions / 2); // see AppStorage: 2 => s.tradingComissionNaymsLtdBP
        assertEq(
            nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), nWETH),
            naymsBalanceAfterTrade,
            "Nayms should receive half of trading commissions"
        );
        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), nWETH), naymsBalanceAfterTrade / 2, "NDF should get a trading commission");
        assertEq(
            nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), nWETH),
            naymsBalanceAfterTrade / 2,
            "Staking mechanism should get a trading commission"
        );

        // assert Entity1 holds `buyAmount` of nE1
        assertEq(nayms.internalBalanceOf(entity2, entity1), dt.entity1MintAndSaleAmt);
    }

    function testMarketFuzzMatchingOffers(uint256 saleAmount, uint256 salePrice) public {
        // avoid overflow issues
        vm.assume(saleAmount < 1_000_000_000_000 ether);
        vm.assume(salePrice < 1_000_000_000_000 ether);

        // avoid dust issues
        vm.assume(saleAmount > 1_000);
        vm.assume(salePrice > 1_000);

        // whitelist underlying token
        nayms.addSupportedExternalToken(wethAddress);

        nayms.createEntity(entity1, signer1Id, initEntity(weth, collateralRatio_500, salePrice, salePrice, true), "entity test hash");
        nayms.createEntity(entity2, signer2Id, initEntity(weth, collateralRatio_500, salePrice, salePrice, true), "entity test hash");

        // init test funds to maxint
        writeTokenBalance(account0, naymsAddress, wethAddress, ~uint256(0));

        if (saleAmount == 0) {
            vm.expectRevert("mint amount must be > 0");
            nayms.startTokenSale(entity1, saleAmount, salePrice);
        } else if (salePrice == 0) {
            vm.expectRevert("MultiToken: mint zero tokens");
            nayms.externalDeposit(entity2, wethAddress, salePrice);
        } else {
            uint256 e2Balance = (salePrice * 1004) / 1000; // this should correspond to `AppStorage.tradingComissionTotalBP`
            nayms.externalDeposit(entity2, wethAddress, e2Balance);

            // putting an offer on behalf of entity1 to sell their nENTITY1 for the entity's associated asset
            // x nENTITY1 for x nWETH  (1:1 ratio)
            nayms.startTokenSale(entity1, saleAmount, salePrice);

            MarketInfo memory marketInfo1 = nayms.getOffer(1);
            assertEq(marketInfo1.creator, entity1, "creator");
            assertEq(marketInfo1.sellToken, entity1, "sell token");
            assertEq(marketInfo1.sellAmount, saleAmount, "sell amount");
            assertEq(marketInfo1.sellAmountInitial, saleAmount, "sell amount initial");
            assertEq(marketInfo1.buyToken, nWETH, "buy token");
            assertEq(marketInfo1.buyAmount, salePrice, "buy amount");
            assertEq(marketInfo1.buyAmountInitial, salePrice, "buy amount initial");
            assertEq(marketInfo1.state, LibConstants.OFFER_STATE_ACTIVE, "state");

            vm.prank(signer2);
            nayms.executeLimitOffer(nWETH, salePrice, entity1, saleAmount);
            vm.stopPrank();

            marketInfo1 = nayms.getOffer(1);
            assertEq(marketInfo1.creator, entity1, "creator");
            assertEq(marketInfo1.sellToken, entity1, "sell token");
            assertEq(marketInfo1.sellAmount, 0, "sell amount");
            assertEq(marketInfo1.sellAmountInitial, saleAmount, "sell amount initial");
            assertEq(marketInfo1.buyToken, nWETH, "buy token");
            assertEq(marketInfo1.buyAmount, 0, "buy amount");
            assertEq(marketInfo1.buyAmountInitial, salePrice, "buy amount initial");
            assertEq(marketInfo1.state, LibConstants.OFFER_STATE_FULFILLED, "state");
        }
    }

    function testMarketUserCannotTransferFundsLockedInAnOffer() public {
        testMarketStartTokenSale();

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");

        // fund taker entity
        nayms.externalDepositToEntity(entity2, wethAddress, 1_000 ether);

        vm.startPrank(signer2);
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt - 200 ether, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("_internalBurn: tokens for sale in mkt");
        nayms.externalWithdrawFromEntity(entity2, signer2, wethAddress, 500 ether);

        uint256 lastOfferId = nayms.getLastOfferId();

        nayms.cancelOffer(lastOfferId);
        MarketInfo memory offer = nayms.getOffer(lastOfferId);
        assertEq(offer.state, LibConstants.OFFER_STATE_CANCELLED);

        nayms.externalWithdrawFromEntity(entity2, signer2, wethAddress, 500 ether);
        uint256 balanceAfterWithdraw = nayms.internalBalanceOf(entity2, nWETH);
        assertEq(balanceAfterWithdraw, 500 ether);
    }

    function testMarketGetBestOfferId() public {
        testMarketStartTokenSale();

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");
        nayms.createEntity(entity4, signer4Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");

        // fund taker entity
        nayms.externalDepositToEntity(entity2, wethAddress, 1_000 ether);
        nayms.externalDepositToEntity(entity3, wethAddress, 1_000 ether);
        nayms.externalDepositToEntity(entity4, wethAddress, 1_000 ether);

        vm.startPrank(signer2);
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt - 200 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        vm.startPrank(signer3);
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt - 150 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();
        // last offer at this point will be the actual best offer
        uint256 bestOfferID = nayms.getLastOfferId();

        vm.startPrank(signer4);
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt - 190 ether, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        // confirm best offer
        assertEq(bestOfferID, nayms.getBestOfferId(nWETH, entity1), "Not the best offer");
    }

    function testMarketOfferValidation() public {
        testMarketStartTokenSale();

        vm.startPrank(account9);
        vm.expectRevert("must belong to entity to make an offer");
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);
        vm.stopPrank();

        // init taker entity
        nayms.createEntity(entity2, signer2Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");
        nayms.externalDepositToEntity(entity2, wethAddress, 1_000 ether);

        vm.startPrank(signer2);

        vm.expectRevert("sell amount must be uint128");
        nayms.executeLimitOffer(nWETH, 2**128 + 1000, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy amount must be uint128");
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, entity1, 2**128 + 1000);

        vm.expectRevert("sell amount must be >0");
        nayms.executeLimitOffer(nWETH, 0, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy amount must be >0");
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, entity1, 0);

        vm.expectRevert("sell token must be valid");
        nayms.executeLimitOffer("", dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("buy token must be valid");
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, "", dt.entity1MintAndSaleAmt);

        vm.expectRevert("must be one platform token"); // 2 non-platform tokens
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, nWBTC, dt.entity1MintAndSaleAmt);

        vm.expectRevert("cannot sell and buy same token");
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, nWETH, dt.entity1MintAndSaleAmt);

        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt - 10 ether, entity1, dt.entity1MintAndSaleAmt);

        vm.expectRevert("tokens locked in market");
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        uint256 lastOfferId = nayms.getLastOfferId();
        nayms.cancelOffer(lastOfferId);

        vm.stopPrank();

        nayms.startTokenSale(entity2, dt.entity2MintAndSaleAmt, dt.entity2SalePrice);

        vm.startPrank(signer3);
        vm.expectRevert("must be one platform token"); // 2 platform tokens
        nayms.executeLimitOffer(entity2, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt);

        vm.stopPrank();
    }

    function testMarketMatchingExternalTokenOnSellSide() public {
        nayms.addSupportedExternalToken(wethAddress);
        writeTokenBalance(account0, naymsAddress, wethAddress, dt.entity1StartingBal);

        nayms.createEntity(entity1, signer1Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");
        nayms.externalDeposit(entity1, wethAddress, dt.entity1ExternalDepositAmt * 2);

        // start token sale
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);

        // create (x2) counter offer
        nayms.createEntity(entity2, signer2Id, initEntity(weth, collateralRatio_500, maxCapital_2000eth, totalLimit_2000eth, true), "entity test hash");
        nayms.externalDepositToEntity(entity2, wethAddress, dt.entity2ExternalDepositAmt * 2);
        vm.startPrank(signer2);
        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt * 2, entity1, dt.entity1MintAndSaleAmt * 2);
        vm.stopPrank();

        // start another token sale
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);

        MarketInfo memory marketInfo1 = nayms.getOffer(1);
        assertEq(marketInfo1.creator, entity1);
        assertEq(marketInfo1.sellToken, entity1);
        assertEq(marketInfo1.sellAmount, 0);
        assertEq(marketInfo1.sellAmountInitial, dt.entity1MintAndSaleAmt);
        assertEq(marketInfo1.buyToken, nWETH);
        assertEq(marketInfo1.buyAmount, 0);
        assertEq(marketInfo1.buyAmountInitial, dt.entity1SalePrice);
        assertEq(marketInfo1.state, LibConstants.OFFER_STATE_FULFILLED);

        MarketInfo memory marketInfo2 = nayms.getOffer(2);
        assertEq(marketInfo2.state, LibConstants.OFFER_STATE_FULFILLED);

        MarketInfo memory marketInfo3 = nayms.getOffer(3);
        assertEq(marketInfo3.state, LibConstants.OFFER_STATE_FULFILLED);
    }

    // executeLimitOffer() with a remaining amount of sell token, buy token
    // todo test order with two platform tokens, two entity tokens, eventually test with staking token (todo should this be allowed?)
}
