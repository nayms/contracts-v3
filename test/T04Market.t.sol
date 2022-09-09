// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { Vm } from "forge-std/Vm.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { Entity, FeeRatio, MarketInfo } from "src/diamonds/nayms/AppStorage.sol";

import { initEntity } from "./T04Entity.t.sol";

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
}

contract T04MarketTest is D03ProtocolDefaults, MockAccounts {
    bytes32 internal nWETH;
    bytes32 internal marketplaceId;
    bytes32 internal dividendBankId;

    bytes32 internal entity1 = bytes32("e5");
    bytes32 internal entity2 = bytes32("e6");
    bytes32 internal entity3 = bytes32("e7");

    uint256 internal constant saleAmount = 1000;
    uint256 internal constant buyAmount = 1000;
    uint256 internal constant dividendAmount = 1000;
    uint256 internal constant TEST_FUNDS_TOTAL = 10_000;

    TestInfo public dt =
        TestInfo({
            entity1StartingBal: 10_000,
            entity2StartingBal: 10_000,
            entity3StartingBal: 10_000,
            entity1ExternalDepositAmt: 1_000,
            entity2ExternalDepositAmt: 2_000,
            entity3ExternalDepositAmt: 3_000,
            entity1MintAndSaleAmt: 1_000,
            entity2MintAndSaleAmt: 1_000,
            entity3MintAndSaleAmt: 1_500,
            entity1SalePrice: 1000 // 1:1 ratio, todo 0:1, 1:0
        });

    function setUp() public virtual override {
        super.setUp();

        nWETH = LibHelpers._getIdForAddress(address(weth));
        marketplaceId = LibHelpers._stringToBytes32(LibConstants.MARKET_IDENTIFIER);
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

    // test the dividends when a user is selling tokens in the marketplace
    // ensure the user cannot transfer / burn or do anything with tokens that are for sale, besides canceling the order
    // ensure the dividends are recorded correctly and paid properly on transfer

    function testStartTokenSale() public {
        // whitelist underlying token
        nayms.addSupportedExternalToken(address(weth));

        nayms.createEntity(entity1, signer1Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");
        nayms.createEntity(entity2, signer2Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");

        // mint weth for account0
        writeTokenBalance(account0, address(nayms), address(weth), dt.entity1StartingBal);

        // NOTE and maybe todo: when using writeTokenBalance, this does not update the total supply!
        // assertEq(weth.totalSupply(), address(nayms), 10_000, "weth total supply after mint should INCREASE (mint)");

        // note: deposits must be an exisiting entity: s.existingEntities[_receiverId]
        vm.expectRevert("extDeposit: invalid receiver");
        nayms.externalDepositToEntity(dividendBankId, address(weth), 1_000);

        nayms.externalDeposit(DEFAULT_ACCOUNT0_ENTITY_ID, address(weth), dt.entity1ExternalDepositAmt);
        assertEq(weth.balanceOf(account0), dt.entity1StartingBal - dt.entity1ExternalDepositAmt, "account0 WETH balance after externalDeposit should DECREASE (transfer)");
        assertEq(weth.balanceOf(address(nayms)), dt.entity1ExternalDepositAmt, "nayms WETH balance after externalDeposit should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(DEFAULT_ACCOUNT0_ENTITY_ID, nWETH), dt.entity1ExternalDepositAmt, "entity0 nWETH balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(nWETH), dt.entity1ExternalDepositAmt, "nWETH total supply should INCREASE (1:1 internal mint)");

        // deposit into nayms vaults
        // note: the entity creator can deposit funds into an entity
        nayms.externalDeposit(entity1, address(weth), dt.entity1ExternalDepositAmt);
        assertEq(weth.balanceOf(account0), dt.entity1StartingBal - (dt.entity1ExternalDepositAmt * 2), "account0 WETH balance after externalDeposit should DECREASE (transfer)");
        assertEq(weth.balanceOf(address(nayms)), dt.entity1ExternalDepositAmt * 2, "nayms WETH balance after externalDeposit should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(DEFAULT_ACCOUNT0_ENTITY_ID, nWETH), dt.entity1ExternalDepositAmt, "entity0 nWETH balance should STAY THE SAME");

        assertEq(nayms.internalBalanceOf(entity1, nWETH), dt.entity1ExternalDepositAmt, "entity1 nWETH balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(nWETH), dt.entity1ExternalDepositAmt * 2, "nWETH total supply should INCREASE (1:1 internal mint)");

        // start a token sale: sell entity tokens for nWETH
        // when a token sale starts: entity tokens are minted to the entity,
        // 2nd param is the sell amount, 3rd param is the buy amount
        vm.recordLogs();
        // putting an offer on behalf of entity1 to sell their nENTITY1 for the entity's associated asset
        // 500 nENTITY1 for 500 nWETH, 1:1 ratio
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2);

        assertEq(entries[0].topics[0], keccak256("InternalTokenSupplyUpdate(bytes32,uint256,string,address)"));
        assertEq(entries[0].topics[1], entity1); // assert entity token
        (uint256 newSupply, string memory fName, ) = abi.decode(entries[0].data, (uint256, string, address));
        assertEq(fName, "_internalMint");
        assertEq(newSupply, dt.entity1MintAndSaleAmt);

        assertEq(entries[1].topics[0], keccak256("InternalTokenBalanceUpdate(bytes32,bytes32,uint256,string,address)"));
        (bytes32 tokenId, uint256 newSupply2, string memory fName2, ) = abi.decode(entries[1].data, (bytes32, uint256, string, address));
        assertEq(fName2, "_internalMint");
        assertEq(tokenId, entity1);
        assertEq(newSupply2, dt.entity1MintAndSaleAmt);

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
    }

    // note: a user can create an entity for other users

    function testDividendsAndFeesMarketIntegration() public {
        testStartTokenSale();

        // init test entities
        nayms.createEntity(entity1, signer1Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");
        nayms.createEntity(entity2, signer2Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");

        // fund the entities
        nayms.externalDepositToEntity(entity2, address(weth), dt.entity2ExternalDepositAmt);
        nayms.externalDepositToEntity(entity3, address(weth), dt.entity3ExternalDepositAmt);

        uint256 naymsBalanceBeforeTrade = nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), nWETH);

        vm.expectRevert("fee schedule invalid");
        vm.prank(signer2);
        nayms.executeLimitOffer(nWETH, buyAmount, entity1, buyAmount, 55);

        // Entity2 limit order: swap nWETH for nE1
        // buyAmount is equal to sellAmount from taker perspective, since price is 1 WETH

        nayms.executeLimitOffer(nWETH, dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt, LibConstants.FEE_SCHEDULE_STANDARD);
        assertEq(nayms.getLastOfferId(), 2, "lastOfferId should INCREASE after executeLimitOffer");

        nayms.cancelOffer(2);

        vm.expectRevert("offer not active");
        nayms.cancelOffer(2);

        nayms.executeLimitOffer(nWETH, buyAmount, entity1, buyAmount, LibConstants.FEE_SCHEDULE_STANDARD);
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
        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), nWETH), totalCommissions / 4, "NDF should get a trading commission");
        assertEq(
            nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), nWETH),
            totalCommissions / 4,
            "Staking mechanism should get a trading commission"
        );

        // assert Entity1 holds `buyAmount` of nE1
        assertEq(nayms.internalBalanceOf(entity2, entity1), dt.entity1MintAndSaleAmt);

        // pay dividend to nE1 holders (in nWETH)
        vm.startPrank(signer3);
        nayms.payDividendFromEntity(entity1, nWETH, dividendAmount);
        vm.stopPrank();

        // assert dividend bank balance
        assertEq(
            nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER), nWETH),
            dividendAmount,
            "dividend bank balance should increase after payment"
        );

        uint256 balanceBeforeDividend = nayms.internalBalanceOf(entity2, nWETH);

        // Entity2 withdraw dividend for owning a share of nE1
        nayms.withdrawDividend(entity2, entity1, nWETH);

        // assert dividend withdrawn
        uint256 actualDividentToWithdraw = (dividendAmount * dt.entity1MintAndSaleAmt) / nayms.internalTokenSupply(entity1);
        assertEq(nayms.internalBalanceOf(entity2, nWETH), balanceBeforeDividend + actualDividentToWithdraw);

        // assert dividend is not withdrawable twice!
        vm.expectRevert("_withdrawDividend: no dividend");
        nayms.withdrawDividend(entity2, entity1, nWETH);
        assertEq(nayms.internalBalanceOf(entity2, nWETH), balanceBeforeDividend + actualDividentToWithdraw);
    }

    function testMarketId() public {
        // whitelist underlying token
        nayms.addSupportedExternalToken(address(weth));

        nayms.createEntity(entity1, signer1Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");
        nayms.createEntity(entity2, signer2Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");
        nayms.createEntity(entity3, signer3Id, initEntity(weth, 500, 2000, 2000, true), "entity test hash");

        // init test entities
        writeTokenBalance(account0, address(nayms), address(weth), 100e18);

        nayms.externalDeposit(DEFAULT_ACCOUNT0_ENTITY_ID, address(weth), dt.entity1ExternalDepositAmt);
        nayms.externalDeposit(entity1, address(weth), dt.entity1ExternalDepositAmt);
        nayms.externalDeposit(entity2, address(weth), 10e18);
        nayms.externalDeposit(entity3, address(weth), dt.entity3ExternalDepositAmt);
        // deposit into nayms vaults
        // note: the entity creator can deposit funds into an entity

        // putting an offer on behalf of entity1 to sell their nENTITY1 for the entity's associated asset
        // 500 nENTITY1 for 500 nWETH, 1:1 ratio
        nayms.startTokenSale(entity1, dt.entity1MintAndSaleAmt, dt.entity1SalePrice);

        MarketInfo memory marketInfo1 = nayms.getOffer(1);
        assertEq(marketInfo1.creator, entity1, "creator");
        assertEq(marketInfo1.sellToken, entity1, "sell token");
        assertEq(marketInfo1.sellAmount, dt.entity1MintAndSaleAmt, "sell amount");
        assertEq(marketInfo1.sellAmountInitial, dt.entity1MintAndSaleAmt, "sell amount initial");
        assertEq(marketInfo1.buyToken, nWETH, "buy token");
        assertEq(marketInfo1.buyAmount, dt.entity1SalePrice, "buy amount");
        assertEq(marketInfo1.buyAmountInitial, dt.entity1SalePrice, "buy amount initial");
        assertEq(marketInfo1.state, LibConstants.OFFER_STATE_ACTIVE, "state");
        prettyGetOffer(1);

        MarketInfo memory marketInfo2 = nayms.getOffer(2);

        vm.prank(signer2);
        nayms.executeLimitOffer(nWETH, dt.entity1SalePrice, entity1, dt.entity1MintAndSaleAmt, LibConstants.FEE_SCHEDULE_STANDARD);
        // nayms.executeLimitOffer(entity2, nWETH, dt.entity1SalePrice * dt.entity1MintAndSaleAmt, entity1, dt.entity1MintAndSaleAmt, LibConstants.FEE_SCHEDULE_STANDARD);
        vm.stopPrank();

        marketInfo1 = nayms.getOffer(1);
        prettyGetOffer(1);
        assertEq(marketInfo1.creator, entity1, "creator");
        assertEq(marketInfo1.sellToken, entity1, "sell token");
        assertEq(marketInfo1.sellAmount, 0, "sell amount");
        assertEq(marketInfo1.sellAmountInitial, dt.entity1MintAndSaleAmt, "sell amount initial");
        assertEq(marketInfo1.buyToken, nWETH, "buy token");
        assertEq(marketInfo1.buyAmount, 0, "buy amount");
        assertEq(marketInfo1.buyAmountInitial, dt.entity1SalePrice, "buy amount initial");
        assertEq(marketInfo1.state, LibConstants.OFFER_STATE_FULFILLED, "state");
        marketInfo2 = nayms.getOffer(2);
        prettyGetOffer(2);
    }
    // executeLimitOffer() with a remaining amount of sell token, buy token
    // todo test order with two platform tokens, two entity tokens, eventually test with staking token (todo should this be allowed?)
}
