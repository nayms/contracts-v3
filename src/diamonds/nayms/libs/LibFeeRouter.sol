// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, SimplePolicy, CalculatedCommissions, CommissionAllocation, CommissionReceiverInfo } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { PolicyCommissionsBasisPointsCannotBeGreaterThan10000 } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibFeeRouter {
    error CommissionsBasisPointsCannotBeGreaterThan5000(uint256 totalBp); // todo move

    event TradingCommissionsPaid(bytes32 indexed takerId, bytes32 tokenId, uint256 amount);
    event PremiumCommissionsPaid(bytes32 indexed policyId, bytes32 indexed entityId, uint256 amount);

    event MakerBasisPointsUpdated(uint16 tradingCommissionMakerBP);
    event PolicyFeeScheduleUpdated(uint256 policyFeeSchedule);
    event FeeScheduleAdded(CommissionReceiverInfo[] commissionReceivers);

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

        CommissionReceiverInfo[] memory policyFeeStrategy = s.feeSchedules[simplePolicy.feeSchedule];
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

        uint256 totalBP;
        uint256 totalCommissionsPaid;
        uint256 commissionsCount = simplePolicy.commissionReceivers.length;

        uint256 commission;
        for (uint256 i; i < commissionsCount; ++i) {
            totalBP += simplePolicy.commissionBasisPoints[i];
            commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
            totalCommissionsPaid += commission;
        }

        CommissionReceiverInfo[] memory feeSchedule = s.feeSchedules[simplePolicy.feeSchedule];

        uint256 additionalCommissionReceiversCount = feeSchedule.length;
        for (uint256 i; i < additionalCommissionReceiversCount; ++i) {
            totalBP += feeSchedule[i].basisPoints;
            commission = (_premiumPaid * feeSchedule[i].basisPoints) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, feeSchedule[i].receiver, simplePolicy.asset, commission);
            totalCommissionsPaid += commission;
        }

        require(LibConstants.BP_FACTOR > totalBP, "commissions sum over 10000 bp");

        emit PremiumCommissionsPaid(_policyId, policyEntityId, totalCommissionsPaid);
    }

    function _payTradingCommissions(
        uint256 _feeSchedule,
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _buyAmount,
        bool _takeExternalToken
    ) internal returns (uint256 totalCommissionsPaid) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Get the commission receivers for this _feeSchedule
        CommissionReceiverInfo[] memory feeSchedules = s.feeSchedules[_feeSchedule];

        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            uint256 commission = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, commission);

            emit TradingCommissionsPaid(_takerId, _tokenId, commission);
        }

        bytes32 buyer; // The entity that is buying par tokens and the one paying commissions if INITIAL_OFFER
        // bytes32 seller; // The entity that is selling par tokens and the one receiving commissions if INITIAL_OFFER
        if (_feeSchedule == LibConstants.FEE_SCHEDULE_INITIAL_OFFER && !_takeExternalToken) {
            buyer = _makerId;
        } else {
            buyer = _takerId;
        }

        uint256 takerBP;
        uint256 makerBP;
        uint256 commission;
        uint256 additionalCommissionReceiversCount = feeSchedules.length;
        for (uint256 i; i < additionalCommissionReceiversCount; ++i) {
            commission = (_buyAmount * feeSchedules[i].basisPoints) / LibConstants.BP_FACTOR;
            totalCommissionsPaid += commission;
            if (buyer == _takerId) {
                takerBP += feeSchedules[i].basisPoints;
            } else if (buyer == _makerId) {
                makerBP += feeSchedules[i].basisPoints;
            }

            LibTokenizedVault._internalTransfer(buyer, feeSchedules[i].receiver, _tokenId, commission);
        }

        require(LibConstants.BP_FACTOR > takerBP + s.tradingCommissionMakerBP, "taker commissions sum over 10000 bp");
        require(LibConstants.BP_FACTOR > makerBP, "maker commissions sum over 10000 bp");

        emit TradingCommissionsPaid(buyer, _tokenId, totalCommissionsPaid);
    }

    function _calculateTradingCommissions(uint256 _feeScheduleId, uint256 buyAmount) internal view returns (CalculatedCommissions memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        CommissionReceiverInfo[] memory feeSchedule = s.feeSchedules[_feeScheduleId];

        // uint256 marketplaceReceiverCount;

        // // Calculate fees for the market maker
        // if (marketplaceFees.tradingCommissionMakerBP > 0) {
        //     marketplaceReceiverCount++;
        //     tc.commissionAllocations[0].commission = (buyAmount * marketplaceFees.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
        //     tc.totalCommissions += tc.commissionAllocations[0].commission;
        //     tc.totalBP += marketplaceFees.tradingCommissionMakerBP;
        // }

        // uint256 additionalCommissionReceiversCount = marketplaceFees.commissionReceiversInfo.length;
        // for (uint256 i; i < additionalCommissionReceiversCount; ++i) {
        //     tc.commissionAllocations[marketplaceReceiverCount + i].commission = (buyAmount * marketplaceFees.commissionReceiversInfo[i].basisPoints) / LibConstants.BP_FACTOR;
        //     tc.totalCommissions += tc.commissionAllocations[marketplaceReceiverCount + i].commission;
        //     tc.totalBP += marketplaceFees.commissionReceiversInfo[i].basisPoints;
        // }
    }

    function _replaceMakerBP(uint16 tradingCommissionMakerBP) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(tradingCommissionMakerBP <= LibConstants.BP_FACTOR / 2, "invalid trading commission total");
        s.tradingCommissionMakerBP = tradingCommissionMakerBP;

        emit MakerBasisPointsUpdated(tradingCommissionMakerBP);
    }

    function _addFeeSchedule(uint256 _feeScheduleId, CommissionReceiverInfo[] calldata _commissionReceivers) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check to see that the total commission does not exceed LibConstants.BP_FACTOR basis points
        uint256 receiverCount = _commissionReceivers.length;
        uint256 totalBp;
        for (uint256 i; i < receiverCount; ++i) {
            totalBp += _commissionReceivers[i].basisPoints;
        }
        if (totalBp > LibConstants.BP_FACTOR / 2) {
            revert CommissionsBasisPointsCannotBeGreaterThan5000(totalBp);
        }

        for (uint256 i; i < receiverCount; ++i) {
            s.feeSchedules[_feeScheduleId].push(_commissionReceivers[i]);
        }

        emit FeeScheduleAdded(s.feeSchedules[_feeScheduleId]);
    }

    function _changePolicyFeeSchedule(uint256 _feeScheduleId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.policyFeeSchedule = _feeScheduleId;
    }

    // function _changeIndividualPolicyCommissionsStrategy(bytes32 _policyId, uint256 _strategyId) internal {
    //     AppStorage storage s = LibAppStorage.diamondStorage();

    //     s.simplePolicies[_policyId].feeSchedule = _strategyId;
    // }

    // function _addCommissionsReceiverToIndividualPolicy(bytes32 _policyId, CommissionReceiverInfo calldata _commissionReceiver) internal {
    //     AppStorage storage s = LibAppStorage.diamondStorage();

    //     s.simplePolicies[_policyId].commissionReceivers.push(_commissionReceiver.receiver);
    //     s.simplePolicies[_policyId].commissionBasisPoints.push(_commissionReceiver.basisPoints);
    // }

    // function _removeCommissionsReceiverFromIndividualPolicy(bytes32 _policyId, bytes32 _receiver) internal {
    //     AppStorage storage s = LibAppStorage.diamondStorage();

    //     SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
    //     uint256 receiverCount = simplePolicy.commissionReceivers.length;
    //     for (uint256 i; i < receiverCount; ++i) {
    //         if (simplePolicy.commissionReceivers[i] == _receiver) {
    //             // Move the last element to the position of the element to be removed
    //             simplePolicy.commissionReceivers[i] = simplePolicy.commissionReceivers[receiverCount - 1];
    //             // Pop off last element
    //             simplePolicy.commissionReceivers.pop();
    //             break;
    //         }
    //     }
    // }
}
