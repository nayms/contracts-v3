// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibAppStorage, AppStorage } from "../shared/AppStorage.sol";
import { Entity, SimplePolicy, Stakeholders, FeeSchedule } from "../shared/AppStorage.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibACL } from "./LibACL.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibMarket } from "./LibMarket.sol";
import { LibSimplePolicy } from "./LibSimplePolicy.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

// prettier-ignore
import { 
    FeeBasisPointsExceedHalfMax, 
    EntityDoesNotExist, 
    DuplicateSignerCreatingSimplePolicy, 
    PolicyIdCannotBeZero, 
    ObjectCannotBeTokenized, 
    EntityExistsAlready, 
    SimplePolicyStakeholderSignatureInvalid, 
    SimplePolicyClaimsPaidShouldStartAtZero, 
    SimplePolicyPremiumsPaidShouldStartAtZero, 
    CancelCannotBeTrueWhenCreatingSimplePolicy, 
    UtilizedCapacityGreaterThanMaxCapacity, 
    EntityOnboardingNotApproved 
} from "../shared/CustomErrors.sol";

library LibEntity {
    using ECDSA for bytes32;
    /**
     * @notice New entity has been created
     * @dev Emitted when entity is created
     * @param entityId Unique ID for the entity
     * @param entityAdmin Unique ID of the entity administrator
     */
    event EntityCreated(bytes32 indexed entityId, bytes32 entityAdmin);
    /**
     * @notice An entity has been updated
     * @dev Emitted when entity is updated
     * @param entityId Unique ID for the entity
     */
    event EntityUpdated(bytes32 indexed entityId);
    /**
     * @notice New policy has been created
     * @dev Emitted when policy is created
     * @param id Unique ID for the policy
     * @param entityId ID of the entity
     */
    event SimplePolicyCreated(bytes32 indexed id, bytes32 entityId);
    /**
     * @notice New token sale has been started
     * @dev Emitted when token sale is started
     * @param entityId Unique ID for the entity
     * @param offerId ID of the sale offer
     * @param tokenSymbol symbol of the token
     * @param tokenName name of the token
     */
    event TokenSaleStarted(bytes32 indexed entityId, uint256 offerId, string tokenSymbol, string tokenName);
    /**
     * @notice Collateral ratio has been updated
     * @dev Emitted when collateral ratio is updated
     * @param entityId ID of the entity
     * @param collateralRatio required collateral ratio
     * @param utilizedCapacity capacity utilization according to the new ratio
     */
    event CollateralRatioUpdated(bytes32 indexed entityId, uint256 collateralRatio, uint256 utilizedCapacity);

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

        FeeSchedule memory feeSchedule = LibFeeRouter._getFeeSchedule(_entityId, LC.FEE_TYPE_PREMIUM);
        uint256 feeReceiversCount = feeSchedule.receiver.length;
        // There must be at least one receiver from the fee schedule
        require(feeReceiversCount > 0, "must have fee schedule receivers"); // error there must be at least one receiver from fee schedule

        // policy-level receivers are expected
        uint256 commissionReceiversArrayLength = simplePolicy.commissionReceivers.length;
        require(commissionReceiversArrayLength <= _stakeholders.roles.length, "too many commission receivers"); // error too many POLICY level commission receivers

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

            signer = getSigner(signingHash, _stakeholders.signatures[i]);

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

    function getSigner(bytes32 signingHash, bytes memory signature) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        if (signature.length == 65) {
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))

                switch v
                // if v == 0, then v = 27
                case 0 {
                    v := 27
                }
                // if v == 1, then v = 28
                case 1 {
                    v := 28
                }
            }
        }

        (address signer, , ) = ECDSA.tryRecover(MessageHashUtils.toEthSignedMessageHash(signingHash), v, r, s);

        return signer;
    }

    /// @param _amount the amount of entity token that is minted and put on sale
    /// @param _totalPrice the buy amount
    function _startTokenSale(bytes32 _entityId, uint256 _amount, uint256 _totalPrice) internal {
        require(_amount > 0, "mint amount must be > 0");
        require(_totalPrice > 0, "total price must be > 0");

        AppStorage storage s = LibAppStorage.diamondStorage();

        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }

        if (!LibObject._isObjectTokenizable(_entityId)) {
            revert ObjectCannotBeTokenized(_entityId);
        }

        Entity memory entity = s.entities[_entityId];

        // note: The participation tokens of the entity are minted to the entity. The participation tokens minted have the same ID as the entity.
        LibTokenizedVault._internalMint(_entityId, _entityId, _amount);

        (uint256 offerId, , ) = LibMarket._executeLimitOffer(_entityId, _entityId, _amount, entity.assetId, _totalPrice, LC.FEE_TYPE_INITIAL_SALE);

        emit TokenSaleStarted(_entityId, offerId, s.objectTokenSymbol[_entityId], s.objectTokenName[_entityId]);
    }

    function _createEntity(bytes32 _entityId, bytes32 _accountAdmin, Entity memory _entity, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.existingEntities[_entityId]) {
            revert EntityExistsAlready(_entityId);
        }
        validateEntity(_entity);

        LibObject._createObject(_entityId, LC.OBJECT_TYPE_ENTITY, _dataHash);
        LibObject._setParent(_accountAdmin, _entityId);
        s.existingEntities[_entityId] = true;

        LibACL._assignRole(_accountAdmin, _entityId, LibHelpers._stringToBytes32(LC.ROLE_ENTITY_ADMIN));

        // An entity starts without any capacity being utilized
        require(_entity.utilizedCapacity == 0, "utilized capacity starts at 0");

        s.entities[_entityId] = _entity;

        emit EntityCreated(_entityId, _accountAdmin);
    }

    /// @dev This currently updates a non cell type entity and a cell type entity, but
    /// we should consider splitting the functionality
    function _updateEntity(bytes32 _entityId, Entity calldata _updateEntityStruct) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Cannot update a non-existing entity's metadata.
        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }

        validateEntity(_updateEntityStruct);

        uint256 oldCollateralRatio = s.entities[_entityId].collateralRatio;
        uint256 oldUtilizedCapacity = s.entities[_entityId].utilizedCapacity;
        bytes32 entityAssetId = s.entities[_entityId].assetId;

        if (entityAssetId != _updateEntityStruct.assetId) {
            revert("assetId change not allowed");
        }

        // can update max capacity and simplePolicyEnabled toggle first since it's not used in collateral ratio calculation below
        s.entities[_entityId].maxCapacity = _updateEntityStruct.maxCapacity;
        s.entities[_entityId].simplePolicyEnabled = _updateEntityStruct.simplePolicyEnabled;

        // if it's a cell, and collateral ratio changed
        if (entityAssetId != 0 && _updateEntityStruct.collateralRatio != oldCollateralRatio) {
            uint256 newUtilizedCapacity = (oldUtilizedCapacity * _updateEntityStruct.collateralRatio) / oldCollateralRatio;
            uint256 newLockedBalance = s.lockedBalances[_entityId][entityAssetId] - oldUtilizedCapacity + newUtilizedCapacity;

            require(LibTokenizedVault._internalBalanceOf(_entityId, entityAssetId) >= newLockedBalance, "collateral ratio invalid, not enough balance");
            require(newUtilizedCapacity <= _updateEntityStruct.maxCapacity, "max capacity must be >= utilized capacity");

            s.entities[_entityId].collateralRatio = _updateEntityStruct.collateralRatio;
            s.entities[_entityId].utilizedCapacity = newUtilizedCapacity;
            s.lockedBalances[_entityId][entityAssetId] = newLockedBalance;

            emit CollateralRatioUpdated(_entityId, _updateEntityStruct.collateralRatio, newUtilizedCapacity);
        }

        emit EntityUpdated(_entityId);
    }

    function validateEntity(Entity memory _entity) internal view {
        // If a non cell type entity is converted into a cell type entity, then the following checks must be performed.
        if (_entity.assetId != 0) {
            // entity has an underlying asset, which means it's a cell

            // External token must be whitelisted by the platform
            require(LibAdmin._isSupportedExternalToken(_entity.assetId), "external token is not supported");

            // Collateral ratio must be in acceptable range of 1 to 10000 basis points (0.01% to 100% collateralized).
            // Cannot ever be completely uncollateralized (0 basis points), if entity is a cell.
            require(1 <= _entity.collateralRatio && _entity.collateralRatio <= LC.BP_FACTOR, "collateral ratio should be 1 to 10000");

            // Max capacity is the capital amount that an entity can write across all of their policies.
            // note: We do not directly use the value maxCapacity to determine if the entity can or cannot write a policy.
            //       First, we use the bool simplePolicyEnabled to toggle (enable / disable) whether an entity can or cannot write a policy.
            //       If an entity has this set to true, then we check if an entity has enough capacity to write a policy.
            require(!_entity.simplePolicyEnabled || (_entity.maxCapacity > 0), "max capacity should be greater than 0 for policy creation");

            if (_entity.utilizedCapacity > _entity.maxCapacity) {
                revert UtilizedCapacityGreaterThanMaxCapacity(_entity.utilizedCapacity, _entity.maxCapacity);
            }
        } else {
            // non-cell entity
            require(_entity.collateralRatio == 0, "only cell has collateral ratio");
            require(!_entity.simplePolicyEnabled, "only cell can issue policies");
            require(_entity.maxCapacity == 0, "only cells have max capacity");
        }
    }

    function _getEntityInfo(bytes32 _entityId) internal view returns (Entity memory entity) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        entity = s.entities[_entityId];
    }

    function _isEntity(bytes32 _entityId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.existingEntities[_entityId];
    }
}
