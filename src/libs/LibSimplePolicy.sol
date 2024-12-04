// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { AppStorage, LibAppStorage, Entity, SimplePolicy, Stakeholders, FeeSchedule } from "../shared/AppStorage.sol";
import { LibACL } from "./LibACL.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibEIP712 } from "./LibEIP712.sol";

import { ExcessiveCommissionReceivers, FeeBasisPointsExceedHalfMax, EntityDoesNotExist, PolicyDoesNotExist, PolicyCannotCancelAfterMaturation, PolicyIdCannotBeZero, DuplicateSignerCreatingSimplePolicy, SimplePolicyStakeholderSignatureInvalid, SimplePolicyClaimsPaidShouldStartAtZero, SimplePolicyPremiumsPaidShouldStartAtZero, CancelCannotBeTrueWhenCreatingSimplePolicy, MaturationDateTooFar } from "../shared/CustomErrors.sol";

library LibSimplePolicy {
    /**
     * @notice New policy has been created
     * @dev Emitted when policy is created
     * @param id Unique ID for the policy
     * @param entityId ID of the entity
     */
    event SimplePolicyCreated(bytes32 indexed id, bytes32 entityId);
    event SimplePolicyMatured(bytes32 indexed id);
    event SimplePolicyCancelled(bytes32 indexed id);
    event SimplePolicyPremiumPaid(bytes32 indexed id, uint256 amount);
    event SimplePolicyClaimPaid(bytes32 indexed claimId, bytes32 indexed policyId, bytes32 indexed insuredId, uint256 amount);

    function _createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata _stakeholders,
        SimplePolicy calldata _simplePolicy,
        bytes32 _offchainDataHash
    ) internal {
        if (_policyId == 0) {
            revert PolicyIdCannotBeZero();
        }

        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }
        require(_stakeholders.entityIds.length == _stakeholders.signatures.length, "incorrect number of signatures");

        s.simplePolicies[_policyId] = _simplePolicy;

        _validateSimplePolicyCreation(_entityId, s.simplePolicies[_policyId], _stakeholders);

        Entity storage entity = s.entities[_entityId];
        uint256 factoredLimit = (_simplePolicy.limit * entity.collateralRatio) / LC.BP_FACTOR;

        entity.utilizedCapacity += factoredLimit;
        s.lockedBalances[_entityId][entity.assetId] += factoredLimit;

        // hash contents are implicitly checked by making sure that resolved signer is the stakeholder entity's admin
        bytes32 signingHash = LibSimplePolicy._getSigningHash(_simplePolicy.startDate, _simplePolicy.maturationDate, _simplePolicy.asset, _simplePolicy.limit, _offchainDataHash);

        LibObject._createObject(_policyId, LC.OBJECT_TYPE_POLICY, _entityId, signingHash);
        s.simplePolicies[_policyId].fundsLocked = true;

        uint256 rolesCount = _stakeholders.roles.length;
        address signer;
        address previousSigner;

        for (uint256 i = 0; i < rolesCount; i++) {
            previousSigner = signer;

            signer = LibAdmin._getSigner(signingHash, _stakeholders.signatures[i]);

            if (LibObject._getParentFromAddress(signer) != _stakeholders.entityIds[i]) {
                revert SimplePolicyStakeholderSignatureInvalid(
                    signingHash,
                    _stakeholders.signatures[i],
                    LibHelpers._getIdForAddress(signer),
                    LibObject._getParentFromAddress(signer),
                    _stakeholders.entityIds[i]
                );
            }

            // Ensure there are no duplicate signers.
            if (previousSigner >= signer) {
                revert DuplicateSignerCreatingSimplePolicy(previousSigner, signer);
            }

            LibACL._assignRole(_stakeholders.entityIds[i], _policyId, _stakeholders.roles[i]);
        }

        s.existingSimplePolicies[_policyId] = true;
        emit SimplePolicyCreated(_policyId, _entityId);
    }

    /**
     * @dev If an entity passes their checks to create a policy, ensure that the entity's capacity is appropriately decreased by the amount of capital that will be tied to the new policy being created.
     */

    function _validateSimplePolicyCreation(bytes32 _entityId, SimplePolicy memory simplePolicy, Stakeholders calldata _stakeholders) internal view {
        // The policy's limit cannot be 0. If a policy's limit is zero, this essentially means the policy doesn't require any capital, which doesn't make business sense.
        require(simplePolicy.limit > 0, "limit not > 0");
        require(LibAdmin._isSupportedExternalToken(simplePolicy.asset), "external token is not supported");

        if (simplePolicy.claimsPaid != 0) {
            revert SimplePolicyClaimsPaidShouldStartAtZero();
        }
        if (simplePolicy.premiumsPaid != 0) {
            revert SimplePolicyPremiumsPaidShouldStartAtZero();
        }
        if (simplePolicy.cancelled) {
            revert CancelCannotBeTrueWhenCreatingSimplePolicy();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        require(simplePolicy.asset == entity.assetId, "asset not matching with entity");

        // Calculate the entity's utilized capacity after it writes this policy.
        uint256 additionalCapacityNeeded = ((simplePolicy.limit * entity.collateralRatio) / LC.BP_FACTOR);
        uint256 updatedUtilizedCapacity = entity.utilizedCapacity + additionalCapacityNeeded;

        // The entity must have enough capacity available to write this policy.
        // An entity is not able to write an additional policy that will utilize its capacity beyond its assigned max capacity.
        require(entity.maxCapacity >= updatedUtilizedCapacity, "not enough available capacity");

        // The entity's balance must be >= to the updated capacity requirement
        uint256 availableBalance = LibTokenizedVault._internalBalanceOf(_entityId, simplePolicy.asset) - LibTokenizedVault._getLockedBalance(_entityId, simplePolicy.asset);
        require(availableBalance >= additionalCapacityNeeded, "not enough capital");

        require(simplePolicy.startDate >= block.timestamp, "start date < block.timestamp");
        require(simplePolicy.maturationDate > simplePolicy.startDate, "start date > maturation date");

        require(simplePolicy.maturationDate - simplePolicy.startDate > 1 days, "policy period must be more than a day");

        if (simplePolicy.maturationDate > block.timestamp + LC.MAX_MATURATION_PERIOD) revert MaturationDateTooFar(simplePolicy.maturationDate);

        FeeSchedule memory feeSchedule = LibFeeRouter._getFeeSchedule(_entityId, LC.FEE_TYPE_PREMIUM);
        uint256 feeReceiversCount = feeSchedule.receiver.length;
        // There must be at least one receiver from the fee schedule
        require(feeReceiversCount > 0, "must have fee schedule receivers"); // error there must be at least one receiver from fee schedule

        // policy-level receivers are expected
        uint256 commissionReceiversArrayLength = simplePolicy.commissionReceivers.length;
        // note: The number of commission receivers could be less than the number of stakeholders, but not more.
        require(commissionReceiversArrayLength <= _stakeholders.roles.length, "too many commission receivers"); // error too many POLICY level commission receivers

        if (commissionReceiversArrayLength > LC.MAX_POLICY_COMMISSION_RECEIVERS) {
            revert ExcessiveCommissionReceivers(commissionReceiversArrayLength, LC.MAX_POLICY_COMMISSION_RECEIVERS);
        }

        uint256 commissionBasisPointsArrayLength = simplePolicy.commissionBasisPoints.length;
        require(commissionReceiversArrayLength == commissionBasisPointsArrayLength, "number of commissions don't match");

        uint256 commissionReceiversTotalBP;
        for (uint256 i; i < commissionBasisPointsArrayLength; ++i) {
            commissionReceiversTotalBP += simplePolicy.commissionBasisPoints[i];
        }

        if (commissionReceiversTotalBP > LC.BP_FACTOR / 2) {
            revert FeeBasisPointsExceedHalfMax(commissionReceiversTotalBP, LC.BP_FACTOR / 2);
        }

        require(_stakeholders.roles.length == _stakeholders.entityIds.length, "stakeholders roles mismatch");
    }

    function _getSimplePolicyInfo(bytes32 _policyId) internal view returns (SimplePolicy memory simplePolicyInfo) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        simplePolicyInfo = s.simplePolicies[_policyId];
    }

    function _checkAndUpdateState(bytes32 _policyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];

        if (!simplePolicy.cancelled && block.timestamp >= simplePolicy.maturationDate && simplePolicy.fundsLocked) {
            // When the policy matures, the entity regains their capacity that was being utilized for that policy.
            releaseFunds(_policyId);

            // emit event
            emit SimplePolicyMatured(_policyId);
        }
    }

    function _payPremium(bytes32 _payerEntityId, bytes32 _policyId, uint256 _amount) internal {
        require(_amount > 0, "invalid premium amount");

        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.existingEntities[_payerEntityId]) {
            revert EntityDoesNotExist(_payerEntityId);
        }
        if (!s.existingSimplePolicies[_policyId]) {
            revert PolicyDoesNotExist(_policyId);
        }
        bytes32 policyEntityId = LibObject._getParent(_policyId);
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy is cancelled");

        LibTokenizedVault._internalTransfer(_payerEntityId, policyEntityId, simplePolicy.asset, _amount);
        LibFeeRouter._payPremiumFees(_policyId, _amount);

        simplePolicy.premiumsPaid += _amount;

        emit SimplePolicyPremiumPaid(_policyId, _amount);
    }

    function _payClaim(bytes32 _claimId, bytes32 _policyId, bytes32 _insuredEntityId, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_amount > 0, "invalid claim amount");
        require(LibACL._isInGroup(_insuredEntityId, _policyId, LibHelpers._stringToBytes32(LC.GROUP_INSURED_PARTIES)), "not an insured party");

        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy is cancelled");

        uint256 claimsPaid = simplePolicy.claimsPaid;
        require(simplePolicy.limit >= _amount + claimsPaid, "exceeds policy limit");
        simplePolicy.claimsPaid += _amount;

        bytes32 entityId = LibObject._getParent(_policyId);
        Entity memory entity = s.entities[entityId];

        if (simplePolicy.fundsLocked) {
            s.lockedBalances[entityId][entity.assetId] -= (_amount * entity.collateralRatio) / LC.BP_FACTOR;
            s.entities[entityId].utilizedCapacity -= (_amount * entity.collateralRatio) / LC.BP_FACTOR;
        } else {
            uint256 availableBalance = LibTokenizedVault._internalBalanceOf(entityId, simplePolicy.asset) - LibTokenizedVault._getLockedBalance(entityId, simplePolicy.asset);
            require(availableBalance >= _amount, "not enough balance");
        }

        LibObject._createObject(_claimId, LC.OBJECT_TYPE_CLAIM);

        LibTokenizedVault._internalTransfer(entityId, _insuredEntityId, simplePolicy.asset, _amount);

        emit SimplePolicyClaimPaid(_claimId, _policyId, _insuredEntityId, _amount);
    }

    function _cancel(bytes32 _policyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy already cancelled");

        if (block.timestamp >= simplePolicy.maturationDate) {
            revert PolicyCannotCancelAfterMaturation(_policyId);
        }

        releaseFunds(_policyId);
        simplePolicy.cancelled = true;

        emit SimplePolicyCancelled(_policyId);
    }

    function releaseFunds(bytes32 _policyId) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 entityId = LibObject._getParent(_policyId);

        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        Entity storage entity = s.entities[entityId];

        uint256 policyLockedAmount = ((simplePolicy.limit - simplePolicy.claimsPaid) * entity.collateralRatio) / LC.BP_FACTOR;
        entity.utilizedCapacity -= policyLockedAmount;
        s.lockedBalances[entityId][entity.assetId] -= policyLockedAmount;

        simplePolicy.fundsLocked = false;
    }

    function _getSigningHash(uint256 _startDate, uint256 _maturationDate, bytes32 _asset, uint256 _limit, bytes32 _offchainDataHash) internal view returns (bytes32) {
        return
            LibEIP712._hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("SimplePolicy(uint256 startDate,uint256 maturationDate,bytes32 asset,uint256 limit,bytes32 offchainDataHash)"),
                        _startDate,
                        _maturationDate,
                        _asset,
                        _limit,
                        _offchainDataHash
                    )
                )
            );
    }
}
