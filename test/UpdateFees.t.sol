// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import { PolicyCommissionsBasisPoints, TradingCommissionsBasisPoints, Entity } from "src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms } from "src/diamonds/nayms/INayms.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";

contract UpdateFeesTestHelpers is Test {}

contract UpdateFeesTest is UpdateFeesTestHelpers {
    address public constant naymsAddress = 0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5;
    INayms public nayms;

    address public systemAdminAddress = 0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929;

    bytes32 public immutable NAYMS_LTD_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER);
    bytes32 public immutable NDF_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER);
    bytes32 public immutable STM_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER);
    bytes32 public immutable SSF_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.SSF_IDENTIFIER);

    bytes32 public immutable DIVIDEND_BANK_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 public immutable USDC_IDENTIFIER = LibHelpers._getIdForAddress(USDC_ADDRESS);

    function setUp() public {
        vm.label(systemAdminAddress, "system admin");

        vm.createSelectFork("mainnet", 17276760);
        vm.chainId(1);
        nayms = INayms(naymsAddress);
    }

    function testUpdateFees() public {
        PolicyCommissionsBasisPoints memory newPolicyCommissionsBasisPoints = PolicyCommissionsBasisPoints({
            premiumCommissionNaymsLtdBP: 300,
            premiumCommissionNDFBP: 0,
            premiumCommissionSTMBP: 0
        });

        vm.startPrank(systemAdminAddress);

        // Updating global policy commissions fees.
        // note: this does not update fees for exising policies, only new ones created after this update.
        nayms.setPolicyCommissionsBasisPoints(newPolicyCommissionsBasisPoints);

        PolicyCommissionsBasisPoints memory results = nayms.getPremiumCommissionBasisPoints();

        assertEq(newPolicyCommissionsBasisPoints.premiumCommissionNaymsLtdBP, results.premiumCommissionNaymsLtdBP, "premiumCommissionNaymsLtdBP not matched");
        assertEq(newPolicyCommissionsBasisPoints.premiumCommissionNDFBP, results.premiumCommissionNDFBP, "premiumCommissionNDFBP not matched");
        assertEq(newPolicyCommissionsBasisPoints.premiumCommissionSTMBP, results.premiumCommissionSTMBP, "premiumCommissionSTMBP not matched");

        TradingCommissionsBasisPoints memory newTradingCommissionsBasisPoints = TradingCommissionsBasisPoints({
            tradingCommissionTotalBP: 30,
            tradingCommissionNaymsLtdBP: 10_000,
            tradingCommissionNDFBP: 0,
            tradingCommissionSTMBP: 0,
            tradingCommissionMakerBP: 0
        });

        nayms.setTradingCommissionsBasisPoints(newTradingCommissionsBasisPoints);

        TradingCommissionsBasisPoints memory result = nayms.getTradingCommissionsBasisPoints();

        assertEq(newTradingCommissionsBasisPoints.tradingCommissionTotalBP, result.tradingCommissionTotalBP, "tradingCommissionTotalBP not matched");
        assertEq(newTradingCommissionsBasisPoints.tradingCommissionNaymsLtdBP, result.tradingCommissionNaymsLtdBP, "tradingCommissionNaymsLtdBP not matched");
        assertEq(newTradingCommissionsBasisPoints.tradingCommissionNDFBP, result.tradingCommissionNDFBP, "tradingCommissionNDFBP not matched");
        assertEq(newTradingCommissionsBasisPoints.tradingCommissionSTMBP, result.tradingCommissionSTMBP, "tradingCommissionSTMBP not matched");
        assertEq(newTradingCommissionsBasisPoints.tradingCommissionMakerBP, result.tradingCommissionMakerBP, "tradingCommissionMakerBP not matched");

        // note: if we want to update the premium commission payments for a specific policy, we need to either create an admin function that will remove
        // policy commission receivers, or have the client deprecate their exisiting policy and create a new one after Nayms updates the global policy fees.
    }

    function testCreateSpecialEntitiesAndTransferFunds() public {
        Entity memory entityData = Entity({ assetId: bytes32(0), collateralRatio: 0, maxCapacity: 0, utilizedCapacity: 0, simplePolicyEnabled: false });

        address naymsLtdAdminAddress = makeAddr("NAYMS LTD Admin");
        bytes32 naymsLtdAdminId = LibHelpers._getIdForAddress(naymsLtdAdminAddress);
        nayms.createEntity(NAYMS_LTD_IDENTIFIER, naymsLtdAdminId, entityData, bytes32(0));

        address ndfAdminAddress = makeAddr("NDF Admin");
        bytes32 ndfAdminId = LibHelpers._getIdForAddress(ndfAdminAddress);
        nayms.createEntity(NDF_IDENTIFIER, ndfAdminId, entityData, bytes32(0));

        address stmAdminAddress = makeAddr("STM Admin");
        bytes32 stmAdminId = LibHelpers._getIdForAddress(stmAdminAddress);
        nayms.createEntity(STM_IDENTIFIER, stmAdminId, entityData, bytes32(0));

        address ssfAdminAddress = makeAddr("SSF Admin");
        bytes32 ssfAdminId = LibHelpers._getIdForAddress(ssfAdminAddress);
        nayms.createEntity(SSF_IDENTIFIER, ssfAdminId, entityData, bytes32(0));

        // Transfer to NAYMS LTD
        changePrank(ndfAdminAddress);
        nayms.internalTransferFromEntity(NAYMS_LTD_IDENTIFIER, USDC_IDENTIFIER, nayms.internalBalanceOf(ndfAdminId, USDC_IDENTIFIER));

        changePrank(stmAdminAddress);
        nayms.internalTransferFromEntity(NAYMS_LTD_IDENTIFIER, USDC_IDENTIFIER, nayms.internalBalanceOf(stmAdminId, USDC_IDENTIFIER));

        changePrank(ssfAdminAddress);
        nayms.internalTransferFromEntity(NAYMS_LTD_IDENTIFIER, USDC_IDENTIFIER, nayms.internalBalanceOf(ssfAdminId, USDC_IDENTIFIER));
    }
}
