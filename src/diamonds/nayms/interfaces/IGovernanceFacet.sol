// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IGovernanceFacet {
    function schedule(
        // address target,
        // uint256 value,
        // bytes calldata data,
        // bytes32 predecessor,
        // bytes32 salt,
        bytes32 id,
        uint256 delay
    ) external;

    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        // bytes32 id,
        uint256 delay
    ) external;

    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external pure returns (bytes32 hash);

    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) external pure returns (bytes32 hash);

    function isOperation(bytes32 id) external view returns (bool registered);

    function getTimestamp(bytes32 id) external view returns (uint256 timestamp);

    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) external;

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) external;
}
