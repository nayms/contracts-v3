// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, SimplePolicy, CommissionReceiverInfo, MarketplaceFeeStrategy, PolicyCommissionsBasisPoints, TradingCommissions, TradingCommissionsBasisPoints } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { PolicyCommissionsBasisPointsCannotBeGreaterThan10000 } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibFeeRouter {
    event TradingCommissionsPaid(bytes32 indexed takerId, bytes32 tokenId, uint256 amount);
    event TradingCommissionsUpdated(
        uint16 tradingCommissionTotalBP,
        uint16 tradingCommissionNaymsLtdBP,
        uint16 tradingCommissionNDFBP,
        uint16 tradingCommissionSTMBP,
        uint16 tradingCommissionMakerBP
    );
    event PremiumCommissionsPaid(bytes32 indexed policyId, bytes32 indexed entityId, uint256 amount);
    event PremiumCommissionsUpdated(uint16 premiumCommissionNaymsLtdBP, uint16 premiumCommissionNDFBP, uint16 premiumCommissionSTMBP);

    function _payPremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 premiumCommissionPaid;
        uint256 commissionsCount = simplePolicy.commissionReceivers.length;

        uint256 commission;
        for (uint256 i; i < commissionsCount; ++i) {
            commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
            premiumCommissionPaid += commission;
        }

        CommissionReceiverInfo[] memory policyFeeStrategy = s.policyFeeStrategy[simplePolicy.feeStrategy];
        uint256 policyFeeStrategyCount = policyFeeStrategy.length;

        for (uint256 i; i < policyFeeStrategyCount; ++i) {
            commission = (_premiumPaid * policyFeeStrategy[i].basisPoints) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, policyFeeStrategy[i].receiver, simplePolicy.asset, commission);
            premiumCommissionPaid += commission;
        }

        emit PremiumCommissionsPaid(_policyId, policyEntityId, premiumCommissionPaid);
    }

    function _payTradingCommissions(bytes32 _makerId, bytes32 _takerId, bytes32 _tokenId, uint256 _requestedBuyAmount) internal returns (uint256 commissionPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.marketplaceFeeStrategy[s.currentGlobalMarketplaceFeeStrategy].tradingCommissionTotalBP <= LibConstants.BP_FACTOR, "commission total must be<=10000bp");

        MarketplaceFeeStrategy memory globalMarketplaceFeeStrategy = s.marketplaceFeeStrategy[s.currentGlobalMarketplaceFeeStrategy];
        uint256 globalMarketplaceFeeReceiverCount = globalMarketplaceFeeStrategy.commissionReceiversInfo.length;
        uint256 totalBP;
        for (uint256 i; i < globalMarketplaceFeeReceiverCount; ++i) {
            totalBP += globalMarketplaceFeeStrategy.commissionReceiversInfo[i].basisPoints;
        }
        require(totalBP <= LibConstants.BP_FACTOR, "commissions sum over 10000 bp");

        uint256 commission;
        uint256 totalCommissionsPaid;
        for (uint256 i; i < globalMarketplaceFeeReceiverCount; ++i) {
            commission = (_requestedBuyAmount * globalMarketplaceFeeStrategy.commissionReceiversInfo[i].basisPoints) / LibConstants.BP_FACTOR;
            totalCommissionsPaid += commission;
            LibTokenizedVault._internalTransfer(_takerId, globalMarketplaceFeeStrategy.commissionReceiversInfo[i].receiver, _tokenId, commission);
        }

        // Pay market maker commission
        commission = (_requestedBuyAmount * globalMarketplaceFeeStrategy.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
        totalCommissionsPaid += commission; // Add the maker commission
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, commission);

        emit TradingCommissionsPaid(_takerId, _tokenId, totalCommissionsPaid);
    }

    function _updateTradingCommissionsBasisPoints(TradingCommissionsBasisPoints calldata bp) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(0 < bp.tradingCommissionTotalBP && bp.tradingCommissionTotalBP < LibConstants.BP_FACTOR, "invalid trading commission total");
        require(
            bp.tradingCommissionNaymsLtdBP + bp.tradingCommissionNDFBP + bp.tradingCommissionSTMBP + bp.tradingCommissionMakerBP == LibConstants.BP_FACTOR,
            "trading commission BPs must sum up to 10000"
        );

        s.tradingCommissionTotalBP = bp.tradingCommissionTotalBP;
        s.tradingCommissionNaymsLtdBP = bp.tradingCommissionNaymsLtdBP;
        s.tradingCommissionNDFBP = bp.tradingCommissionNDFBP;
        s.tradingCommissionSTMBP = bp.tradingCommissionSTMBP;
        s.tradingCommissionMakerBP = bp.tradingCommissionMakerBP;

        emit TradingCommissionsUpdated(
            bp.tradingCommissionTotalBP,
            bp.tradingCommissionNaymsLtdBP,
            bp.tradingCommissionNDFBP,
            bp.tradingCommissionSTMBP,
            bp.tradingCommissionMakerBP
        );
    }

    // todo remove
    function _updatePolicyCommissionsBasisPoints(PolicyCommissionsBasisPoints calldata bp) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalBp = bp.premiumCommissionNaymsLtdBP + bp.premiumCommissionNDFBP + bp.premiumCommissionSTMBP;
        if (totalBp > LibConstants.BP_FACTOR) {
            revert PolicyCommissionsBasisPointsCannotBeGreaterThan10000(totalBp);
        }
        s.premiumCommissionNaymsLtdBP = bp.premiumCommissionNaymsLtdBP;
        s.premiumCommissionNDFBP = bp.premiumCommissionNDFBP;
        s.premiumCommissionSTMBP = bp.premiumCommissionSTMBP;

        emit PremiumCommissionsUpdated(bp.premiumCommissionNaymsLtdBP, bp.premiumCommissionNDFBP, bp.premiumCommissionSTMBP);
    }

    function _calculateTradingCommissions(uint256 buyAmount) internal view returns (TradingCommissions memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // The rough commission deducted. The actual total might be different due to integer division
        tc.roughCommissionPaid = (s.tradingCommissionTotalBP * buyAmount) / LibConstants.BP_FACTOR;

        // Pay Nayms, LTD commission
        tc.commissionNaymsLtd = (s.tradingCommissionNaymsLtdBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay Nayms Discretionary Fund commission
        tc.commissionNDF = (s.tradingCommissionNDFBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay Staking Mechanism commission
        tc.commissionSTM = (s.tradingCommissionSTMBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay market maker commission
        tc.commissionMaker = (s.tradingCommissionMakerBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Work it out again so the math is precise, ignoring remainders
        tc.totalCommissions = tc.commissionNaymsLtd + tc.commissionNDF + tc.commissionSTM + tc.commissionMaker;
    }

    function _getTradingCommissionsBasisPoints() internal view returns (TradingCommissionsBasisPoints memory bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp.tradingCommissionTotalBP = s.tradingCommissionTotalBP;
        bp.tradingCommissionNaymsLtdBP = s.tradingCommissionNaymsLtdBP;
        bp.tradingCommissionNDFBP = s.tradingCommissionNDFBP;
        bp.tradingCommissionSTMBP = s.tradingCommissionSTMBP;
        bp.tradingCommissionMakerBP = s.tradingCommissionMakerBP;
    }

    function _getPremiumCommissionBasisPoints() internal view returns (PolicyCommissionsBasisPoints memory bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp.premiumCommissionNaymsLtdBP = s.premiumCommissionNaymsLtdBP;
        bp.premiumCommissionNDFBP = s.premiumCommissionNDFBP;
        bp.premiumCommissionSTMBP = s.premiumCommissionSTMBP;
    }

    function _addGlobalPolicyCommissionsStrategy(uint256 _strategyId, CommissionReceiverInfo[] calldata _commissionReceivers) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check to see that the total commission does not exceed 10000 basis points
        uint256 receiverCount = _commissionReceivers.length;
        uint256 totalBp;
        for (uint256 i; i < receiverCount; ++i) {
            totalBp += _commissionReceivers[i].basisPoints;
        }
        if (totalBp > LibConstants.BP_FACTOR) {
            revert PolicyCommissionsBasisPointsCannotBeGreaterThan10000(totalBp);
        }

        for (uint256 i; i < receiverCount; ++i) {
            s.policyFeeStrategy[_strategyId].push(_commissionReceivers[i]);
        }
    }

    error CommissionsBasisPointsCannotBeGreaterThan10000(uint256 _totalBP);

    // todo increment strategy id deterministically
    function _addGlobalMarketplaceFeeStrategy(uint256 _strategyId, MarketplaceFeeStrategy calldata _marketplaceFeeStrategy) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 receiverCount = _marketplaceFeeStrategy.commissionReceiversInfo.length;
        uint256 totalBp;
        for (uint256 i; i < receiverCount; ++i) {
            totalBp += _marketplaceFeeStrategy.commissionReceiversInfo[i].basisPoints;
        }

        if (totalBp + _marketplaceFeeStrategy.tradingCommissionMakerBP > LibConstants.BP_FACTOR) {
            revert CommissionsBasisPointsCannotBeGreaterThan10000(totalBp);
        }

        s.marketplaceFeeStrategy[_strategyId].tradingCommissionTotalBP = _marketplaceFeeStrategy.tradingCommissionTotalBP;
        s.marketplaceFeeStrategy[_strategyId].tradingCommissionMakerBP = _marketplaceFeeStrategy.tradingCommissionMakerBP;
        for (uint256 i; i < receiverCount; ++i) {
            s.marketplaceFeeStrategy[_strategyId].commissionReceiversInfo.push(_marketplaceFeeStrategy.commissionReceiversInfo[i]);
        }
    }

    function _changeGlobalPolicyCommissionsStrategy(uint256 _strategyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.currentGlobalPolicyFeeStrategy = _strategyId;
    }

    function _changeGlobalMarketplaceCommissionsStrategy(uint256 _strategyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.currentGlobalMarketplaceFeeStrategy = _strategyId;
    }
}
