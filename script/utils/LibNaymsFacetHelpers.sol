// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "src/diamonds/nayms/INayms.sol";

struct NaymsFacetAddresses {
    address aclFacet;
    address naymsERC20Facet;
    address adminFacet;
    address userFacet;
    address systemFacet;
    address tokenizedVaultFacet;
    address tokenizedVaultIOFacet;
    address marketFacet;
    address entityFacet;
    address simplePolicyFacet;
    address ndfFacet;
    address ssfFacet;
    address stakingFacet;
}

library LibNaymsFacetHelpers {
    function createNaymsDiamondFunctionsCut(NaymsFacetAddresses memory naymsFacetAddresses) internal pure returns (IDiamondCut.FacetCut[] memory cut) {
        // initialize the diamond as well as cut in all facets
        cut = new IDiamondCut.FacetCut[](13);

        // yul too slow, so fix stack too deep here
        {
            bytes4[] memory functionSelectorsSystemFacet = new bytes4[](3);
            functionSelectorsSystemFacet[0] = ISystemFacet.createEntity.selector;
            functionSelectorsSystemFacet[1] = ISystemFacet.approveUser.selector;
            functionSelectorsSystemFacet[2] = ISystemFacet.stringToBytes32.selector;

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

            bytes4[] memory functionSelectorsACLFacet = new bytes4[](4);
            functionSelectorsACLFacet[0] = IACLFacet.assignRole.selector;
            functionSelectorsACLFacet[1] = IACLFacet.unassignRole.selector;
            functionSelectorsACLFacet[2] = IACLFacet.isInGroup.selector;
            functionSelectorsACLFacet[3] = IACLFacet.getRoleInContext.selector;

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

            bytes4[] memory functionSelectorsNDFFacet = new bytes4[](6);
            functionSelectorsNDFFacet[0] = INDFFacet.buyNayms.selector;
            functionSelectorsNDFFacet[1] = INDFFacet.paySubSurplusFund.selector;
            functionSelectorsNDFFacet[2] = INDFFacet.swapTokens.selector;
            functionSelectorsNDFFacet[3] = INDFFacet.getNaymsValueRatio.selector;
            functionSelectorsNDFFacet[4] = INDFFacet.getDiscount.selector;

            bytes4[] memory functionSelectorsSSFFacet = new bytes4[](3);
            functionSelectorsSSFFacet[0] = ISSFFacet.payRewardsToUser.selector;
            functionSelectorsSSFFacet[1] = ISSFFacet.estimateAmountOut.selector;
            functionSelectorsSSFFacet[2] = ISSFFacet.payReward.selector;

            cut[0] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.systemFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsSystemFacet
            });
            cut[1] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.tokenizedVaultFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsTokenizedVaultFacet
            });
            cut[2] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.tokenizedVaultIOFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsTokenizedVaultIOFacet
            });
            cut[3] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.marketFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsMarketFacet
            });
            cut[4] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.aclFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsACLFacet
            });
            cut[5] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.entityFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsEntityFacet
            });
            cut[6] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.simplePolicyFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsSimplePolicyFacet
            });
            cut[7] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.userFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsUserFacet
            });
            cut[8] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.ndfFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsNDFFacet
            });
            cut[9] = IDiamondCut.FacetCut({
                facetAddress: address(naymsFacetAddresses.ssfFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: functionSelectorsSSFFacet
            });
        }

        bytes4[] memory functionSelectorsNaymsERC20Facet = new bytes4[](15);
        functionSelectorsNaymsERC20Facet[0] = INaymsERC20Facet.name.selector;
        functionSelectorsNaymsERC20Facet[1] = INaymsERC20Facet.symbol.selector;
        functionSelectorsNaymsERC20Facet[2] = INaymsERC20Facet.decimals.selector;
        functionSelectorsNaymsERC20Facet[3] = INaymsERC20Facet.totalSupply.selector;
        functionSelectorsNaymsERC20Facet[4] = INaymsERC20Facet.balanceOf.selector;
        functionSelectorsNaymsERC20Facet[5] = INaymsERC20Facet.transfer.selector;
        functionSelectorsNaymsERC20Facet[6] = INaymsERC20Facet.transferFrom.selector;
        functionSelectorsNaymsERC20Facet[7] = INaymsERC20Facet.approve.selector;
        functionSelectorsNaymsERC20Facet[8] = INaymsERC20Facet.increaseAllowance.selector;
        functionSelectorsNaymsERC20Facet[9] = INaymsERC20Facet.decreaseAllowance.selector;
        functionSelectorsNaymsERC20Facet[10] = INaymsERC20Facet.allowance.selector;
        functionSelectorsNaymsERC20Facet[11] = INaymsERC20Facet.permit.selector;
        functionSelectorsNaymsERC20Facet[12] = INaymsERC20Facet.DOMAIN_SEPARATOR.selector;
        functionSelectorsNaymsERC20Facet[13] = INaymsERC20Facet.mint.selector;
        functionSelectorsNaymsERC20Facet[14] = INaymsERC20Facet.mintTo.selector;

        bytes4[] memory functionSelectorsAdminFacet = new bytes4[](19);
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

        bytes4[] memory functionSelectorsStakingFacet = new bytes4[](12);
        functionSelectorsStakingFacet[0] = IStakingFacet.checkpoint.selector;
        functionSelectorsStakingFacet[1] = IStakingFacet.withdraw.selector;
        functionSelectorsStakingFacet[2] = IStakingFacet.increaseAmount.selector;
        functionSelectorsStakingFacet[3] = IStakingFacet.increaseUnlockTime.selector;
        functionSelectorsStakingFacet[4] = IStakingFacet.createLock.selector;
        functionSelectorsStakingFacet[5] = IStakingFacet.depositFor.selector;
        functionSelectorsStakingFacet[6] = IStakingFacet.getLastUserSlope.selector;
        functionSelectorsStakingFacet[7] = IStakingFacet.getUserPointHistoryTimestamp.selector;
        functionSelectorsStakingFacet[8] = IStakingFacet.getUserLockedBalanceEndTime.selector;
        functionSelectorsStakingFacet[9] = IStakingFacet.exchangeRate.selector;
        functionSelectorsStakingFacet[10] = IStakingFacet.getVENAYMForNAYM.selector;
        functionSelectorsStakingFacet[11] = IStakingFacet.getNAYMForVENAYM.selector;

        cut[10] = IDiamondCut.FacetCut({
            facetAddress: address(naymsFacetAddresses.naymsERC20Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectorsNaymsERC20Facet
        });
        cut[11] = IDiamondCut.FacetCut({
            facetAddress: address(naymsFacetAddresses.adminFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectorsAdminFacet
        });
        cut[12] = IDiamondCut.FacetCut({
            facetAddress: address(naymsFacetAddresses.stakingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectorsStakingFacet
        });
    }

    function systemFacetCut() internal pure returns (IDiamondCut.FacetCut[] memory cut) {
        cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectorsSystemFacet = new bytes4[](3);
        functionSelectorsSystemFacet[0] = ISystemFacet.createEntity.selector;
        functionSelectorsSystemFacet[1] = ISystemFacet.approveUser.selector;
        functionSelectorsSystemFacet[2] = ISystemFacet.stringToBytes32.selector;

        // cut[0] = IDiamondCut.FacetCut({
        //     facetAddress: address(naymsFacetAddresses.systemFacet),
        //     action: IDiamondCut.FacetCutAction.Add,
        //     functionSelectors: functionSelectorsSystemFacet
        // });
    }
}

// library LibSystemFacetCut {
//     function systemFacetCut() internal pure returns (IDiamondCut.FacetCut[] memory cut) {
//         cut = new IDiamondCut.FacetCut[](1);
//         bytes4[] memory functionSelectorsSystemFacet = new bytes4[](3);
//         functionSelectorsSystemFacet[0] = ISystemFacet.createEntity.selector;
//         functionSelectorsSystemFacet[1] = ISystemFacet.approveUser.selector;
//         functionSelectorsSystemFacet[2] = ISystemFacet.stringToBytes32.selector;

//         cut[0] = IDiamondCut.FacetCut({
//             facetAddress: address(naymsFacetAddresses.systemFacet),
//             action: IDiamondCut.FacetCutAction.Add,
//             functionSelectors: functionSelectorsSystemFacet
//         });
//     }
// }
