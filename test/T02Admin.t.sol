// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";
import { Vm } from "forge-std/Vm.sol";
import { TradingCommissionsBasisPoints, PolicyCommissionsBasisPoints } from "../src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms, IDiamondCut, IEntityFacet, IMarketFacet, ITokenizedVaultFacet, ITokenizedVaultIOFacet, ISimplePolicyFacet } from "src/diamonds/nayms/INayms.sol";
import { LibFeeRouterFixture } from "./fixtures/LibFeeRouterFixture.sol";
import "src/diamonds/nayms/interfaces/CustomErrors.sol";

contract T02AdminTest is D03ProtocolDefaults, MockAccounts {
    LibFeeRouterFixture internal libFeeRouterFixture = new LibFeeRouterFixture();

    function setUp() public virtual override {
        super.setUp();

        libFeeRouterFixture = new LibFeeRouterFixture();
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](5);
        functionSelectors[0] = libFeeRouterFixture.payPremiumCommissions.selector;
        functionSelectors[1] = libFeeRouterFixture.payTradingCommissions.selector;
        functionSelectors[2] = libFeeRouterFixture.calculateTradingCommissionsFixture.selector;
        functionSelectors[3] = libFeeRouterFixture.getTradingCommissionsBasisPointsFixture.selector;
        functionSelectors[4] = libFeeRouterFixture.getPremiumCommissionBasisPointsFixture.selector;

        // Diamond cut this fixture contract into our nayms diamond in order to test against the diamond
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(libFeeRouterFixture), action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        nayms.diamondCut(cut, address(0), "");
    }

    function testGetSystemId() public {
        assertEq(nayms.getSystemId(), LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER));
    }

    function testGetMaxDividendDenominationsDefaultValue() public {
        assertEq(nayms.getMaxDividendDenominations(), 1);
    }

    function testSetMaxDividendDenominationsFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.setMaxDividendDenominations(100);
        vm.stopPrank();
    }

    function testSetMaxDividendDenominationsFailIfLowerThanBefore() public {
        nayms.setMaxDividendDenominations(2);

        vm.expectRevert("_updateMaxDividendDenominations: cannot reduce");
        nayms.setMaxDividendDenominations(2);

        nayms.setMaxDividendDenominations(3);
    }

    function testSetMaxDividendDenominations() public {
        uint256 orig = nayms.getMaxDividendDenominations();

        vm.recordLogs();

        nayms.setMaxDividendDenominations(100);
        assertEq(nayms.getMaxDividendDenominations(), 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("MaxDividendDenominationsUpdated(uint8,uint8)"));
        (uint8 oldV, uint8 newV) = abi.decode(entries[0].data, (uint8, uint8));
        assertEq(oldV, orig);
        assertEq(newV, 100);
    }

    function testAddSupportedExternalTokenFailIfNotAdmin() public {
        vm.startPrank(account1);
        vm.expectRevert("not a system admin");
        nayms.addSupportedExternalToken(wethAddress);
        vm.stopPrank();
    }

    function testAddSupportedExternalTokenFailIfTokenAddressHasNoCode() public {
        vm.expectRevert("LibERC20: ERC20 token address has no code");
        nayms.addSupportedExternalToken(address(0xdddddaaaaa));
    }

    function testAddSupportedExternalToken() public {
        address[] memory orig = nayms.getSupportedExternalTokens();

        vm.recordLogs();

        nayms.addSupportedExternalToken(wbtcAddress);
        address[] memory v = nayms.getSupportedExternalTokens();
        assertEq(v.length, orig.length + 1);
        assertEq(v[v.length - 1], wbtcAddress);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("SupportedTokenAdded(address)"));
        address tok = abi.decode(entries[0].data, (address));
        assertEq(tok, wbtcAddress);
    }

    function testIsSupportedToken() public {
        bytes32 id = LibHelpers._getIdForAddress(wbtcAddress);

        assertFalse(nayms.isSupportedExternalToken(id));

        nayms.addSupportedExternalToken(wbtcAddress);

        assertTrue(nayms.isSupportedExternalToken(id));
    }

    function testAddSupportedExternalTokenIfAlreadyAdded() public {
        address[] memory orig = nayms.getSupportedExternalTokens();

        vm.recordLogs();

        nayms.addSupportedExternalToken(wbtcAddress);
        nayms.addSupportedExternalToken(wbtcAddress);

        address[] memory v = nayms.getSupportedExternalTokens();
        assertEq(v.length, orig.length + 1);
        assertEq(v[v.length - 1], wbtcAddress);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("SupportedTokenAdded(address)"));
    }

    function testAddSupportedExternalTokenIfWrapper() public {
        bytes32 entityId1 = "0xe1";
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5_000, 30_000, true), "test");
        nayms.enableEntityTokenization(entityId1, "E1", "E1 Token");
        nayms.startTokenSale(entityId1, 100 ether, 100 ether);

        vm.recordLogs();

        nayms.wrapToken(entityId1);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "TokenWrapped: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("TokenWrapped(bytes32,address)"), "TokenWrapped: Invalid event signature");
        assertEq(entries[0].topics[1], entityId1, "TokenWrapped: incorrect tokenID"); // assert entity token
        address loggedWrapperAddress = abi.decode(entries[0].data, (address));

        vm.expectRevert("cannot add participation token wrapper as external");
        nayms.addSupportedExternalToken(loggedWrapperAddress);
    }

    function testSetTradingCommissionsBasisPoints() public {
        
        // total must be > 0 and < 10_000
        vm.expectRevert("invalid trading commission total");
        nayms.setTradingCommissionsBasisPoints(
            TradingCommissionsBasisPoints({
                tradingCommissionTotalBP: 0,
                tradingCommissionNaymsLtdBP: 5001,
                tradingCommissionNDFBP: 2500,
                tradingCommissionSTMBP: 2499,
                tradingCommissionMakerBP: 1
            })
        );
        vm.expectRevert("invalid trading commission total");
        nayms.setTradingCommissionsBasisPoints(
            TradingCommissionsBasisPoints({
                tradingCommissionTotalBP: 10001,
                tradingCommissionNaymsLtdBP: 5001,
                tradingCommissionNDFBP: 2500,
                tradingCommissionSTMBP: 2499,
                tradingCommissionMakerBP: 1
            })
        );
        
        // must add up to 10000
        vm.expectRevert("trading commission BPs must sum up to 10000");
        nayms.setTradingCommissionsBasisPoints(
            TradingCommissionsBasisPoints({
                tradingCommissionTotalBP: 41,
                tradingCommissionNaymsLtdBP: 5001,
                tradingCommissionNDFBP: 2500,
                tradingCommissionSTMBP: 2499,
                tradingCommissionMakerBP: 1
            })
        );

        TradingCommissionsBasisPoints memory s = TradingCommissionsBasisPoints({
            tradingCommissionTotalBP: 41,
            tradingCommissionNaymsLtdBP: 5001,
            tradingCommissionNDFBP: 2499,
            tradingCommissionSTMBP: 2499,
            tradingCommissionMakerBP: 1
        });

        // must be sys admin
        vm.prank(account9);
        vm.expectRevert("not a system admin");
        nayms.setTradingCommissionsBasisPoints(s);
        vm.stopPrank();

        // assert happy path
        nayms.setTradingCommissionsBasisPoints(s);

        TradingCommissionsBasisPoints memory result = nayms.getTradingCommissionsBasisPoints();

        assertEq(s.tradingCommissionTotalBP, result.tradingCommissionTotalBP, "tradingCommissionTotalBP not matched");
        assertEq(s.tradingCommissionNaymsLtdBP, result.tradingCommissionNaymsLtdBP, "tradingCommissionNaymsLtdBP not matched");
        assertEq(s.tradingCommissionNDFBP, result.tradingCommissionNDFBP, "tradingCommissionNDFBP not matched");
        assertEq(s.tradingCommissionSTMBP, result.tradingCommissionSTMBP, "tradingCommissionSTMBP not matched");
        assertEq(s.tradingCommissionMakerBP, result.tradingCommissionMakerBP, "tradingCommissionMakerBP not matched");
    }

    function testSetPremiumCommissionsBasisPoints() public {
        // prettier-ignore
        PolicyCommissionsBasisPoints memory s = PolicyCommissionsBasisPoints({ 
            premiumCommissionNaymsLtdBP: 42, 
            premiumCommissionNDFBP: 42, 
            premiumCommissionSTMBP: 42 
        });

        // must be sys admin
        vm.prank(account9);
        vm.expectRevert("not a system admin");
        nayms.setPolicyCommissionsBasisPoints(s);
        vm.stopPrank();

        nayms.setPolicyCommissionsBasisPoints(s);

        PolicyCommissionsBasisPoints memory result = getPremiumCommissions();

        assertEq(s.premiumCommissionNaymsLtdBP, result.premiumCommissionNaymsLtdBP, "premiumCommissionNaymsLtdBP not matched");
        assertEq(s.premiumCommissionNDFBP, result.premiumCommissionNDFBP, "premiumCommissionNDFBP not matched");
        assertEq(s.premiumCommissionSTMBP, result.premiumCommissionSTMBP, "premiumCommissionSTMBP not matched");
    }

    function getPremiumCommissions() internal returns (PolicyCommissionsBasisPoints memory) {
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(libFeeRouterFixture.getPremiumCommissionBasisPointsFixture.selector));
        require(success, "Should get commissions from app storage");
        return abi.decode(result, (PolicyCommissionsBasisPoints));
    }

    function testOnlySystemAdminCanCallLockAndUnlockFunction(address userAddress) public {
        bytes32 userId = LibHelpers._getIdForAddress(userAddress);
        vm.startPrank(userAddress);
        if (nayms.isInGroup(userId, systemContext, LibConstants.GROUP_SYSTEM_ADMINS)) {
            nayms.lockFunction(bytes4(0x12345678));

            assertTrue(nayms.isFunctionLocked(bytes4(0x12345678)));

            nayms.unlockFunction(bytes4(0x12345678));
            assertFalse(nayms.isFunctionLocked(bytes4(0x12345678)));
        } else {
            vm.expectRevert("not a system admin");
            nayms.lockFunction(bytes4(0x12345678));

            vm.expectRevert("not a system admin");
            nayms.unlockFunction(bytes4(0x12345678));
        }
    }

    function testLockFunction() public {
        // must be sys admin
        vm.prank(account9);
        vm.expectRevert("not a system admin");
        nayms.lockFunction(bytes4(0x12345678));
        vm.stopPrank();

        // assert happy path
        nayms.lockFunction(bytes4(0x12345678));

        assertTrue(nayms.isFunctionLocked(bytes4(0x12345678)));
    }

    function testLockFunctionExternalWithdrawFromEntity() public {
        bytes32 wethId = LibHelpers._getIdForAddress(wethAddress);

        // deposit
        writeTokenBalance(account0, naymsAddress, wethAddress, 1 ether);
        nayms.externalDeposit(wethAddress, 1 ether);

        assertEq(nayms.internalBalanceOf(DEFAULT_ACCOUNT0_ENTITY_ID, wethId), 1 ether, "entity1 lost internal WETH");
        assertEq(nayms.internalTokenSupply(wethId), 1 ether);

        nayms.lockFunction(ITokenizedVaultIOFacet.externalWithdrawFromEntity.selector);

        vm.expectRevert("function is locked");
        nayms.externalWithdrawFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, account0, address(weth), 0.5 ether);

        assertEq(nayms.internalBalanceOf(DEFAULT_ACCOUNT0_ENTITY_ID, wethId), 1 ether, "balance should stay the same");

        nayms.unlockFunction(ITokenizedVaultIOFacet.externalWithdrawFromEntity.selector);

        nayms.externalWithdrawFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, account0, address(weth), 0.5 ether);

        assertEq(nayms.internalBalanceOf(DEFAULT_ACCOUNT0_ENTITY_ID, wethId), 0.5 ether, "half of balance should be withdrawn");
    }

    bytes4[] s_functionSelectors;

    function test_lockAllFundTransferFunctions() public {
        vm.recordLogs();

        nayms.lockAllFundTransferFunctions();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("FunctionsLocked(bytes4[])"));
        (s_functionSelectors) = abi.decode(entries[0].data, (bytes4[]));

        bytes4[] memory lockedFunctions = new bytes4[](14);
        lockedFunctions[0] = IEntityFacet.startTokenSale.selector;
        lockedFunctions[1] = ISimplePolicyFacet.paySimpleClaim.selector;
        lockedFunctions[2] = ISimplePolicyFacet.paySimplePremium.selector;
        lockedFunctions[3] = ISimplePolicyFacet.checkAndUpdateSimplePolicyState.selector;
        lockedFunctions[4] = IMarketFacet.cancelOffer.selector;
        lockedFunctions[5] = IMarketFacet.executeLimitOffer.selector;
        lockedFunctions[6] = ITokenizedVaultFacet.internalTransferFromEntity.selector;
        lockedFunctions[7] = ITokenizedVaultFacet.payDividendFromEntity.selector;
        lockedFunctions[8] = ITokenizedVaultFacet.internalBurn.selector;
        lockedFunctions[9] = ITokenizedVaultFacet.wrapperInternalTransferFrom.selector;
        lockedFunctions[10] = ITokenizedVaultFacet.withdrawDividend.selector;
        lockedFunctions[11] = ITokenizedVaultFacet.withdrawAllDividends.selector;
        lockedFunctions[12] = ITokenizedVaultFacet.payDividendFromEntity.selector;
        lockedFunctions[13] = ITokenizedVaultIOFacet.externalDeposit.selector;

        for (uint256 i = 0; i < lockedFunctions.length; i++) {
            assertTrue(nayms.isFunctionLocked(lockedFunctions[i]));
            assertEq(s_functionSelectors[i], lockedFunctions[i]);
        }
        vm.expectRevert("function is locked");
        nayms.startTokenSale(DEFAULT_ACCOUNT0_ENTITY_ID, 100, 100);

        vm.expectRevert("function is locked");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), 0x1100000000000000000000000000000000000000000000000000000000000000, DEFAULT_INSURED_PARTY_ENTITY_ID, 2);

        vm.expectRevert("function is locked");
        nayms.paySimplePremium(0x1100000000000000000000000000000000000000000000000000000000000000, 1000);

        vm.expectRevert("function is locked");
        nayms.checkAndUpdateSimplePolicyState(0x1100000000000000000000000000000000000000000000000000000000000000);

        vm.expectRevert("function is locked");
        nayms.cancelOffer(1);

        vm.expectRevert("function is locked");
        nayms.executeLimitOffer(wethId, 1 ether, account0Id, 100);

        vm.expectRevert("function is locked");
        nayms.internalTransferFromEntity(account0Id, wethId, 1 ether);

        vm.expectRevert("function is locked");
        nayms.payDividendFromEntity(account0Id, 1 ether);

        vm.expectRevert("function is locked");
        nayms.internalBurn(account0Id, wethId, 1 ether);

        vm.expectRevert("function is locked");
        nayms.wrapperInternalTransferFrom(account0Id, account0Id, wethId, 1 ether);

        vm.expectRevert("function is locked");
        nayms.withdrawDividend(account0Id, wethId, wethId);

        vm.expectRevert("function is locked");
        nayms.withdrawAllDividends(account0Id, wethId);

        vm.expectRevert("function is locked");
        nayms.payDividendFromEntity(bytes32("0x11"), 1 ether);

        vm.expectRevert("function is locked");
        nayms.externalDeposit(wethAddress, 1 ether);
    }
}
