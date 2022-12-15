// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";
import { Vm } from "forge-std/Vm.sol";
import { TradingCommissionsBasisPoints, PolicyCommissionsBasisPoints } from "../src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
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

    function testSetTradingCommissionsBasisPoints() public {
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
}
