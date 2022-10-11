// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, FeeRatio, MarketInfo } from "src/diamonds/nayms/interfaces/FreeStructs.sol";

contract T03TokenizedVaultTest is D03ProtocolDefaults {
    bytes32 internal nWETH;
    bytes32 internal dividendBankId;

    bytes32 internal entity1 = bytes32("e5");
    bytes32 internal entity2 = bytes32("e6");
    bytes32 internal entity3 = bytes32("e7");

    uint256 internal constant collateralRatio_500 = 500;
    uint256 internal constant maxCapital_3000eth = 3_000 ether;
    uint256 internal constant totalLimit_2000eth = 2_000 ether;

    uint256 internal constant depositAmount = 2_000 ether;

    function setUp() public virtual override {
        super.setUp();
        nWETH = LibHelpers._getIdForAddress(wethAddress);
        dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);
    }

    function testSingleExternalDeposit() public {
        nayms.createEntity(entity1, signer1Id, initEntity(weth, collateralRatio_500, maxCapital_3000eth, totalLimit_2000eth, true), "entity test hash");
        nayms.createEntity(entity2, signer2Id, initEntity(weth, collateralRatio_500, maxCapital_3000eth, totalLimit_2000eth, true), "entity test hash");

        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);

        uint256 externalDepositAmount = depositAmount / 5;

        // note: deposits must be an exisiting entity: s.existingEntities[_receiverId]
        vm.expectRevert("extDeposit: invalid receiver");
        nayms.externalDepositToEntity(dividendBankId, wethAddress, 1);

        // deposit to entity1
        nayms.externalDeposit(entity1, wethAddress, externalDepositAmount);
        assertEq(weth.balanceOf(account0), depositAmount - externalDepositAmount, "account0 WETH balance after externalDeposit should DECREASE (transfer)");
        assertEq(weth.balanceOf(naymsAddress), externalDepositAmount, "nayms WETH balance after externalDeposit should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(entity1, nWETH), externalDepositAmount, "entity1 nWETH balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(nWETH), externalDepositAmount, "nWETH total supply should INCREASE (1:1 internal mint)");

        // deposit to entity2
        nayms.externalDeposit(entity2, wethAddress, externalDepositAmount);
        assertEq(weth.balanceOf(account0), depositAmount - externalDepositAmount * 2, "account0 WETH balance after externalDeposit should DECREASE (transfer)");
        assertEq(weth.balanceOf(naymsAddress), externalDepositAmount * 2, "nayms WETH balance after externalDeposit should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(entity2, nWETH), externalDepositAmount, "entity2 nWETH balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(nWETH), externalDepositAmount * 2, "nWETH total supply should INCREASE (1:1 internal mint)");
    }

    function testSingleInternalTransfer() public {
        testSingleExternalDeposit();
        // todo
    }

    // function testFuzzExternalDeposit(
    //     bytes32 account0Id,
    //     bytes32 account0Id,
    //     uint256 depositAmount
    // ) public {
    //     Entity memory entityInfo;
    //     // LibConstants.ROLE_UNDERWRITER
    //     nayms.createEntity(account0Id, objectContext1, entityInfo, "entity test hash");

    //     // if account0Id == account0Id, createEntity will revert
    //     vm.assume(account0Id != account0Id);

    //     nayms.createEntity(account0Id, objectContext1, entityInfo, "entity test hash");

    //     weth.approve(naymsAddress, depositAmount);
    //     address assetAddress = wethAddress;
    //     writeTokenBalance(account0, assetAddress, depositAmount);
    //     assertEq(weth.balanceOf(account0), depositAmount);

    //     if (account0Id == "") {
    //         vm.expectRevert("MultiToken: mint to zero address");
    //         nayms.externalDeposit(account0Id, assetAddress, depositAmount);
    //     } else {
    //         nayms.externalDeposit(account0Id, assetAddress, depositAmount);
    //     }

    //     // get balance of weth
    //     assertEq(weth.balanceOf(account0), 0);
    //     assertEq(weth.balanceOf(naymsAddress), depositAmount);

    //     // get balance of object
    //     assertEq(nayms.internalBalanceOf(account0Id, nWETH), depositAmount);

    //     // get total supply of naymsVaultToken
    //     assertEq(nayms.internalTokenSupply(nWETH), depositAmount);
    // }

    function testSingleExternalWithdraw() public {
        testSingleExternalDeposit();

        uint256 account0WethBalanceAccount0 = weth.balanceOf(account0);
        uint256 naymsWethBalancePre = weth.balanceOf(naymsAddress);
        uint256 entity1WethInternalBalance = nayms.internalBalanceOf(entity1, nWETH);
        uint256 naymsWethInternalTokenSupply = nayms.internalTokenSupply(nWETH);

        vm.prank(signer1);
        nayms.externalWithdrawFromEntity(entity1, account0, wethAddress, 100);

        assertEq(weth.balanceOf(account0), account0WethBalanceAccount0 + 100, "account0 got WETH");
        assertEq(weth.balanceOf(naymsAddress), naymsWethBalancePre - 100, "nayms lost WETH");
        assertEq(nayms.internalBalanceOf(entity1, nWETH), entity1WethInternalBalance - 100, "entity1 lost internal WETH");
        assertEq(nayms.internalTokenSupply(nWETH), naymsWethInternalTokenSupply - 100, "nayms burned internal WETH");
    }

    function TODO_testPayAndWithdrawDividendForEntity() public {
        bytes32 entity0Token = DEFAULT_ACCOUNT0_ENTITY_ID;
        uint256 saleAmount = 100 ether;

        writeTokenBalance(account0, naymsAddress, wethAddress, saleAmount);

        // complete a market token sale: entity2 will hold 50% of Entity0 tokens, entity2 holds the other 50%
        nayms.startTokenSale(DEFAULT_ACCOUNT0_ENTITY_ID, saleAmount, saleAmount);

        nayms.createEntity(entity1, signer1Id, initEntity(weth, collateralRatio_500, maxCapital_3000eth, totalLimit_2000eth, true), "entity test hash");
        nayms.externalDepositToEntity(entity1, wethAddress, saleAmount / 2);
        // vm.prank(signer1);
        // nayms.executeLimitOffer(nWETH, saleAmount / 2, entity0Token, saleAmount / 2, LibConstants.FEE_SCHEDULE_STANDARD);

        // nayms.createEntity(entity2, signer2Id, initEntity(weth, collateralRatio_500, maxCapital_3000eth, totalLimit_2000eth, true), "entity test hash");
        // nayms.externalDepositToEntity(entity2, wethAddress, saleAmount / 2);
        // vm.prank(signer2);
        // nayms.executeLimitOffer(nWETH, saleAmount / 2, entity0Token, saleAmount / 2, LibConstants.FEE_SCHEDULE_STANDARD);

        // assertEq(nayms.internalBalanceOf(entity1, entity0Token), saleAmount / 2, "entity1 should be an entity0 token hoder");
        // assertEq(nayms.internalBalanceOf(entity2, entity0Token), saleAmount / 2, "entity2 should be an entity0 token hoder");

        // pay dividend to entity0 token holders (in nWETH)
        // uint256 dividendAmount = 10 ether;
        // nayms.payDividendFromEntity(entity0Token, nWETH, dividendAmount);

        // // assert dividend bank balance
        // assertEq(
        //     nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER), nWETH),
        //     dividendAmount,
        //     "dividend bank balance should increase after payment"
        // );

        // uint256 entity1BalanceBeforeDividend = nayms.internalBalanceOf(entity1, nWETH);
        // uint256 entity2BalanceBeforeDividend = nayms.internalBalanceOf(entity2, nWETH);

        // // Entity1 withdraw dividend for owning a share of entity0 tokens
        // nayms.withdrawDividend(entity1, entity0Token, nWETH);
        // nayms.withdrawDividend(entity2, entity0Token, nWETH);

        // // assert dividend withdrawn
        // uint256 actualDividendToWithdraw = (dividendAmount / 2); // since entity1 and entity2 each hold 50% of entity0 tokens
        // assertEq(nayms.internalBalanceOf(entity1, nWETH), entity1BalanceBeforeDividend + actualDividendToWithdraw);
        // assertEq(nayms.internalBalanceOf(entity2, nWETH), entity2BalanceBeforeDividend + actualDividendToWithdraw);

        // // assert dividend is not withdrawable twice!
        // vm.expectRevert("_withdrawDividend: no dividend");
        // nayms.withdrawDividend(entity1, entity0Token, nWETH);
        // assertEq(nayms.internalBalanceOf(entity1, nWETH), entity1BalanceBeforeDividend + actualDividendToWithdraw);
    }
}
