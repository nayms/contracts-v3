// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { Entity } from "./FreeStructs.sol";

interface ISystemFacet {
    function createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entityData,
        bytes32 _dataHash
    ) external;

    function approveUser(bytes32 _userId, bytes32 _entityId) external;

    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result);
}
