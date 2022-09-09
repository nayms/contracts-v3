// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibAdmin, LibConstants, LibHelpers, Entity, Modifiers } from "../AppStorage.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibACL } from "../libs/LibACL.sol";

contract SystemFacet is Modifiers {
    event NewEntity(bytes32 entityId, bytes32 _entityAdmin);

    function createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entityData
    ) external assertSysMgr {
        LibObject._createObject(_entityId);

        // state that this is an entity
        s.existingEntities[_entityId] = true;

        // setParent(objectId, parentId)
        LibObject._setParent(_entityAdmin, _entityId);

        emit NewEntity(_entityId, _entityAdmin);

        LibACL._assignRole(_entityAdmin, _entityId, LibHelpers._stringToBytes32(LibConstants.ROLE_ENTITY_ADMIN));
        s.entities[_entityId] = _entityData;
    }

    function approveUser(bytes32 _userId, bytes32 _entityId) external assertSysMgr {
        LibACL._assignRole(_userId, LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.ROLE_APPROVED_USER));
        LibObject._setParent(_userId, _entityId);
    }

    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result) {
        result = LibHelpers._stringToBytes32(_strIn);
    }
}
