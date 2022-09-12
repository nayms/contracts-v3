// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, SimplePolicy, TokenAmount } from "../AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";

library LibFeeRouter {
    event DistributeFees(address operator, uint256 totalFeesDistributed);
    event RecordDividend(bytes32 entityId, bytes32 dividendDenomination, uint256 amount);

    function _payPremiumComissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;
        for (uint256 i = 0; i < commissionsCount; i++) {
            uint256 commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / 1000;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
        }

        uint256 comissionNaymsLtd = (_premiumPaid * s.premiumComissionNaymsLtdBP) / 1000;
        uint256 comissionNDF = (_premiumPaid * s.premiumComissionNDFBP) / 1000;
        uint256 comissionSTM = (_premiumPaid * s.premiumComissionSTMBP) / 1000;
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), simplePolicy.asset, comissionNaymsLtd);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), simplePolicy.asset, comissionNDF);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), simplePolicy.asset, comissionSTM);
    }

    function _payTradingComissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 commissionPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.tradingComissionNaymsLtdBP + s.tradingComissionNDFBP + s.tradingComissionSTMBP + s.tradingComissionMakerBP <= 1000, "commissions sum over 1000 bp");
        require(s.tradingComissionTotalBP <= 1000, "commission total must be<1000bp");

        // The rough commission deducted. The actual total might be different due to integer division
        uint256 roughCommissionPaid = (s.tradingComissionTotalBP * _requestedBuyAmount) / 1000;

        // Pay Nayms, LTD commission
        uint256 comissionNaymsLtd = (s.tradingComissionNaymsLtdBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), _tokenId, comissionNaymsLtd);

        // Pay Nayms Discretionsry Fund commission
        uint256 comissionNDF = (s.tradingComissionNDFBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), _tokenId, comissionNDF);

        // Pay Staking Mechanism commission
        uint256 comissionSTM = (s.tradingComissionSTMBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), _tokenId, comissionSTM);

        // Pay market maker commission
        uint256 comissionMaker = (s.tradingComissionMakerBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, comissionMaker);

        // Work it out again so the math is precise, ignoring remainers
        commissionPaid_ = comissionNaymsLtd + comissionNDF + comissionSTM + comissionMaker;
    }
}
