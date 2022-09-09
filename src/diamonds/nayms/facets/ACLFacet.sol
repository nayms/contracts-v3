// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibACL, LibHelpers } from "../libs/LibACL.sol";
import { IACLFacet } from "../interfaces/IACLFacet.sol";

contract ACLFacet is IACLFacet {
    function assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external {
        bytes32 assignerId = LibHelpers._getIdForAddress(msg.sender);
        require(LibACL._canAssign(assignerId, _objectId, _contextId, LibHelpers._stringToBytes32(_role)), "not in assigners group");
        LibACL._assignRole(_objectId, _contextId, LibHelpers._stringToBytes32(_role));
    }

    function unassignRole(bytes32 _objectId, bytes32 _contextId) external {
        bytes32 roleId = LibACL._getRoleInContext(_objectId, _contextId);
        bytes32 assignerId = LibHelpers._getIdForAddress(msg.sender);
        require(LibACL._canAssign(assignerId, _objectId, _contextId, roleId), "not in assigners group");
        LibACL._unassignRole(_objectId, _contextId);
    }

    function isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool) {
        return LibACL._isInGroup(_objectId, _contextId, LibHelpers._stringToBytes32(_group));
    }

    function isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool) {
        return LibACL._isParentInGroup(_objectId, _contextId, LibHelpers._stringToBytes32(_group));
    }

    function canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external view returns (bool) {
        return LibACL._canAssign(_assignerId, _objectId, _contextId, LibHelpers._stringToBytes32(_role));
    }

    function getRoleInContext(bytes32 objectId, bytes32 contextId) external view returns (bytes32) {
        return LibACL._getRoleInContext(objectId, contextId);
    }
}
