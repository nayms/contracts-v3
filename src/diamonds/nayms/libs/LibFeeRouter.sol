// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, SimplePolicy, CalculatedFees, FeeAllocation, FeeReceiver } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { PolicyCommissionsBasisPointsCannotBeGreaterThan10000 } from "src/diamonds/nayms/interfaces/CustomErrors.sol";
import { LibEntity } from "./LibEntity.sol";

library LibFeeRouter {
    error FeeBasisPointsCannotBeGreaterThan5000(uint256 totalBp); // todo move

    event TradingCommissionsPaid(bytes32 indexed takerId, bytes32 tokenId, uint256 amount);
    event PremiumCommissionsPaid(bytes32 indexed policyId, bytes32 indexed entityId, uint256 amount);

    event MakerBasisPointsUpdated(uint16 tradingCommissionMakerBP);
    event PolicyFeeScheduleUpdated(uint256 policyFeeSchedule);
    event FeeScheduleAdded(uint256 feeScheduleId, FeeReceiver[] commissionReceivers);

    function _calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal returns (CalculatedFees memory calculatedFees_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;

        uint256 fee;
        uint256 premiumCommissionsIndex;
        for (uint256 i; i < commissionsCount; ++i) {
            fee = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
            calculatedFees_.totalBP += simplePolicy.commissionBasisPoints[i];
            calculatedFees_.totalFees += fee;

            calculatedFees_.feeAllocations[i] = FeeAllocation({ receiver: policyEntityId, basisPoints: simplePolicy.commissionBasisPoints[i], fee: fee });

            premiumCommissionsIndex++;
        }

        FeeReceiver[] memory feeSchedule = s.feeSchedules[LibEntity._getPremiumFeeScheduleId(policyEntityId)];
        uint256 policyFeeStrategyCount = feeSchedule.length;

        for (uint256 i; i < policyFeeStrategyCount; ++i) {
            fee = (_premiumPaid * feeSchedule[i].basisPoints) / LibConstants.BP_FACTOR;
            calculatedFees_.totalBP += feeSchedule[i].basisPoints;
            calculatedFees_.totalFees += fee;

            calculatedFees_.feeAllocations[premiumCommissionsIndex + i] = FeeAllocation({ receiver: feeSchedule[i].receiver, basisPoints: feeSchedule[i].basisPoints, fee: fee });
        }
    }

    function _payPremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];

        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 totalBP;
        uint256 totalFees;
        uint256 commissionsCount = simplePolicy.commissionReceivers.length;

        uint256 fee;
        for (uint256 i; i < commissionsCount; ++i) {
            totalBP += simplePolicy.commissionBasisPoints[i];
            fee = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, fee);
            totalFees += fee;
        }

        FeeReceiver[] memory feeSchedule = s.feeSchedules[LibEntity._getPremiumFeeScheduleId(policyEntityId)];

        uint256 feeScheduleReceiversCount = feeSchedule.length;
        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            totalBP += feeSchedule[i].basisPoints;
            fee = (_premiumPaid * feeSchedule[i].basisPoints) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, feeSchedule[i].receiver, simplePolicy.asset, fee);
            totalFees += fee;
        }

        require(LibConstants.BP_FACTOR > totalBP, "commissions sum over 10000 bp");

        emit PremiumCommissionsPaid(_policyId, policyEntityId, totalFees);
    }

    function _payTradingFees(
        uint256 _feeSchedule,
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _buyAmount,
        bool _takeExternalToken
    ) internal returns (uint256 totalFees) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Get the fee receivers for this _feeSchedule
        FeeReceiver[] memory feeSchedules = s.feeSchedules[_feeSchedule];

        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            uint256 fee = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, fee);

            emit TradingCommissionsPaid(_takerId, _tokenId, fee);
        }

        bytes32 buyer; // The entity that is buying par tokens and the one paying commissions if INITIAL_OFFER
        // bytes32 seller; // The entity that is selling par tokens and the one receiving commissions if INITIAL_OFFER
        if (_feeSchedule == LibConstants.MARKET_FEE_SCHEDULE_INITIAL_OFFER && !_takeExternalToken) {
            buyer = _takerId;
        } else {
            buyer = _makerId;
        }

        uint256 takerBP;
        uint256 makerBP;
        uint256 fee;
        uint256 feeScheduleReceiversCount = feeSchedules.length;
        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            fee = (_buyAmount * feeSchedules[i].basisPoints) / LibConstants.BP_FACTOR;
            totalFees += fee;
            if (buyer == _takerId) {
                takerBP += feeSchedules[i].basisPoints;
            } else if (buyer == _makerId) {
                makerBP += feeSchedules[i].basisPoints;
            }

            LibTokenizedVault._internalTransfer(buyer, feeSchedules[i].receiver, _tokenId, fee);
        }

        require(LibConstants.BP_FACTOR > takerBP + s.tradingCommissionMakerBP, "taker commissions sum over 10000 bp");
        require(LibConstants.BP_FACTOR > makerBP, "maker commissions sum over 10000 bp");

        emit TradingCommissionsPaid(buyer, _tokenId, totalFees);
    }

    function _calculateTradingFees(
        uint256 _feeSchedule,
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _buyAmount,
        bool _takeExternalToken
    ) internal view returns (CalculatedFees memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Get the fee receivers for this _feeSchedule
        FeeReceiver[] memory feeSchedules = s.feeSchedules[_feeSchedule];

        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            uint256 fee = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;

            tc.feeAllocations[0] = FeeAllocation({ receiver: _makerId, basisPoints: s.tradingCommissionMakerBP, fee: fee });
        }

        uint256 feeScheduleReceiversCount = feeSchedules.length;
        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            tc.feeAllocations[feeScheduleReceiversCount + i].basisPoints = feeSchedules[i].basisPoints;
            tc.feeAllocations[feeScheduleReceiversCount + i].fee = (_buyAmount * feeSchedules[i].basisPoints) / LibConstants.BP_FACTOR;
            tc.totalFees += tc.feeAllocations[feeScheduleReceiversCount + i].fee;
            tc.totalBP += feeSchedules[i].basisPoints;

            tc.feeAllocations[feeScheduleReceiversCount + i].receiver = feeSchedules[i].receiver;
        }
    }

    function _replaceMakerBP(uint16 tradingCommissionMakerBP) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(tradingCommissionMakerBP <= LibConstants.BP_FACTOR / 2, "maker bp cannot be greater than 5000");
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
            revert FeeBasisPointsCannotBeGreaterThan5000(totalBp);
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
}
