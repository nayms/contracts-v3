// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// import { Entity } from "../AppStorage.sol";
import { Entity } from "./FreeStructs.sol";

/**
 * @title System
 * @notice Use it to perform system level operations
 * @dev Use it to perform system level operations
 */
interface ISystemFacet {
    /**
     * @notice New entity has been created
     * @dev Thrown when entity is created
     * @param entityId Unique ID for the entity
     * @param entityAdminId Unique ID of the entity administrator
     */
    event NewEntity(bytes32 entityId, bytes32 entityAdminId);

    // Todo: remove this
    /**
     * Deprocated. Function in admin facet replaces this
     * @notice Whitelist `_underlyingToken` as underlying asset for the entity
     * @dev Whitelist an underlying asset
     * @param _underlyingToken underlying asset address
     */
    function whitelistExternalToken(address _underlyingToken) external;

    /**
     * @notice Create an entity
     * @dev Create a new entity with given properties
     * @param _entityId Unique ID for the entity
     * @param _entityAdmin Unique ID of the entity administrator
     * @param _entityData remaining entity metadata
     * @param _dataHash hash of the offchain data
     */
    function createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entityData,
        bytes32 _dataHash
    ) external;

    /**
     * @notice Approve user on entity
     * @dev Assign user the approved user role in context of entity
     * @param _userId Unique ID of the user
     * @param _entityId Unique ID for the entity
     */
    function approveUser(bytes32 _userId, bytes32 _entityId) external;

    /**
     * @notice Convert a string type to a bytes32 type
     * @param _strIn a string
     */
    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result);
}
