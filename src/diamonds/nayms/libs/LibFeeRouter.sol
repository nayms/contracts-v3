// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, SimplePolicy, CalculatedFees, FeeAllocation, FeeReceiver } from "../AppStorage.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { PolicyCommissionsBasisPointsCannotBeGreaterThan10000 } from "src/diamonds/nayms/interfaces/CustomErrors.sol";
import { LibEntity } from "./LibEntity.sol";
import { console2 } from "forge-std/console2.sol";

library LibFeeRouter {
    error FeeBasisPointsCannotBeGreaterThan5000(uint256 totalBp); // todo move

    event TradingFeesPaid(bytes32 indexed fromId, bytes32 indexed toId, bytes32 tokenId, uint256 amount);
    event PremiumCommissionsPaid(bytes32 indexed policyId, bytes32 indexed entityId, uint256 amount); // todo update

    event MakerBasisPointsUpdated(uint16 tradingCommissionMakerBP);
    event FeeScheduleAdded(uint256 feeScheduleId, FeeReceiver[] feeReceivers);

    function _calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal returns (CalculatedFees memory cf) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];
        uint256 commissionsCount = simplePolicy.commissionReceivers.length;

        bytes32 policyEntityId = LibObject._getParent(_policyId);
        FeeReceiver[] memory feeSchedule = s.feeSchedules[LibEntity._getPremiumFeeScheduleId(policyEntityId)];
        uint256 feeScheduleReceiversCount = feeSchedule.length;

        uint256 totalReceiverCount;
        totalReceiverCount += feeScheduleReceiversCount + commissionsCount;

        cf.feeAllocations = new FeeAllocation[](totalReceiverCount);

        uint256 fee;
        for (uint256 i; i < commissionsCount; ++i) {
            fee = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;

            cf.feeAllocations[i].to = simplePolicy.commissionReceivers[i];
            cf.feeAllocations[i].basisPoints = simplePolicy.commissionBasisPoints[i];
            cf.feeAllocations[i].fee = fee;

            cf.totalBP += simplePolicy.commissionBasisPoints[i];
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

    event DebugPayTradingFees(bytes32 _makerId, bytes32 _takerId, bytes32 _tokenId, uint256 _buyAmount);

    event DebugTradingTransfer(bytes32 _from, bytes32 _to, bytes32 _tokenId, uint256 _amount);

    event DebugBuyer(uint256 feeSchedule, bool _takeExternalToken, bytes32 buyer);

    function _payTradingFees(uint256 _feeSchedule, bytes32 buyer, bytes32 _makerId, bytes32 _takerId, bytes32 _tokenId, uint256 _buyAmount) internal returns (uint256 totalFees) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        emit DebugPayTradingFees(_makerId, _takerId, _tokenId, _buyAmount);
        // Get the fee receivers for this _feeSchedule
        FeeReceiver[] memory feeSchedules = s.feeSchedules[_feeSchedule];

        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            uint256 fee = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, fee);

            emit TradingFeesPaid(_takerId, _makerId, _tokenId, fee);
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

            emit TradingFeesPaid(buyer, feeSchedules[i].receiver, _tokenId, fee);
        }

        require(LibConstants.BP_FACTOR > takerBP + s.tradingCommissionMakerBP, "taker commissions sum over 10000 bp");
        require(LibConstants.BP_FACTOR > makerBP, "maker commissions sum over 10000 bp");
    }

    function _calculateTradingFees(bytes32 _buyer, uint256 _buyAmount) internal view returns (CalculatedFees memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 feeScheduleId = LibEntity._getTradingFeeScheduleId(_buyer);
        // Get the fee receivers for this _feeSchedule
        FeeReceiver[] memory feeSchedules = s.feeSchedules[feeScheduleId];

        uint256 totalReceiverCount;
        if (s.tradingCommissionMakerBP > 0) {
            totalReceiverCount++;
        }

        uint256 feeScheduleReceiversCount = feeSchedules.length;
        totalReceiverCount += feeScheduleReceiversCount;

        tc.feeAllocations = new FeeAllocation[](totalReceiverCount);

        uint256 receiverCount;
        // Calculate fees for the market maker
        if (s.tradingCommissionMakerBP > 0) {
            tc.feeAllocations[0].to = _buyer;
            tc.feeAllocations[0].basisPoints = s.tradingCommissionMakerBP;
            tc.feeAllocations[0].fee = (_buyAmount * s.tradingCommissionMakerBP) / LibConstants.BP_FACTOR;

            tc.totalFees += tc.feeAllocations[0].fee;
            tc.totalBP += s.tradingCommissionMakerBP;

            receiverCount++;
        }

        for (uint256 i; i < feeScheduleReceiversCount; ++i) {
            tc.feeAllocations[receiverCount + i].to = feeSchedules[i].receiver;
            tc.feeAllocations[receiverCount + i].basisPoints = feeSchedules[i].basisPoints;
            tc.feeAllocations[receiverCount + i].fee = (_buyAmount * feeSchedules[i].basisPoints) / LibConstants.BP_FACTOR;

            tc.totalFees += tc.feeAllocations[receiverCount + i].fee;
            tc.totalBP += feeSchedules[i].basisPoints;
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

    function _getMakerBP() internal view returns (uint16) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tradingCommissionMakerBP;
    }
}
