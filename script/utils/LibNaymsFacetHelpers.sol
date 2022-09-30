// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "src/diamonds/nayms/INayms.sol";

// Index into naymsFacetAddresses array
enum NaymsFacetAddressIndex {
    ACL,
    ADMIN,
    USER,
    SYSTEM,
    TOKENIZED_VAULT,
    TOKENIZED_VAULT_IO,
    MARKET,
    ENTITY,
    SIMPLE_POLICY
}

library LibNaymsFacetHelpers {
    function createNaymsDiamondFunctionsCut(address[] memory naymsFacetAddresses) internal pure returns (IDiamondCut.FacetCut[] memory cut) {
        // initialize the diamond as well as cut in all facets
        cut = new IDiamondCut.FacetCut[](9);

        // yul too slow, so fix stack too deep here
        {
            bytes4[] memory functionSelectorsSystemFacet = new bytes4[](3);
            functionSelectorsSystemFacet[0] = ISystemFacet.createEntity.selector;
            functionSelectorsSystemFacet[1] = ISystemFacet.stringToBytes32.selector;

            bytes4[] memory functionSelectorsTokenizedVaultFacet = new bytes4[](8);
            functionSelectorsTokenizedVaultFacet[0] = ITokenizedVaultFacet.internalBalanceOf.selector;
            functionSelectorsTokenizedVaultFacet[1] = ITokenizedVaultFacet.internalTokenSupply.selector;
            functionSelectorsTokenizedVaultFacet[2] = ITokenizedVaultFacet.getWithdrawableDividend.selector;
            functionSelectorsTokenizedVaultFacet[3] = ITokenizedVaultFacet.withdrawDividend.selector;
            functionSelectorsTokenizedVaultFacet[4] = ITokenizedVaultFacet.internalTransfer.selector;
            functionSelectorsTokenizedVaultFacet[5] = ITokenizedVaultFacet.internalTransferFromEntity.selector;
            functionSelectorsTokenizedVaultFacet[6] = ITokenizedVaultFacet.payDividend.selector;
            functionSelectorsTokenizedVaultFacet[7] = ITokenizedVaultFacet.payDividendFromEntity.selector;

            bytes4[] memory functionSelectorsTokenizedVaultIOFacet = new bytes4[](3);
            functionSelectorsTokenizedVaultIOFacet[0] = ITokenizedVaultIOFacet.externalDeposit.selector;
            functionSelectorsTokenizedVaultIOFacet[1] = ITokenizedVaultIOFacet.externalDepositToEntity.selector;
            functionSelectorsTokenizedVaultIOFacet[2] = ITokenizedVaultIOFacet.externalWithdrawFromEntity.selector;

            bytes4[] memory functionSelectorsMarketFacet = new bytes4[](6);
            functionSelectorsMarketFacet[0] = IMarketFacet.executeLimitOffer.selector;
            functionSelectorsMarketFacet[1] = IMarketFacet.cancelOffer.selector;
            functionSelectorsMarketFacet[2] = IMarketFacet.getOffer.selector;
            functionSelectorsMarketFacet[3] = IMarketFacet.getLastOfferId.selector;
            functionSelectorsMarketFacet[4] = IMarketFacet.getBestOfferId.selector;
            functionSelectorsMarketFacet[5] = IMarketFacet.calculateFee.selector;

            bytes4[] memory functionSelectorsACLFacet = new bytes4[](6);
            functionSelectorsACLFacet[0] = IACLFacet.assignRole.selector;
            functionSelectorsACLFacet[1] = IACLFacet.unassignRole.selector;
            functionSelectorsACLFacet[2] = IACLFacet.canAssign.selector;
            functionSelectorsACLFacet[3] = IACLFacet.isInGroup.selector;
            functionSelectorsACLFacet[4] = IACLFacet.isParentInGroup.selector;
            functionSelectorsACLFacet[5] = IACLFacet.getRoleInContext.selector;

            bytes4[] memory functionSelectorsEntityFacet = new bytes4[](6);
            functionSelectorsEntityFacet[0] = IEntityFacet.createSimplePolicy.selector;
            functionSelectorsEntityFacet[1] = IEntityFacet.enableEntityTokenization.selector;
            functionSelectorsEntityFacet[2] = IEntityFacet.startTokenSale.selector;
            functionSelectorsEntityFacet[3] = IEntityFacet.updateEntity.selector;
            functionSelectorsEntityFacet[4] = IEntityFacet.getEntityInfo.selector;
            functionSelectorsEntityFacet[5] = IEntityFacet.updateAllowSimplePolicy.selector;

            bytes4[] memory functionSelectorsSimplePolicyFacet = new bytes4[](4);
            functionSelectorsSimplePolicyFacet[0] = ISimplePolicyFacet.paySimplePremium.selector;
            functionSelectorsSimplePolicyFacet[1] = ISimplePolicyFacet.paySimpleClaim.selector;
            functionSelectorsSimplePolicyFacet[2] = ISimplePolicyFacet.getSimplePolicyInfo.selector;
            functionSelectorsSimplePolicyFacet[3] = ISimplePolicyFacet.checkAndUpdateSimplePolicyState.selector;

            bytes4[] memory functionSelectorsUserFacet = new bytes4[](5);
            functionSelectorsUserFacet[0] = IUserFacet.getUserIdFromAddress.selector;
            functionSelectorsUserFacet[1] = IUserFacet.getAddressFromExternalTokenId.selector;
            functionSelectorsUserFacet[2] = IUserFacet.setEntity.selector;
            functionSelectorsUserFacet[3] = IUserFacet.getEntity.selector;
            functionSelectorsUserFacet[4] = IUserFacet.getBalanceOfTokensForSale.selector;

            cut[0] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.SYSTEM)]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsSystemFacet
            });
            cut[1] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.TOKENIZED_VAULT)]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsTokenizedVaultFacet
            });
            cut[2] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.TOKENIZED_VAULT_IO)]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsTokenizedVaultIOFacet
            });
            cut[3] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.MARKET)]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsMarketFacet
            });
            cut[4] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.ACL)]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsACLFacet
            });
            cut[5] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.ENTITY)]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsEntityFacet
            });
            cut[6] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.SIMPLE_POLICY)]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsSimplePolicyFacet
            });
            cut[7] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.USER)]),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsUserFacet
            });
        }

        bytes4[] memory functionSelectorsAdminFacet = new bytes4[](21);
        functionSelectorsAdminFacet[0] = IAdminFacet.isSupportedExternalToken.selector;
        functionSelectorsAdminFacet[1] = IAdminFacet.addSupportedExternalToken.selector;
        functionSelectorsAdminFacet[2] = IAdminFacet.getSupportedExternalTokens.selector;
        functionSelectorsAdminFacet[3] = IAdminFacet.updateRoleAssigner.selector;
        functionSelectorsAdminFacet[4] = IAdminFacet.updateRoleGroup.selector;
        functionSelectorsAdminFacet[5] = IAdminFacet.setEquilibriumLevel.selector;
        functionSelectorsAdminFacet[6] = IAdminFacet.setMaxDiscount.selector;
        functionSelectorsAdminFacet[7] = IAdminFacet.setTargetNaymsAllocation.selector;
        functionSelectorsAdminFacet[8] = IAdminFacet.setDiscountToken.selector;
        functionSelectorsAdminFacet[9] = IAdminFacet.setPoolFee.selector;
        functionSelectorsAdminFacet[10] = IAdminFacet.setCoefficient.selector;
        functionSelectorsAdminFacet[11] = IAdminFacet.getDiscountToken.selector;
        functionSelectorsAdminFacet[12] = IAdminFacet.getEquilibriumLevel.selector;
        functionSelectorsAdminFacet[13] = IAdminFacet.getActualNaymsAllocation.selector;
        functionSelectorsAdminFacet[14] = IAdminFacet.getTargetNaymsAllocation.selector;
        functionSelectorsAdminFacet[15] = IAdminFacet.getMaxDiscount.selector;
        functionSelectorsAdminFacet[16] = IAdminFacet.getPoolFee.selector;
        functionSelectorsAdminFacet[17] = IAdminFacet.getRewardsCoefficient.selector;
        functionSelectorsAdminFacet[18] = IAdminFacet.getSystemId.selector;
        functionSelectorsAdminFacet[19] = IAdminFacet.setMaxDividendDenominations.selector;
        functionSelectorsAdminFacet[20] = IAdminFacet.getMaxDividendDenominations.selector;

        cut[8] = IDiamondCut.FacetCut({
            facetAddress: address(naymsFacetAddresses[uint256(NaymsFacetAddressIndex.ADMIN)]),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectorsAdminFacet
        });
    }
}
