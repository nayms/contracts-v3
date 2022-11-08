// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers, LibObject } from "./defaults/D03ProtocolDefaults.sol";
import { AppStorage, Entity, FeeRatio, MarketInfo, TradingCommissions, TradingCommissionsBasisPoints } from "src/diamonds/nayms/AppStorage.sol";
import { LibFeeRouter } from "src/diamonds/nayms/libs/LibFeeRouter.sol";
import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { TradingCommissionsFixture, TradingCommissionsConfig } from "test/fixtures/TradingCommissionsFixture.sol";

contract T03TokenizedVaultTest is D03ProtocolDefaults {
    bytes32 internal nWETH;
    bytes32 internal nWBTC;
    bytes32 internal dividendBankId;

    bytes32 internal entity1 = bytes32("e5");
    bytes32 internal entity2 = bytes32("e6");
    bytes32 internal entity3 = bytes32("e7");

    uint256 internal constant collateralRatio_500 = 500;
    uint256 internal constant maxCapital_3000eth = 3_000 ether;
    uint256 internal constant totalLimit_2000eth = 2_000 ether;

    uint256 internal constant depositAmount = 2_000 ether;

    address public immutable david = vm.addr(0x11111D);
    address public immutable emily = vm.addr(0x11111E);
    address public immutable faith = vm.addr(0x11111F);

    bytes32 public immutable davidId = LibHelpers._getIdForAddress(vm.addr(0x11111D));
    bytes32 public immutable emilyId = LibHelpers._getIdForAddress(vm.addr(0x11111E));
    bytes32 public immutable faithId = LibHelpers._getIdForAddress(vm.addr(0x11111F));

    bytes32 internal eDavid;
    bytes32 internal eEmily;
    bytes32 internal eFaith;

    Entity internal entityWbtc;

    TradingCommissionsFixture internal tradingCommissionsFixture;
    TradingCommissionsConfig internal c;

    function setUp() public virtual override {
        super.setUp();
        nWETH = LibHelpers._getIdForAddress(wethAddress);
        nWBTC = LibHelpers._getIdForAddress(wbtcAddress);
        dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        nayms.addSupportedExternalToken(wbtcAddress);
        entityWbtc = Entity({
            assetId: LibHelpers._getIdForAddress(wbtcAddress),
            collateralRatio: LibConstants.BP_FACTOR,
            maxCapacity: 100 ether,
            utilizedCapacity: 0,
            simplePolicyEnabled: true
        });
        nayms.createEntity(bytes32("0x11111"), davidId, entityWbtc, "entity wbtc test hash");
        nayms.createEntity(bytes32("0x22222"), emilyId, entityWbtc, "entity wbtc test hash");
        nayms.createEntity(bytes32("0x33333"), faithId, entityWbtc, "entity wbtc test hash");

        eDavid = nayms.getEntity(davidId);
        eEmily = nayms.getEntity(emilyId);
        eFaith = nayms.getEntity(faithId);

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

    function testBasisPoints() public {
        TradingCommissionsBasisPoints memory bp = nayms.getTradingCommissionsBasisPoints();

        uint16 tradingCommissionNaymsLtdBP = 5000;
        uint16 tradingCommissionNDFBP = 2500;
        uint16 tradingCommissionSTMBP = 2500;
        uint16 tradingCommissionMakerBP; // init 0
        assertEq(bp.tradingCommissionNaymsLtdBP, tradingCommissionNaymsLtdBP);
        assertEq(bp.tradingCommissionNDFBP, tradingCommissionNDFBP);
        assertEq(bp.tradingCommissionSTMBP, tradingCommissionSTMBP);
        assertEq(bp.tradingCommissionMakerBP, tradingCommissionMakerBP);
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
        bytes32 acc0EntityId = nayms.getEntity(account0Id);
        console2.logBytes32(acc0EntityId);

        uint256 balanceAcc0 = nayms.internalBalanceOf(account0Id, nWETH);
        console2.log(balanceAcc0);
        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 0, "account0Id nWETH balance should start at 0");

        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);

        nayms.externalDeposit(account0Id, wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 1 ether, "account0Id nWETH balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(nWETH), 1 ether, "nWETH total supply should INCREASE (1:1 internal mint)");

        // note internalTransfer() transfers from the msg.sender's Id to the bytes32 Id given

        nayms.internalTransfer(entity1, nWETH, 1 ether);
        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 1 ether - 1 ether, "account0Id nWETH balance should DECREASE (transfer to entityId)");
        assertEq(nayms.internalBalanceOf(entity1, nWETH), 1 ether, "entity1Id nWETH balance should INCREASE (transfer from account0Id)");
        assertEq(nayms.internalTokenSupply(nWETH), 1 ether, "nWETH total supply should STAY THE SAME (transfer)");
    }

    function testSingleInternalTransferFromEntity() public {
        bytes32 acc0EntityId = nayms.getEntity(account0Id);

        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 0, "account0Id nWETH balance should start at 0");

        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);

        // note Depositing to account0's associated entity
        nayms.externalDepositToEntity(acc0EntityId, wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(acc0EntityId, nWETH), 1 ether, "account0's entityId (account0's parent) nWETH balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(nWETH), 1 ether, "nWETH total supply should INCREASE (1:1 internal mint)");

        // from parent of sender (address(this)) to
        nayms.internalTransferFromEntity(account0Id, nWETH, 1 ether);
        assertEq(nayms.internalBalanceOf(acc0EntityId, nWETH), 1 ether - 1 ether, "account0's entityId (account0's parent) nWETH balance should DECREASE (transfer to account0Id)");
        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 1 ether, "account0Id nWETH balance should INCREASE (transfer from acc0EntityId)");

        assertEq(nayms.internalTokenSupply(nWETH), 1 ether, "nWETH total supply should STAY THE SAME (transfer)");
    }

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

    function testPayDividendsWithZeroParticipationTokenSupply() public {
        bytes32 acc0EntityId = nayms.getEntity(account0Id);

        assertEq(nayms.internalBalanceOf(acc0EntityId, nWETH), 0, "account0Id nWETH balance should start at 0");

        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);

        nayms.externalDeposit(acc0EntityId, wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(acc0EntityId, nWETH), 1 ether, "account0Id nWETH balance should INCREASE (mint)");

        uint256 withdrawableDiv = nayms.getWithdrawableDividend(account0Id, nWETH, nWETH);
        // No withdrawable dividends.
        assertEq(withdrawableDiv, 0);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(acc0EntityId), 0, "Testing when the participation token supply is 0, but par token supply is NOT 0");

        bytes32 randomGuid = bytes32("0x1");
        nayms.payDividendFromEntity(randomGuid, 1 ether);
        // note: When the participation token supply is 0, payDividend() should transfer the payout directly to the payee
        assertEq(nayms.internalBalanceOf(acc0EntityId, nWETH), 1 ether, "acc0EntityId nWETH balance should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 1 ether - 1 ether, "account0Id nWETH balance should DECREASE (transfer)");
        assertEq(nayms.internalTokenSupply(nWETH), 1 ether, "nWETH total supply should STAY THE SAME");
    }

    // start token sale, pay dividend,
    function testPayDividendsWithNonZeroParticipationTokenSupply() public {
        bytes32 acc0EntityId = nayms.getEntity(account0Id);

        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 0, "account0Id nWETH balance should start at 0");

        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);

        nayms.externalDeposit(account0Id, wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 1 ether, "account0Id nWETH balance should INCREASE (mint)");

        // note Depositing to account0's associated entity

        uint256 withdrawableDiv = nayms.getWithdrawableDividend(account0Id, nWETH, nWETH);
        // No withdrawable dividends.
        assertEq(withdrawableDiv, 0);

        // note: starting a token sale which mints participation tokens
        nayms.startTokenSale(acc0EntityId, 1e18, 1e18);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(acc0EntityId), 1 ether, "");
        bytes32 randomGuid = bytes32("0x1");

        nayms.externalDepositToEntity(acc0EntityId, wethAddress, 1 ether);

        nayms.payDividendFromEntity(randomGuid, 1 ether);
        // note:When the participation token supply is non zero,
        assertEq(nayms.internalBalanceOf(acc0EntityId, nWETH), 0, "acc0EntityId nWETH balance should DECREASE (transfer)");
        assertEq(nayms.internalBalanceOf(account0Id, nWETH), 1 ether, "account0Id nWETH balance should STAY THE SAME");
        assertEq(nayms.internalTokenSupply(nWETH), 2 ether, "nWETH total supply should STAY THE SAME");

        assertEq(
            nayms.internalBalanceOf(dividendBankId, nWETH),
            1 ether,
            "The balance of the dividend bank should be non zero after payDividend() is called on a par token with a non zero supply."
        );

        assertEq(nayms.internalBalanceOf(signer1Id, nWETH), 0, "");
        nayms.externalDeposit(signer1Id, wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(signer1Id, nWETH), 1 ether, "");

        vm.prank(signer1);
        bytes32 signer1EntityId = nayms.getEntity(signer1Id);

        // give signer1's entity nWETH
        nayms.externalDeposit(signer1EntityId, wethAddress, 2 ether);
        assertEq(nayms.internalBalanceOf(signer1EntityId, nWETH), 2 ether, "signer1EntityId nWETH balance should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(signer1Id, nWETH), 1 ether, "signer1Id nWETH balance should STAY THE SAME");
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 1 ether, "dividendBankId nWETH balance should STAY THE SAME");
        assertEq(nayms.internalTokenSupply(nWETH), 5 ether, "nWETH total supply should INCREASE (mint)");

        // the taker's buy amount
        uint256 takerBuyAmount = 1 ether;
        vm.prank(signer1);
        nayms.executeLimitOffer(nWETH, 1 ether, acc0EntityId, takerBuyAmount);

        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 1 ether - 1 ether, "The dividend should've been transfered when executeLimitOffer() is called and executed");

        assertEq(
            nayms.internalBalanceOf(acc0EntityId, nWETH),
            2 ether,
            "account0's entity should've received 1 ether from dividends and 1 ether from their order being filled for their participation tokens"
        );
        nayms.internalBalanceOf(signer1Id, nWETH); // no change

        nayms.withdrawDividend(acc0EntityId, nWETH, nWETH);
        nayms.withdrawAllDividends(account0Id, nWETH);
        assertEq(nayms.internalBalanceOf(acc0EntityId, nWETH), 2 ether, "acc0EntityId nWETH balance should STAY THE SAME");

        TradingCommissions memory tc = nayms.calculateTradingCommissions(takerBuyAmount);

        bytes32 naymsLtdId = LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER);
        bytes32 ndfId = LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER);
        bytes32 stakingId = LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER);
        assertEq(nayms.internalBalanceOf(naymsLtdId, nWETH), tc.commissionNaymsLtd, "balance of naymsLtd should have INCREASED (trading commissions)");
        assertEq(nayms.internalBalanceOf(ndfId, nWETH), tc.commissionNDF, "balance of ndfId should have INCREASED (trading commissions)");
        assertEq(nayms.internalBalanceOf(stakingId, nWETH), tc.commissionSTM, "balance of stakingId should have INCREASED (trading commissions)");

        // the amount the taker receives from the matching order
        uint256 calculatedTakerAmount = takerBuyAmount - tc.totalCommissions;
        assertEq(nayms.internalBalanceOf(signer1EntityId, nWETH), calculatedTakerAmount, "balance of signer1's entity should be the their buy amount minus the commission fees"); // order filled minus trading commissions)
    }

    function testMultipleDepositDividend() public {
        // naming conventions for this test:
        // alice == account0
        // aliceId == account0Id
        // eAlice == account0's parent, aka entity
        // bob == signer1
        // bobId == signer1Id
        // nBob == signer1's parent, aka entity

        address alice = account0;
        address bob = signer1;
        bytes32 eAlice = nayms.getEntity(account0Id);
        bytes32 eBob = nayms.getEntity(signer1Id);

        writeTokenBalance(alice, naymsAddress, wethAddress, depositAmount);

        // note: starting a token sale which mints participation tokens
        nayms.startTokenSale(eAlice, 1e18, 1e18);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(eAlice), 1e18, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(eAlice, eAlice), 1e18, "eAlice's eAlice balance should INCREASE (mint)");

        bytes32 randomGuid = bytes32("0x1");
        nayms.externalDepositToEntity(eAlice, wethAddress, 1 ether);
        assertEq(nayms.internalTokenSupply(nWETH), 1 ether, "nWETH token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 1 ether, "eAlice's nWETH balance should INCREASE (deposit)");

        nayms.payDividendFromEntity(randomGuid, 1 ether); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 1 ether - 1 ether, "eAlice's nWETH balance should DECREASE (transfer to dividend bank)");

        assertEq(
            nayms.internalBalanceOf(dividendBankId, nWETH),
            1 ether,
            "The balance of the dividend bank should be non zero after payDividend() is called on a par token with a non zero supply."
        );

        uint256 takerBuyAmount = 1e18;
        console2.log(nayms.getBalanceOfTokensForSale(eAlice, eAlice));

        TradingCommissions memory tc = nayms.calculateTradingCommissions(takerBuyAmount);

        nayms.externalDepositToEntity(eBob, wethAddress, 1 ether + tc.totalCommissions);
        assertEq(nayms.internalBalanceOf(eBob, nWETH), 1 ether + tc.totalCommissions, "eBob's nWETH balance should INCREASE");

        vm.prank(bob);
        nayms.executeLimitOffer(nWETH, 1 ether, eAlice, 1e18);

        assertEq(nayms.internalBalanceOf(eBob, nWETH), 0, "eBob's nWETH balance should DECREASE");
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 2 ether, "eAlice's nWETH balance should INCREASE");

        bytes32 naymsLtdId = LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER);
        bytes32 ndfId = LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER);
        bytes32 stakingId = LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER);
        assertEq(nayms.internalBalanceOf(naymsLtdId, nWETH), tc.commissionNaymsLtd, "balance of naymsLtd should have INCREASED (trading commissions)");
        assertEq(nayms.internalBalanceOf(ndfId, nWETH), tc.commissionNDF, "balance of ndfId should have INCREASED (trading commissions)");
        assertEq(nayms.internalBalanceOf(stakingId, nWETH), tc.commissionSTM, "balance of stakingId should have INCREASED (trading commissions)");
    }

    function testMultipleDepositDividendWithdraw() public {
        address alice = account0;
        bytes32 eAlice = nayms.getEntity(account0Id);
        address bob = signer1;
        bytes32 eBob = nayms.getEntity(signer1Id);
        address charlie = signer2;
        bytes32 eCharlie = nayms.getEntity(signer2Id);

        writeTokenBalance(alice, naymsAddress, wethAddress, depositAmount);

        nayms.externalDepositToEntity(eAlice, wethAddress, 80_000); // to be used for dividend payments

        nayms.externalDepositToEntity(eBob, wethAddress, 3_000 + nayms.calculateTradingCommissions(3_000).totalCommissions);
        nayms.externalDepositToEntity(eCharlie, wethAddress, 17_000 + nayms.calculateTradingCommissions(17_000).totalCommissions);

        assertEq(nayms.internalBalanceOf(eBob, nWETH), 3_000 + nayms.calculateTradingCommissions(3_000).totalCommissions);
        // note: starting a token sale which mints participation tokens
        nayms.startTokenSale(eAlice, 20_000, 20_000);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(eAlice), 20_000, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(eAlice, eAlice), 20_000, "eAlice's eAlice balance should INCREASE (mint)");

        vm.prank(bob);
        nayms.executeLimitOffer(nWETH, 3_000, eAlice, 3_000); // 1:1 purchase price

        vm.prank(charlie);
        nayms.executeLimitOffer(nWETH, 17_000, eAlice, 17_000); // 1:1 purchase price

        assertEq(nayms.internalBalanceOf(eBob, eAlice), 3_000);
        assertEq(nayms.internalBalanceOf(eCharlie, eAlice), 17_000);

        bytes32 randomGuid = bytes32("0x1");
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 100_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 0);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 0);

        nayms.payDividendFromEntity(randomGuid, 40_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 60_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 40_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 6_000);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 34_000);

        nayms.payDividendFromEntity(randomGuid, 60_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 0);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 100_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 15_000);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 85_000);

        nayms.withdrawDividend(eBob, eAlice, nWETH);
        assertEq(nayms.internalBalanceOf(eBob, nWETH), 15_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 85_000);

        nayms.withdrawDividend(eCharlie, eAlice, nWETH);
        assertEq(nayms.internalBalanceOf(eBob, nWETH), 15_000);
        assertEq(nayms.internalBalanceOf(eCharlie, nWETH), 85_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 0);

        weth.balanceOf(bob);
    }

    function testMultipleDepositDividendWithdrawWithTwoDividendTokens() public {
        address alice = account0;
        bytes32 eAlice = nayms.getEntity(account0Id);
        address bob = signer1;
        bytes32 eBob = nayms.getEntity(signer1Id);
        address charlie = signer2;
        bytes32 eCharlie = nayms.getEntity(signer2Id);

        writeTokenBalance(alice, naymsAddress, wethAddress, depositAmount);
        writeTokenBalance(alice, naymsAddress, wbtcAddress, depositAmount);

        nayms.externalDepositToEntity(eAlice, wethAddress, 80_000); // to be used for dividend payments
        nayms.externalDepositToEntity(eDavid, wbtcAddress, 80_000); // to be used for dividend payments

        nayms.externalDepositToEntity(eBob, wethAddress, 3_000 + nayms.calculateTradingCommissions(3_000).totalCommissions);
        nayms.externalDepositToEntity(eCharlie, wethAddress, 17_000 + nayms.calculateTradingCommissions(17_000).totalCommissions);
        nayms.externalDepositToEntity(eEmily, wbtcAddress, 3_000 + nayms.calculateTradingCommissions(3_000).totalCommissions);
        nayms.externalDepositToEntity(eFaith, wbtcAddress, 17_000 + nayms.calculateTradingCommissions(17_000).totalCommissions);

        assertEq(nayms.internalBalanceOf(eBob, nWETH), 3_000 + nayms.calculateTradingCommissions(3_000).totalCommissions);
        assertEq(nayms.internalBalanceOf(eEmily, nWBTC), 3_000 + nayms.calculateTradingCommissions(3_000).totalCommissions);

        // note: starting a token sale which mints participation tokens
        nayms.startTokenSale(eAlice, 20_000, 20_000);
        nayms.startTokenSale(eDavid, 20_000, 20_000);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(eAlice), 20_000, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(eAlice, eAlice), 20_000, "eAlice's eAlice balance should INCREASE (mint)");
        assertEq(nayms.internalTokenSupply(eDavid), 20_000, "eDavid participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(eDavid, eDavid), 20_000, "eDavid's eDavid balance should INCREASE (mint)");

        vm.prank(bob);
        nayms.executeLimitOffer(nWETH, 3_000, eAlice, 3_000); // 1:1 purchase price

        vm.prank(charlie);
        nayms.executeLimitOffer(nWETH, 17_000, eAlice, 17_000); // 1:1 purchase price

        vm.prank(emily);
        nayms.executeLimitOffer(nWBTC, 3_000, eDavid, 3_000); // 1:1 purchase price

        vm.prank(faith);
        nayms.executeLimitOffer(nWBTC, 17_000, eDavid, 17_000); // 1:1 purchase price

        assertEq(nayms.internalBalanceOf(eBob, eAlice), 3_000);
        assertEq(nayms.internalBalanceOf(eCharlie, eAlice), 17_000);
        assertEq(nayms.internalBalanceOf(eEmily, eDavid), 3_000);
        assertEq(nayms.internalBalanceOf(eFaith, eDavid), 17_000);

        bytes32 randomGuid = bytes32("0x1");
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 100_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 0);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 0);

        nayms.payDividendFromEntity(randomGuid, 40_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 60_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 40_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 6_000);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 34_000);

        nayms.payDividendFromEntity(randomGuid, 60_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 0);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 100_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 15_000);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 85_000);

        // eDavid, eEmily, eFaith
        assertEq(nayms.getWithdrawableDividend(eEmily, eDavid, nWETH), 0);
        assertEq(nayms.getWithdrawableDividend(eFaith, eDavid, nWETH), 0);

        assertEq(nayms.internalBalanceOf(eDavid, nWBTC), 100_000);
        vm.prank(david);
        nayms.payDividendFromEntity(randomGuid, 40_000); // eDavid is paying out a dividend
        assertEq(nayms.internalBalanceOf(eDavid, nWBTC), 60_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWBTC), 40_000);

        assertEq(nayms.getWithdrawableDividend(eEmily, eDavid, nWBTC), 6_000);
        assertEq(nayms.getWithdrawableDividend(eFaith, eDavid, nWBTC), 34_000);

        vm.prank(david);
        nayms.payDividendFromEntity(randomGuid, 60_000); // eDavid is paying out a dividend
        assertEq(nayms.internalBalanceOf(eDavid, nWBTC), 0);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWBTC), 100_000);

        assertEq(nayms.getWithdrawableDividend(eEmily, eDavid, nWBTC), 15_000);
        assertEq(nayms.getWithdrawableDividend(eFaith, eDavid, nWBTC), 85_000);

        nayms.withdrawDividend(eBob, eAlice, nWETH);
        assertEq(nayms.internalBalanceOf(eBob, nWETH), 15_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 85_000);

        nayms.withdrawDividend(eCharlie, eAlice, nWETH);
        assertEq(nayms.internalBalanceOf(eBob, nWETH), 15_000);
        assertEq(nayms.internalBalanceOf(eCharlie, nWETH), 85_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 0);

        nayms.withdrawDividend(eEmily, eDavid, nWBTC);
        assertEq(nayms.internalBalanceOf(eEmily, nWBTC), 15_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWBTC), 85_000);

        nayms.withdrawDividend(eFaith, eDavid, nWBTC);
        assertEq(nayms.internalBalanceOf(eEmily, nWBTC), 15_000);
        assertEq(nayms.internalBalanceOf(eFaith, nWBTC), 85_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWBTC), 0);
    }

    function testDepositAndBurn() public {
        address alice = account0;
        bytes32 eAlice = nayms.getEntity(account0Id);
        address bob = signer1;
        bytes32 eBob = nayms.getEntity(signer1Id);
        address charlie = signer2;
        bytes32 eCharlie = nayms.getEntity(signer2Id);

        writeTokenBalance(alice, naymsAddress, wethAddress, depositAmount);

        nayms.externalDepositToEntity(eAlice, wethAddress, 80_000); // to be used for dividend payments

        nayms.externalDepositToEntity(eBob, wethAddress, 3_000 + nayms.calculateTradingCommissions(3_000).totalCommissions);
        nayms.externalDepositToEntity(eCharlie, wethAddress, 17_000 + nayms.calculateTradingCommissions(17_000).totalCommissions);

        assertEq(nayms.internalBalanceOf(eBob, nWETH), 3_000 + nayms.calculateTradingCommissions(3_000).totalCommissions);
        // note: starting a token sale which mints participation tokens
        nayms.startTokenSale(eAlice, 20_000, 20_000);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(eAlice), 20_000, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(eAlice, eAlice), 20_000, "eAlice's eAlice balance should INCREASE (mint)");

        vm.prank(bob);
        nayms.executeLimitOffer(nWETH, 3_000, eAlice, 3_000); // 1:1 purchase price

        vm.prank(charlie);
        nayms.executeLimitOffer(nWETH, 17_000, eAlice, 17_000); // 1:1 purchase price

        assertEq(nayms.internalBalanceOf(eBob, eAlice), 3_000);
        assertEq(nayms.internalBalanceOf(eCharlie, eAlice), 17_000);

        bytes32 randomGuid = bytes32("0x1");
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 100_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 0);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 0);

        nayms.payDividendFromEntity(randomGuid, 40_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 60_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 40_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 6_000);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 34_000);

        nayms.payDividendFromEntity(randomGuid, 60_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(eAlice, nWETH), 0);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 100_000);

        assertEq(nayms.getWithdrawableDividend(eBob, eAlice, nWETH), 15_000);
        assertEq(nayms.getWithdrawableDividend(eCharlie, eAlice, nWETH), 85_000);

        assertEq(nayms.internalBalanceOf(eBob, nWETH), 0);

        nayms.internalBurn(eBob, eAlice, 3_000);

        assertEq(nayms.internalBalanceOf(eBob, nWETH), 15_000);

        nayms.withdrawAllDividends(eBob, eAlice);
        // nayms.withdrawDividend(eBob, eAlice, nWETH);
        assertEq(nayms.internalBalanceOf(eBob, nWETH), 15_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 85_000);

        // nayms.withdrawDividend(eCharlie, eAlice, nWETH);
        // assertEq(nayms.internalBalanceOf(eBob, nWETH), 15_000);
        // assertEq(nayms.internalBalanceOf(eCharlie, nWETH), 85_000);
        // assertEq(nayms.internalBalanceOf(dividendBankId, nWETH), 0);

        // weth.balanceOf(bob);
    }

    function scopeToDefaults(uint256 _input) internal {
        scopeTo(_input, 1_000, 1_000_000_000_000 ether);
    }

    function scopeTo(
        uint256 _input,
        uint256 _min,
        uint256 _max
    ) internal {
        vm.assume(_input <= _max);
        vm.assume(_input >= _min);
    }

    function testFuzzWithdrawableDividends(
        uint256 _parTokenSupply,
        uint256 _holdersShare,
        uint256 _dividendAmount
    ) public {
        // -- Test Case -----------------------------
        // 1. start token sale
        // 2. distribute dividends
        // 3. purchase participation tokens
        // 4. taker SHOULD NOT have withdrawable dividend
        // 5. distribute another round of dividends
        // 6. SHOULD have withdrawable dividends now!
        // ------------------------------------------

        // scope input values
        scopeToDefaults(_parTokenSupply);
        scopeTo(_holdersShare, 1, 100);
        scopeTo(_dividendAmount, 1, _parTokenSupply);

        // prettier-ignore
        Entity memory e = Entity({ 
            assetId: nWETH, 
            collateralRatio: 1_000, 
            maxCapacity: _parTokenSupply, 
            utilizedCapacity: 0, 
            simplePolicyEnabled: true 
        });

        bytes32 entity0Id = bytes32("0xe1");
        bytes32 entity1Id = bytes32("0xe2");
        nayms.createEntity(entity0Id, account0Id, e, "test");
        nayms.createEntity(entity1Id, signer1Id, e, "test");

        // 1. ---- start token sale ----

        nayms.startTokenSale(entity0Id, _parTokenSupply, _parTokenSupply);
        assertEq(nayms.internalTokenSupply(entity0Id), _parTokenSupply, "Entity 1 participation tokens should be minted");

        // 2. ---- distribute dividends ----

        // fund entity0 to distribute as dividends
        writeTokenBalance(account0, naymsAddress, wethAddress, _dividendAmount * 2);
        assertEq(nayms.internalBalanceOf(entity0Id, nWETH), 0, "entity0 nWETH balance should start at 0");
        nayms.externalDeposit(entity0Id, wethAddress, _dividendAmount);
        assertEq(nayms.internalBalanceOf(entity0Id, nWETH), _dividendAmount, "entity0 nWETH balance should INCREASE (mint)");

        // distribute dividends to entity0 shareholders
        bytes32 guid = bytes32("0xc0ffee");
        nayms.payDividendFromEntity(guid, _dividendAmount);

        // entity1 has no share, thus no withdrawable dividend at this point
        vm.startPrank(signer1);
        uint256 entity1Div = nayms.getWithdrawableDividend(entity1Id, nWETH, nWETH);
        assertEq(entity1Div, 0, "Entity 1 has no tokens, so should NOT have dividend to claim");
        vm.stopPrank();

        // 3.  ---- purchase participation tokens  ----

        // fund entity1 to by par-tokens
        uint256 takeAmount = (_parTokenSupply * _holdersShare) / 100;
        uint256 commissionAmount = (takeAmount * c.tradingCommissionTotalBP) / 1000;
        writeTokenBalance(account0, naymsAddress, wethAddress, takeAmount + commissionAmount);
        nayms.externalDeposit(entity1Id, wethAddress, takeAmount + commissionAmount);
        assertEq(nayms.internalBalanceOf(entity1Id, nWETH), takeAmount + commissionAmount, "entity1 nWETH balance should INCREASE (mint)");
        console2.log(" -- e1 balance: ", nayms.internalBalanceOf(entity1Id, nWETH));

        // place order, get the tokens
        vm.startPrank(signer1);
        nayms.executeLimitOffer(nWETH, takeAmount, entity0Id, takeAmount);
        assertEq(nayms.internalBalanceOf(entity1Id, entity0Id), takeAmount, "entity1 SHOULD have entity0-tokens in his balance");
        vm.stopPrank();

        // 4.  ---- SHOULD NOT have withdrawable dividend  ----

        // withdrawable divident should still be zero!
        vm.startPrank(signer1);
        uint256 entity1DivAfterPurchase = nayms.getWithdrawableDividend(entity1Id, entity0Id, nWETH);
        assertEq(entity1DivAfterPurchase, 0, "Entity 1 should NOT have dividend to claim here!");
        vm.stopPrank();

        // 5.  ---- distribute another round of dividends  ----

        bytes32 guid2 = bytes32("0xbEEf");
        nayms.payDividendFromEntity(guid2, _dividendAmount);

        // 6.  ---- SHOULD have more withdrawable dividends now!  ----

        uint256 expectedDividend = (_dividendAmount * takeAmount) / _parTokenSupply;
        vm.startPrank(signer1);
        uint256 entity1DivAfter2Purchase = nayms.getWithdrawableDividend(entity1Id, entity0Id, nWETH);

        // tolerate rounding errors
        uint256 absDiff = entity1DivAfter2Purchase > expectedDividend ? entity1DivAfter2Purchase - expectedDividend : expectedDividend - entity1DivAfter2Purchase;
        assertTrue(absDiff <= 1, "Entity 1 should have a dividend to claim here!");

        vm.stopPrank();
    }

    function testWithdrawableDividenWhenPurchasedAfterDistribution() public {
        // test specific values
        testFuzzWithdrawableDividends(1_000 ether, 10, 100 ether);
    }

    // note withdrawAllDividends() will still succeed even if there are 0 dividends to be paid out,
    // while withdrawDividend() will revert
}
