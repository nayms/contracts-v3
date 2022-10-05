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

        // The rough commission deducted. The actual total might be different due to integer division
        uint256 roughCommissionPaid = (s.tradingCommissionTotalBP * _requestedBuyAmount) / 1000;

        // Pay Nayms, LTD commission
        uint256 commissionNaymsLtd = (s.tradingCommissionNaymsLtdBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), _tokenId, commissionNaymsLtd);

        // Pay Nayms Discretionsry Fund commission
        uint256 commissionNDF = (s.tradingCommissionNDFBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), _tokenId, commissionNDF);

        // Pay Staking Mechanism commission
        uint256 commissionSTM = (s.tradingCommissionSTMBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), _tokenId, commissionSTM);

        // Pay market maker commission
        uint256 commissionMaker = (s.tradingCommissionMakerBP * roughCommissionPaid) / 1000;
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, commissionMaker);

        // Work it out again so the math is precise, ignoring remainers
        commissionPaid_ = commissionNaymsLtd + commissionNDF + commissionSTM + commissionMaker;
    }
}
