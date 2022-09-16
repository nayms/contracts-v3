// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibAppStorage, AppStorage, LibAdmin, LibConstants, LibHelpers, Entity, SimplePolicy, Stakeholders } from "../AppStorage.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibMarket } from "../libs/LibMarket.sol";

import "../../../utils/ECDSA.sol";

library LibEntity {
    using ECDSA for bytes32;

    event EntityCreated(bytes32 entityId, bytes32 _entityAdmin);
    event EntityUpdated(bytes32 entityId);
    event SimplePolicyCreated(bytes32 indexed id, bytes32 entityId);
    event TokenSaleStarted(bytes32 indexed entityId, uint256 offerId);

    /**
     * @dev If an entity passes their checks to create a policy, ensure that the entity's capacity is appropriately decreased by the amount of capital that will be tied to the new policy being created.
     */
    function _validateSimplePolicyCreation(bytes32 _entityId, SimplePolicy calldata simplePolicy) internal view returns (uint256 updatedUtilizedCapacity) {
        // The policy's limit cannot be 0. If a policy's limit is zero, this essentially means the policy doesn't require any capital, which doesn't make business sense.
        require(simplePolicy.limit > 0, "limit not > 0");

        bool isEntityAdmin = LibACL._isInGroup(LibHelpers._getSenderId(), _entityId, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS));
        require(isEntityAdmin, "must be entity admin");

        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        // todo: ensure that the capital raised is >= max capacity. Probably want to do this check when the trade is made.
        // note: An entity cannot be created / updated to have a 0 collateral ratio, 0 max capacity. We can keep these checks here for now.
        require(entity.collateralRatio > 0 && entity.maxCapacity > 0, "currency disabled");

        // Calculate the entity's utilized capacity after it writes this policy.
        updatedUtilizedCapacity = entity.utilizedCapacity + simplePolicy.limit;

        // The entity must have enough capacity available to write this policy.
        // An entity is not able to write an additional policy that will utilize its capacity beyond its assigned max capacity.
        require(entity.maxCapacity >= updatedUtilizedCapacity, "not enough available capacity");

        // Calculate the entity's required capital for its capacity utilization based on its collateral requirements.
        uint256 capitalRequirementForUpdatedUtilizedCapacity = (updatedUtilizedCapacity * entity.collateralRatio) / 1000;

        // The entity's balance must be >= to the updated capacity requirement
        // todo: business only wants to count the entity's balance that was raised from the participation token sale and not its total balance
        require(LibTokenizedVault._internalBalanceOf(_entityId, simplePolicy.asset) >= capitalRequirementForUpdatedUtilizedCapacity, "not enough capital");

        require(simplePolicy.startDate >= block.timestamp, "start date < block.timestamp");
        require(simplePolicy.maturationDate > simplePolicy.startDate, "start date > maturation date");
        require(LibAdmin._isSupportedExternalToken(simplePolicy.asset), "external token is not supported");
        require(simplePolicy.limit > 0, "limit == 0");

        uint256 commissionReceiversArrayLength = simplePolicy.commissionReceivers.length;
        require(commissionReceiversArrayLength > 0, "must have commission receivers");

        uint256 commissionBasisPointsArrayLength = simplePolicy.commissionBasisPoints.length;
        require(commissionBasisPointsArrayLength > 0, "must have commission basis points");
        require(commissionReceiversArrayLength == commissionBasisPointsArrayLength, "commissions lengths !=");

        uint256 totalBP;
        for (uint256 i; i < commissionBasisPointsArrayLength; ++i) {
            totalBP += simplePolicy.commissionBasisPoints[i];
        }
        require(totalBP <= 1000, "bp cannot be > 1000");
    }

    function _createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata stakeholders,
        SimplePolicy calldata simplePolicy,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // note: An entity's updated utilized capacity <= max capitalization check is done in _validateSimplePolicyCreation().
        // Update state with the entity's updated utilized capacity.
        s.entities[_entityId].utilizedCapacity = _validateSimplePolicyCreation(_entityId, simplePolicy);

        LibObject._createObject(_policyId, _entityId, _dataHash);
        s.simplePolicies[_policyId] = simplePolicy;
        s.simplePolicies[_policyId].fundsLocked = true;

        // todo: move check up to follow checks, effects, interactions pattern
        require(stakeholders.entityIds.length == stakeholders.signatures.length, "incorrect number of signatures");
        uint256 rolesCount = stakeholders.roles.length;

        for (uint256 i = 0; i < rolesCount; i++) {
            address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_policyId), stakeholders.signatures[i]);
            bytes32 signerId = LibHelpers._getIdForAddress(signer);

            require(LibACL._isInGroup(signerId, stakeholders.entityIds[i], LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)), "invalid stakeholder");
            LibACL._assignRole(stakeholders.entityIds[i], _policyId, stakeholders.roles[i]);
        }

        emit SimplePolicyCreated(_policyId, _entityId);
    }

    function _updateAllowSimplePolicy(bytes32 _entityId, bool _allow) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.entities[_entityId].simplePolicyEnabled = _allow;
    }

    /// @param _amount the amount of entity token that is minted and put on sale
    /// @param _totalPrice the buy amount
    function _startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) internal {
        require(_amount > 0, "mint amount must be > 0");
        require(_totalPrice > 0, "total price must be > 0");

        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        LibTokenizedVault._internalMint(_entityId, _entityId, _amount);

        (uint256 offerId, , ) = LibMarket._executeLimitOffer(_entityId, _entityId, _amount, entity.assetId, _totalPrice, LibConstants.FEE_SCHEDULE_STANDARD);

        emit TokenSaleStarted(_entityId, offerId);
    }

    function _createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entity,
        bytes32 _dataHash
    ) internal {
        require(LibAdmin._isSupportedExternalToken(_entity.assetId), "external token is not supported");
        require(1 <= _entity.collateralRatio && _entity.collateralRatio <= 1000, "collateral ratio should be 1 to 1000");

        AppStorage storage s = LibAppStorage.diamondStorage();

        LibObject._createObject(_entityId, _dataHash);
        LibObject._setParent(_entityAdmin, _entityId);
        s.existingEntities[_entityId] = true;

        LibACL._assignRole(_entityAdmin, _entityId, LibHelpers._stringToBytes32(LibConstants.ROLE_ENTITY_ADMIN));

        // An entity starts without any capacity being utilized
        delete _entity.utilizedCapacity;

        s.entities[_entityId] = _entity;

        emit EntityCreated(_entityId, _entityAdmin);
    }

    function _updateEntity(bytes32 _entityId, Entity memory _entity) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // External token must be whitelisted by the platform.
        require(LibAdmin._isSupportedExternalToken(_entity.assetId), "external token is not supported");
        // Collateral ratio must be in acceptable range of 1 to 1000 basis points (0.01% to 100% collateralized).
        // Cannot ever be completely uncollateralized (0 basis points).
        require(1 <= _entity.collateralRatio && _entity.collateralRatio <= 1000, "collateral ratio should be 1 to 1000");
        // Max capacity is the capital amount that an entity can write across all of their policies.
        // note: We do not directly use the value maxCapacity to determine if the entity can or cannot write a policy. First, we use the bool simplePolicyEnabled to control and dictate
        //       whether an entity can or cannot write a policy. If an entity has this set to true, then we check if an entity has enough capacity to write the policy.

        // note: When first creating an entity, utilizedCapacity should be 0. Utilized capacity is determined by the policy limits the entity has written.
        // Update state.
        s.entities[_entityId] = _entity;
        emit EntityUpdated(_entityId);
    }

    function _getEntityInfo(bytes32 _entityId) internal view returns (Entity memory entity) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        entity = s.entities[_entityId];
    }
}
