// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IACLFacet {
    function assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _roleId
    ) external;

    function unassignRole(bytes32 _objectId, bytes32 _contextId) external;

    function isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool);

    function isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool);

    function canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external view returns (bool);

    function getRoleInContext(bytes32 objectId, bytes32 contextId) external view returns (bytes32);
}
