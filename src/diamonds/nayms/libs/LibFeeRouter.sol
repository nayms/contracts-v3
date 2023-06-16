// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, SimplePolicy, CalculatedCommissions, CommissionAllocation, CommissionReceiverInfo, MarketplaceFees } from "../AppStorage.sol";
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

    function _calculatePremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) internal returns (CalculatedCommissions memory calculatedCommissions_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;

        uint256 commission;
        uint256 premiumCommissionsIndex;
        for (uint256 i; i < commissionsCount; ++i) {
            commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
            calculatedCommissions_.totalBP += simplePolicy.commissionBasisPoints[i];
            calculatedCommissions_.totalCommissions += commission;

            calculatedCommissions_.commissionAllocations[i] = CommissionAllocation({
                receiverId: policyEntityId,
                basisPoints: simplePolicy.commissionBasisPoints[i],
                commission: commission
            });

            premiumCommissionsIndex++;
        }

        CommissionReceiverInfo[] memory policyFeeStrategy = s.policyFeeStrategies[simplePolicy.feeStrategy];
        uint256 policyFeeStrategyCount = policyFeeStrategy.length;

        for (uint256 i; i < policyFeeStrategyCount; ++i) {
            commission = (_premiumPaid * policyFeeStrategy[i].basisPoints) / LibConstants.BP_FACTOR;
            calculatedCommissions_.totalBP += policyFeeStrategy[i].basisPoints;
            calculatedCommissions_.totalCommissions += commission;

            calculatedCommissions_.commissionAllocations[premiumCommissionsIndex + i] = CommissionAllocation({
                receiverId: policyFeeStrategy[i].receiver,
                basisPoints: policyFeeStrategy[i].basisPoints,
                commission: commission
            });
        }
    }

    function _payPremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 totalCommissionsPaid;
        uint256 commissionsCount = simplePolicy.commissionReceivers.length;

        uint256 commission;
        for (uint256 i; i < commissionsCount; ++i) {
            commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
            totalCommissionsPaid += commission;
        }

        CommissionReceiverInfo[] memory policyFeeStrategy = s.policyFeeStrategies[simplePolicy.feeStrategy];
        uint256 policyFeeStrategyCount = policyFeeStrategy.length;

        for (uint256 i; i < policyFeeStrategyCount; ++i) {
            commission = (_premiumPaid * policyFeeStrategy[i].basisPoints) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, policyFeeStrategy[i].receiver, simplePolicy.asset, commission);
            totalCommissionsPaid += commission;
        }

        emit PremiumCommissionsPaid(_policyId, policyEntityId, totalCommissionsPaid);
    }

    function _payTradingCommissions(
        uint256 _feeSchedule,
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _buyAmount
    ) internal returns (uint256 totalCommissionsPaid) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        MarketplaceFees memory marketplaceFees;
        if (_feeSchedule == LibConstants.FEE_SCHEDULE_INITIAL_OFFER) {
            marketplaceFees = s.marketplaceFeeStrategies[LibConstants.FEE_SCHEDULE_INITIAL_OFFER];
        } else {
            marketplaceFees = s.marketplaceFeeStrategies[s.currentGlobalMarketplaceFeeStrategy];
        }

        uint256 commission;
        uint256 totalBP;
        // Calculate fees for the market maker
        if (marketplaceFees.tradingCommissionMakerBP > 0) {
            commission = (_buyAmount * marketplaceFees.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
            totalCommissionsPaid += commission;
            totalBP += marketplaceFees.tradingCommissionMakerBP;
            LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, commission);
        }

        uint256 additionalCommissionReceiversCount = marketplaceFees.commissionReceiversInfo.length;
        for (uint256 i; i < additionalCommissionReceiversCount; ++i) {
            commission = (_buyAmount * marketplaceFees.commissionReceiversInfo[i].basisPoints) / LibConstants.BP_FACTOR;
            totalCommissionsPaid += commission;
            totalBP += marketplaceFees.commissionReceiversInfo[i].basisPoints;
            LibTokenizedVault._internalTransfer(_takerId, marketplaceFees.commissionReceiversInfo[i].receiver, _tokenId, commission);
        }

        require(LibConstants.BP_FACTOR > totalBP, "commissions sum over 10000 bp");

        emit TradingCommissionsPaid(_takerId, _tokenId, totalCommissionsPaid);
    }

    // replaces a receiver's commission basis points
    function _updateTradingCommissionsBasisPoints(uint256 _strategyId, MarketplaceFees calldata _marketplaceFees) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // CommissionReceiverInfo[] memory commissionReceiversInfo = s.marketplaceFeeStrategies[_strategyId];
        // uint256 commissionReceiversCount = commissionReceiversInfo.length;
        // uint256 totalBP = _basisPoints;
        // for (uint256 i; i < commissionReceiversCount; ++i) {
        //     if (_marketplaceFees.commissionReceiversInfo[i].receiver == _receiverId) {
        //         // todo replace variable in array
        //         // s.marketplaceFeeStrategies[_strategyId] = _marketplaceFees.commissionReceiversInfo[i].basisPoints = _basisPoints;
        //         totalBP += _marketplaceFees.commissionReceiversInfo[i].basisPoints;
        //     } else {
        //         totalBP += _marketplaceFees.commissionReceiversInfo[i].basisPoints;
        //     }
        // }

        // require(0 < totalBP && totalBP < LibConstants.BP_FACTOR, "invalid trading commission total");

        // emit TradingCommissionsUpdated(
        //     bp.tradingCommissionTotalBP,
        //     bp.tradingCommissionNaymsLtdBP,
        //     bp.tradingCommissionNDFBP,
        //     bp.tradingCommissionSTMBP,
        //     bp.tradingCommissionMakerBP
        // );
    }

    error CommissionsBasisPointsCannotBeGreaterThan10000(uint256 totalBp);

    function _calculateTradingCommissions(uint256 _feeStrategyId, uint256 buyAmount) internal view returns (CalculatedCommissions memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        MarketplaceFees memory marketplaceFees = s.marketplaceFeeStrategies[_feeStrategyId];

        uint256 marketplaceReceiverCount;

        // Calculate fees for the market maker
        if (marketplaceFees.tradingCommissionMakerBP > 0) {
            marketplaceReceiverCount++;
            tc.commissionAllocations[0].commission = (buyAmount * marketplaceFees.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
            tc.totalCommissions += tc.commissionAllocations[0].commission;
            tc.totalBP += marketplaceFees.tradingCommissionMakerBP;
        }

        uint256 additionalCommissionReceiversCount = marketplaceFees.commissionReceiversInfo.length;
        for (uint256 i; i < additionalCommissionReceiversCount; ++i) {
            tc.commissionAllocations[marketplaceReceiverCount + i].commission = (buyAmount * marketplaceFees.commissionReceiversInfo[i].basisPoints) / LibConstants.BP_FACTOR;
            tc.totalCommissions += tc.commissionAllocations[marketplaceReceiverCount + i].commission;
            tc.totalBP += marketplaceFees.commissionReceiversInfo[i].basisPoints;
        }
    }

    function _addGlobalPolicyCommissionsStrategy(uint256 _strategyId, CommissionReceiverInfo[] calldata _commissionReceivers) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check to see that the total commission does not exceed 100000 basis points
        uint256 receiverCount = _commissionReceivers.length;
        uint256 totalBp;
        for (uint256 i; i < receiverCount; ++i) {
            totalBp += _commissionReceivers[i].basisPoints;
        }
        if (totalBp > LibConstants.BP_FACTOR) {
            revert CommissionsBasisPointsCannotBeGreaterThan10000(totalBp);
        }

        for (uint256 i; i < receiverCount; ++i) {
            s.policyFeeStrategies[_strategyId].push(_commissionReceivers[i]);
        }
    }

    // todo increment strategy id deterministically
    function _addGlobalMarketplaceFeeStrategy(uint256 _strategyId, MarketplaceFees calldata _marketplaceFees) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        MarketplaceFees memory marketplaceFees = s.marketplaceFeeStrategies[_strategyId];
        uint256 receiverCount = marketplaceFees.commissionReceiversInfo.length;
        uint256 totalBp;
        for (uint256 i; i < receiverCount; ++i) {
            totalBp += marketplaceFees.commissionReceiversInfo[i].basisPoints;
        }

        if (totalBp + _marketplaceFees.tradingCommissionMakerBP > LibConstants.BP_FACTOR) {
            revert CommissionsBasisPointsCannotBeGreaterThan10000(totalBp);
        }

        s.marketplaceFeeStrategies[_strategyId] = _marketplaceFees;
        // s.marketplaceFeeStrategies[_strategyId].tradingCommissionMakerBP = _marketplaceFees.tradingCommissionMakerBP;
        // for (uint256 i; i < receiverCount; ++i) {
        //     s.marketplaceFeeStrategies[_strategyId].commissionReceiversInfo.push(_marketplaceFees.commissionReceiversInfo[i]);
        // }

        // emit
    }

    function _changeGlobalPolicyCommissionsStrategy(uint256 _strategyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.currentGlobalPolicyFeeStrategy = _strategyId;
    }

    function _changeGlobalMarketplaceCommissionsStrategy(uint256 _strategyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.currentGlobalMarketplaceFeeStrategy = _strategyId;
    }

    function _changeIndividualPolicyCommissionsStrategy(bytes32 _policyId, uint256 _strategyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.simplePolicies[_policyId].feeStrategy = _strategyId;
    }

    function _addCommissionsReceiverToIndividualPolicy(bytes32 _policyId, CommissionReceiverInfo calldata _commissionReceiver) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.simplePolicies[_policyId].commissionReceivers.push(_commissionReceiver.receiver);
        s.simplePolicies[_policyId].commissionBasisPoints.push(_commissionReceiver.basisPoints);
    }

    function _removeCommissionsReceiverFromIndividualPolicy(bytes32 _policyId, bytes32 _receiver) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        uint256 receiverCount = simplePolicy.commissionReceivers.length;
        for (uint256 i; i < receiverCount; ++i) {
            if (simplePolicy.commissionReceivers[i] == _receiver) {
                // Move the last element to the position of the element to be removed
                simplePolicy.commissionReceivers[i] = simplePolicy.commissionReceivers[receiverCount - 1];
                // Pop off last element
                simplePolicy.commissionReceivers.pop();
                break;
            }
        }
    }
}
