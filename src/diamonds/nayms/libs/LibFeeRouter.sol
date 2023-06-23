// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, CalculatedFees, FeeAllocation, FeeReceiver } from "../AppStorage.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { FeeBasisPointsExceedHalfMax } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibFeeRouter {
    event TradingFeePaid(uint256 feeScheduleId, bytes32 indexed fromId, bytes32 indexed toId, bytes32 tokenId, uint256 amount);
    event PremiumFeePaid(bytes32 indexed policyId, bytes32 indexed fromId, bytes32 indexed toId, bytes32 tokenId, uint256 amount);

    event MakerBasisPointsUpdated(uint16 tradingCommissionMakerBP);
    event FeeScheduleAdded(uint256 feeScheduleId, FeeReceiver[] feeReceivers);

    function _calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal view returns (CalculatedFees memory cf) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32[] memory commissionReceivers = s.simplePolicies[_policyId].commissionReceivers;
        uint256[] memory commissionBasisPoints = s.simplePolicies[_policyId].commissionBasisPoints;
        uint256 commissionsCount = commissionReceivers.length;

        bytes32 policyEntityId = LibObject._getParent(_policyId);
        FeeReceiver[] memory feeSchedule = s.feeSchedules[_getPremiumFeeScheduleId(policyEntityId)];
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
        uint256 _feeSchedule,
        bytes32 buyer,
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _buyAmount
    ) internal returns (uint256 totalFees_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Get the fee receivers for this _feeSchedule
        FeeReceiver[] memory feeSchedules = s.feeSchedules[_feeSchedule];

        uint256 fee;
        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            fee = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;

            emit TradingFeePaid(_feeSchedule, _takerId, _makerId, _tokenId, fee);
            LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, fee);
        }

        uint256 feeScheduleReceiversCount = feeSchedules.length;
        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            fee = (_buyAmount * feeSchedules[i].basisPoints) / LibConstants.BP_FACTOR;
            totalFees_ += fee;

            emit TradingFeePaid(_feeSchedule, buyer, feeSchedules[i].receiver, _tokenId, fee);
            LibTokenizedVault._internalTransfer(buyer, feeSchedules[i].receiver, _tokenId, fee);
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

    function _addFeeSchedule(uint256 _feeScheduleId, FeeReceiver[] calldata _feeReceivers) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Remove the fee schedule for this _feeScheduleId if it already exists
        delete s.feeSchedules[_feeScheduleId];

        // Check to see that the total basis points does not exceed LibConstants.BP_FACTOR / 2 basis points
        uint256 receiverCount = _feeReceivers.length;
        uint256 totalBp;
        for (uint256 i; i < receiverCount; ++i) {
            totalBp += _feeReceivers[i].basisPoints;
        }
        if (totalBp > LibConstants.BP_FACTOR / 2) {
            revert FeeBasisPointsExceedHalfMax(totalBp, LibConstants.BP_FACTOR / 2);
        }

        for (uint256 i; i < receiverCount; ++i) {
            s.feeSchedules[_feeScheduleId].push(_feeReceivers[i]);
        }

        emit FeeScheduleAdded(_feeScheduleId, s.feeSchedules[_feeScheduleId]);
    }

    function _getFeeSchedule(uint256 _feeScheduleId) internal view returns (FeeReceiver[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.feeSchedules[_feeScheduleId];
    }

    function _getMakerBP() internal view returns (uint16) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tradingCommissionMakerBP;
    }

    function _getPremiumFeeScheduleId(bytes32 _entityId) internal view returns (uint256 feeScheduleId_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 feeScheduleId = uint256(_entityId);

        if (s.feeSchedules[feeScheduleId].length == 0) {
            feeScheduleId_ = LibConstants.PREMIUM_FEE_SCHEDULE_DEFAULT;
        } else {
            feeScheduleId_ = feeScheduleId;
        }
    }

    function _getTradingFeeScheduleId(bytes32 _entityId) internal view returns (uint256 feeScheduleId_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 feeScheduleId = uint256(_entityId) - LibConstants.STORAGE_OFFSET_FOR_CUSTOM_MARKET_FEES;

        if (s.feeSchedules[feeScheduleId].length == 0) {
            feeScheduleId_ = LibConstants.MARKET_FEE_SCHEDULE_DEFAULT;
        } else {
            feeScheduleId_ = feeScheduleId;
        }
    }
}
