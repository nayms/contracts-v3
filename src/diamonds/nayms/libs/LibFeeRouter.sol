// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { SimplePolicy, TokenAmount, TradingCommissions } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";

library LibFeeRouter {
    event TradingCommissionsPaid(bytes32 indexed takerId, bytes32 tokenId, uint256 amount);
    event PremiumCommissionsPaid(bytes32 indexed policyId, bytes32 indexed entityId, uint256 amount);

    function _payPremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];
        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;
        for (uint256 i = 0; i < commissionsCount; i++) {
            uint256 commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / 1000;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
        }

        uint256 commissionNaymsLtd = (_premiumPaid * s.premiumCommissionNaymsLtdBP) / 1000;
        uint256 commissionNDF = (_premiumPaid * s.premiumCommissionNDFBP) / 1000;
        uint256 commissionSTM = (_premiumPaid * s.premiumCommissionSTMBP) / 1000;

        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), simplePolicy.asset, commissionNaymsLtd);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), simplePolicy.asset, commissionNDF);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), simplePolicy.asset, commissionSTM);

        emit PremiumCommissionsPaid(_policyId, policyEntityId, _premiumPaid);
    }

    function _payTradingCommissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 commissionPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.tradingCommissionNaymsLtdBP + s.tradingCommissionNDFBP + s.tradingCommissionSTMBP + s.tradingCommissionMakerBP <= 1000, "commissions sum over 1000 bp");
        require(s.tradingCommissionTotalBP <= 1000, "commission total must be<1000bp");

        TradingCommissions memory tc = _calculateTradingCommissions(_requestedBuyAmount);
        // The rough commission deducted. The actual total might be different due to integer division

        // Pay Nayms, LTD commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), _tokenId, tc.commissionNaymsLtd);

        // Pay Nayms Discretionsry Fund commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), _tokenId, tc.commissionNDF);

        // Pay Staking Mechanism commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), _tokenId, tc.commissionSTM);

        // Pay market maker commission
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, tc.commissionMaker);

        // Work it out again so the math is precise, ignoring remainers
        commissionPaid_ = tc.totalCommissions;

        emit TradingCommissionsPaid(_takerId, _tokenId, commissionPaid_);
    }

    function _calculateTradingCommissions(uint256 buyAmount) internal view returns (TradingCommissions memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // The rough commission deducted. The actual total might be different due to integer division
        tc.roughCommissionPaid = (s.tradingCommissionTotalBP * buyAmount) / 1000;

        // Pay Nayms, LTD commission
        tc.commissionNaymsLtd = (s.tradingCommissionNaymsLtdBP * tc.roughCommissionPaid) / 1000;

        // Pay Nayms Discretionsry Fund commission
        tc.commissionNDF = (s.tradingCommissionNDFBP * tc.roughCommissionPaid) / 1000;

        // Pay Staking Mechanism commission
        tc.commissionSTM = (s.tradingCommissionSTMBP * tc.roughCommissionPaid) / 1000;

        // Pay market maker commission
        tc.commissionMaker = (s.tradingCommissionMakerBP * tc.roughCommissionPaid) / 1000;

        // Work it out again so the math is precise, ignoring remainers
        tc.totalCommissions = tc.commissionNaymsLtd + tc.commissionNDF + tc.commissionSTM + tc.commissionMaker;
    }

    function _getNaymsLtdBP() internal view returns (uint256 bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp = s.tradingCommissionNaymsLtdBP;
    }

    function _getNDFBP() internal view returns (uint256 bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp = s.tradingCommissionNDFBP;
    }

    function _getSTMBP() internal view returns (uint256 bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp = s.tradingCommissionSTMBP;
    }

    function _getMakerBP() internal view returns (uint256 bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp = s.tradingCommissionMakerBP;
    }
}
