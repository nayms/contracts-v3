// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SimplePolicy, Entity, Stakeholders } from "./FreeStructs.sol";

interface IEntityFacet {
    function updateAllowSimplePolicy(bytes32 _entityId, bool _allow) external;

    function createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata stakeholders,
        SimplePolicy calldata simplePolicy,
        bytes32 _dataHash
    ) external;

    function enableEntityTokenization(bytes32 _entityId, string memory _symbol) external;

    function startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) external;

    function updateEntity(bytes32 _entityId, Entity calldata _entity) external;

    function getEntityInfo(bytes32 _entityId) external view returns (Entity memory);
}
