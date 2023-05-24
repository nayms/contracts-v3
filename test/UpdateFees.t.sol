// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import { CommissionReceiverInfo, MarketplaceFeeStrategy, PolicyCommissionsBasisPoints, TradingCommissionsBasisPoints, Entity } from "src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms, IDiamondCut, IDiamondCut, IAdminFacet } from "src/diamonds/nayms/INayms.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";

import { AdminFacet } from "src/diamonds/nayms/facets/AdminFacet.sol";

import { TokenizedVaultFacet, ITokenizedVaultFacet } from "src/diamonds/nayms/facets/TokenizedVaultFacet.sol";

contract UpdateFeesTestHelpers is Test {}

contract UpdateFeesTest is UpdateFeesTestHelpers {
    address public constant naymsAddress = 0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5;
    INayms public nayms;

    address public ownerAddress = 0xd5c10a9a09B072506C7f062E4f313Af29AdD9904;
    address public systemAdminAddress = 0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929;

    bytes32 public ownerId = LibHelpers._getIdForAddress(ownerAddress);
    bytes32 public systemAdminId = LibHelpers._getIdForAddress(systemAdminAddress);

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
        vm.startPrank(systemAdminAddress);
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

    function test_addGlobalPolicyCommissionsStrategy() public {
        AdminFacet adminFacet = new AdminFacet();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory f0 = new bytes4[](7);
        f0[0] = IAdminFacet.addGlobalPolicyCommissionsStrategy.selector;
        f0[1] = IAdminFacet.changeGlobalPolicyCommissionsStrategy.selector;
        f0[2] = IAdminFacet.addGlobalMarketplaceFeeStrategy.selector;
        f0[3] = IAdminFacet.changeGlobalMarketplaceCommissionsStrategy.selector;
        f0[4] = IAdminFacet.changeIndividualPolicyCommissionsStrategy.selector;
        f0[5] = IAdminFacet.addCommissionsReceiverToIndividualPolicy.selector;
        f0[6] = IAdminFacet.removeCommissionsReceiverFromIndividualPolicy.selector;

        // bytes4[] memory f1 = new bytes4[](18);

        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(adminFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });
        // cut[0] = IDiamondCut.FacetCut({ facetAddress: address(adminFacet), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: f0 });
        bytes32 upgradeHashOld = keccak256(abi.encode(cut));

        vm.startPrank(systemAdminAddress);
        nayms.createUpgrade(upgradeHashOld);

        changePrank(ownerAddress);
        nayms.diamondCut(cut, address(0), new bytes(0));

        CommissionReceiverInfo[] memory commissionReceiversInfo = new CommissionReceiverInfo[](1);
        commissionReceiversInfo[0] = CommissionReceiverInfo({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 300 });

        changePrank(systemAdminAddress);
        nayms.addGlobalPolicyCommissionsStrategy(0, commissionReceiversInfo);

        commissionReceiversInfo = new CommissionReceiverInfo[](1);
        commissionReceiversInfo[0] = CommissionReceiverInfo({ receiver: NAYMS_LTD_IDENTIFIER, basisPoints: 10000 });

        MarketplaceFeeStrategy memory marketplaceFeeStrategy = MarketplaceFeeStrategy({
            tradingCommissionTotalBP: 30,
            tradingCommissionMakerBP: 0,
            commissionReceiversInfo: commissionReceiversInfo
        });

        nayms.addGlobalMarketplaceFeeStrategy(0, marketplaceFeeStrategy);
    }

    // note to implement - want to make an object id an entity admin of an entity id, then be able to transfer funds
    function testTransferFromSpecialEntities() public {
        vm.startPrank(systemAdminAddress);

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        address newTokenizedVaultFacetAddress = address(new TokenizedVaultFacet());

        bytes4[] memory f0 = new bytes4[](1);
        f0[0] = TokenizedVaultFacet.internalTransferByEntityAdmin.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: newTokenizedVaultFacetAddress, action: IDiamondCut.FacetCutAction.Add, functionSelectors: f0 });

        bytes32 upgradeHash = keccak256(abi.encode(cut));
        nayms.createUpgrade(upgradeHash);

        changePrank(ownerAddress);
        nayms.diamondCut(cut, address(0), "");

        changePrank(systemAdminAddress);
        nayms.assignRole(systemAdminId, NDF_IDENTIFIER, LibConstants.ROLE_ENTITY_ADMIN);

        // nayms.internalTransferFromEntity(NAYMS_LTD_IDENTIFIER, USDC_IDENTIFIER, nayms.internalBalanceOf(NDF_IDENTIFIER, USDC_IDENTIFIER));
        nayms.internalTransferByEntityAdmin(NDF_IDENTIFIER, NAYMS_LTD_IDENTIFIER, USDC_IDENTIFIER, nayms.internalBalanceOf(NDF_IDENTIFIER, USDC_IDENTIFIER));

        vm.expectRevert("not the entity's admin");
        nayms.internalTransferByEntityAdmin(STM_IDENTIFIER, NAYMS_LTD_IDENTIFIER, USDC_IDENTIFIER, nayms.internalBalanceOf(NDF_IDENTIFIER, USDC_IDENTIFIER));
    }
}
