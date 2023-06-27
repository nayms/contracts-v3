// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, CalculatedFees, FeeAllocation, FeeSchedule } from "../AppStorage.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { FeeBasisPointsExceedHalfMax } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibFeeRouter {
    event TradingFeePaid(bytes32 indexed fromId, bytes32 indexed toId, bytes32 tokenId, uint256 amount);
    event PremiumFeePaid(bytes32 indexed policyId, bytes32 indexed fromId, bytes32 indexed toId, bytes32 tokenId, uint256 amount);

    event MakerBasisPointsUpdated(uint16 tradingCommissionMakerBP);
    event FeeScheduleAdded(bytes32 _entityId, uint256 _feeType, FeeSchedule feeSchedule);

    function _calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal view returns (CalculatedFees memory cf) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32[] memory commissionReceivers = s.simplePolicies[_policyId].commissionReceivers;
        uint256[] memory commissionBasisPoints = s.simplePolicies[_policyId].commissionBasisPoints;
        uint256 commissionsCount = commissionReceivers.length;

        bytes32 parentEntityId = LibObject._getParent(_policyId);
        FeeSchedule memory feeSchedule = s.feeSchedules[parentEntityId][LibConstants.FEE_TYPE_PREMIUM];
        uint256 feeScheduleReceiversCount = feeSchedule.length;

        uint256 totalReceiverCount;
        totalReceiverCount += feeScheduleReceiversCount + commissionsCount;

        cf.feeAllocations = new FeeAllocation[](totalReceiverCount);

        uint256 fee;
        for (uint256 i; i < commissionsCount; ++i) {
            fee = (_premiumPaid * commissionBasisPoints[i]) / LibConstants.BP_FACTOR;

            cf.feeAllocations[i].to = commissionReceivers[i];
            cf.feeAllocations[i].basisPoints = commissionBasisPoints[i];
            cf.feeAllocations[i].fee = fee;

            cf.totalBP += commissionBasisPoints[i];
            cf.totalFees += fee;
        }

        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            fee = (_premiumPaid * feeSchedule[i].basisPoints) / LibConstants.BP_FACTOR;

            cf.feeAllocations[i].to = feeSchedule[i].receiver;
            cf.feeAllocations[i].basisPoints = feeSchedule[i].basisPoints;
            cf.feeAllocations[i].fee = fee;

            cf.totalBP += feeSchedule[i].basisPoints;
            cf.totalFees += fee;
        }
    }

    /// @dev The total bp for a policy premium fee schedule cannot exceed LibConstants.BP_FACTOR since the policy's additional fee receivers and fee schedule are each checked to be less than LibConstants.BP_FACTOR / 2 when they are being set.
    function _payPremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32[] memory commissionReceivers = s.simplePolicies[_policyId].commissionReceivers;
        uint256[] memory commissionBasisPoints = s.simplePolicies[_policyId].commissionBasisPoints;
        uint256 commissionsCount = commissionReceivers.length;

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        bytes32 asset = s.simplePolicies[_policyId].asset;
        uint256 fee;
        for (uint256 i; i < commissionsCount; ++i) {
            fee = (_premiumPaid * commissionBasisPoints[i]) / LibConstants.BP_FACTOR;

            emit PremiumFeePaid(_policyId, policyEntityId, commissionReceivers[i], asset, fee);
            LibTokenizedVault._internalTransfer(policyEntityId, commissionReceivers[i], asset, fee);
        }

        FeeReceiver[] memory feeSchedule = s.feeSchedules[_getPremiumFeeScheduleId(policyEntityId)];

        uint256 feeScheduleReceiversCount = feeSchedule.length;
        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            fee = (_premiumPaid * feeSchedule[i].basisPoints) / LibConstants.BP_FACTOR;

            emit PremiumFeePaid(_policyId, policyEntityId, feeSchedule[i].receiver, asset, fee);
            LibTokenizedVault._internalTransfer(policyEntityId, feeSchedule[i].receiver, asset, fee);
        }
    }

    function _calculateTradingFees(bytes32 _buyer, uint256 _buyAmount) internal view returns (CalculatedFees memory cf) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 feeScheduleId = _getTradingFeeScheduleId(_buyer);
        // Get the fee receivers for this _feeSchedule
        FeeReceiver[] memory feeSchedules = s.feeSchedules[feeScheduleId];

        uint256 totalReceiverCount;
        if (s.tradingCommissionMakerBP > 0) {
            totalReceiverCount++;
        }

        uint256 feeScheduleReceiversCount = feeSchedules.length;
        totalReceiverCount += feeScheduleReceiversCount;

        cf.feeAllocations = new FeeAllocation[](totalReceiverCount);

        uint256 receiverCount;
        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            cf.feeAllocations[0].to = _buyer;
            cf.feeAllocations[0].basisPoints = s.tradingCommissionMakerBP;
            cf.feeAllocations[0].fee = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;

            cf.totalFees += cf.feeAllocations[0].fee;
            cf.totalBP += s.tradingCommissionMakerBP;

            receiverCount++;
        }

        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            cf.feeAllocations[receiverCount + i].to = feeSchedules[i].receiver;
            cf.feeAllocations[receiverCount + i].basisPoints = feeSchedules[i].basisPoints;
            cf.feeAllocations[receiverCount + i].fee = (_buyAmount * feeSchedules[i].basisPoints) / LibConstants.BP_FACTOR;

            cf.totalFees += cf.feeAllocations[receiverCount + i].fee;
            cf.totalBP += feeSchedules[i].basisPoints;
        }
    }

    /// @dev The total bp for a marketplace fee schedule cannot exceed LibConstants.BP_FACTOR since the maker BP and fee schedules are each checked to be less than LibConstants.BP_FACTOR / 2 when they are being set.
    function _payTradingFees(
        uint256 _feeScheduleType,
        bytes32 _buyer,
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _buyAmount
    ) internal returns (uint256 totalFees_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Get the fee receivers for this _feeScheduleType
        FeeSchedule memory feeSchedule = s.feeSchedules[_buyer][_feeScheduleType];

        uint256 fee;
        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            fee = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;

            emit TradingFeePaid(_takerId, _makerId, _tokenId, fee);
            LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, fee);
        }

        uint256 feeScheduleReceiversCount = feeSchedule.receiver.length;
        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            fee = (_buyAmount * feeSchedule.basisPoints[i]) / LibConstants.BP_FACTOR;
            totalFees_ += fee;

            emit TradingFeePaid(_buyer, feeSchedules.receiver[i], _tokenId, fee);
            LibTokenizedVault._internalTransfer(_buyer, feeSchedules.receiver[i], _tokenId, fee);
        }
    }

    function _replaceMakerBP(uint16 tradingCommissionMakerBP) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (tradingCommissionMakerBP > LibConstants.BP_FACTOR / 2) {
            revert FeeBasisPointsExceedHalfMax(tradingCommissionMakerBP, LibConstants.BP_FACTOR / 2);
        }

        s.tradingCommissionMakerBP = tradingCommissionMakerBP;

        emit MakerBasisPointsUpdated(tradingCommissionMakerBP);
    }

    function _addFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType, FeeSchedule calldata _feeSchedule) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Remove the fee schedule for this _entityId/_feeScheduleType if it already exists
        delete s.feeSchedules[_entityId][_feeScheduleType];

        // Check to see that the total basis points does not exceed LibConstants.BP_FACTOR / 2 basis points
        uint256 receiverCount = _feeSchedule.length;
        uint256 totalBp;
        for (uint256 i; i < receiverCount; ++i) {
            totalBp += _feeSchedule.basisPoints[i];
        }
        if (totalBp > LibConstants.BP_FACTOR / 2) {
            revert FeeBasisPointsExceedHalfMax(totalBp, LibConstants.BP_FACTOR / 2);
        }

        s.feeSchedules[_entityId][_feeScheduleType] = _feeSchedule;

        emit FeeScheduleAdded(_entityId, _feeScheduleType, _feeSchedule);
    }

    function _getFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) internal view returns (FeeSchedule memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        FeeSchedule memory feeSchedule = s.feeSchedules[_entityId][_feeScheduleType];
        
        if(feeSchedule.receiver.length == 0 || feeSchedule.receiver.length != feeSchedule.basisPoints.length) {
            // return default fee schedule
            if(_feeScheduleType == LibConstants.FEE_TYPE_TRADING) {
                feeSchedule = s.feeSchedules[DEFAULT_TRADING_FEE_SCHEDULE][_feeScheduleType];
            } else if (_feeScheduleType == LibConstants.FEE_TYPE_INITIAL_SALE) {
                feeSchedule = s.feeSchedules[DEFAULT_INITIAL_SALE_FEE_SCHEDULE][_feeScheduleType];
            } else if (_feeScheduleType == LibConstants.FEE_TYPE_PREMIUM) {
                feeSchedule = s.feeSchedules[DEFAULT_PREMIUM_FEE_SCHEDULE][_feeScheduleType];
            } else {
                revert("invalid fee schedule type");
            }
        }
        return feeSchedule;
    }

    function _getMakerBP() internal view returns (uint16) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tradingCommissionMakerBP;
    }

}
