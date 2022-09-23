// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibAdmin, LibConstants, LibHelpers, Entity, Modifiers } from "../AppStorage.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibEntity } from "../libs/LibEntity.sol";

/**
 * @title System
 * @notice Use it to perform system level operations
 * @dev Use it to perform system level operations
 */
contract SystemFacet is Modifiers {
    /**
     * @notice Create an entity
     * @dev An entity can be created with a zero max capacity! This is in the event where an entity cannot write any policies.
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
    ) external assertSysMgr {
        LibEntity._createEntity(_entityId, _entityAdmin, _entityData, _dataHash);
    }

    /**
     * @notice Convert a string type to a bytes32 type
     * @param _strIn a string
     */
    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result) {
        result = LibHelpers._stringToBytes32(_strIn);
    }
}
