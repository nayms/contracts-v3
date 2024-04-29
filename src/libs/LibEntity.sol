// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibAppStorage, AppStorage } from "../shared/AppStorage.sol";
import { Entity } from "../shared/AppStorage.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibACL } from "./LibACL.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibMarket } from "./LibMarket.sol";

// prettier-ignore
import { 
    EntityDoesNotExist, 
    ObjectCannotBeTokenized, 
    EntityExistsAlready, 
    UtilizedCapacityGreaterThanMaxCapacity, 
    EntityOnboardingNotApproved
} from "../shared/CustomErrors.sol";

library LibEntity {
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

    /// @param _amount the amount of entity token that is minted and put on sale
    /// @param _totalPrice the buy amount
    function _startTokenSale(bytes32 _entityId, uint256 _amount, uint256 _totalPrice) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_amount > 0, "mint amount must be > 0");
        require(_totalPrice > 0, "total price must be > 0");

        bytes32 assetId = s.entities[_entityId].assetId;
        require(_totalPrice > s.objectMinimumSell[assetId], "total price must be greater than asset minimum sell amount");

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
