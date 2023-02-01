// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "../libs/LibACL.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibDiamond } from "../../shared/libs/LibDiamond.sol";
import { Modifiers } from "../Modifiers.sol";
import { LibGovernance } from "../libs/LibGovernance.sol";
import { IGovernanceFacet } from "../interfaces/IGovernanceFacet.sol";

contract GovernanceFacet is Modifiers {
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    function schedule(
        // address target,
        // uint256 value,
        // bytes calldata data,
        // bytes32 predecessor,
        // bytes32 salt,
        bytes32 id,
        uint256 delay
    ) external assertSysAdmin {
        // bytes32 id = hashOperation(target, value, data, predecessor, salt);
        LibGovernance._schedule(id, delay);
        // emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        // bytes32 id,
        uint256 delay
    ) external assertSysAdmin {
        bytes32 id = LibGovernance.hashOperationBatch(targets, values, payloads, predecessor, salt);
        LibGovernance._schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit LibGovernance.CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
    }

    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) external pure returns (bytes32 hash) {
        return LibGovernance.hashOperation(target, value, data, predecessor, salt);
    }

    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) external pure returns (bytes32 hash) {
        return LibGovernance.hashOperationBatch(targets, values, payloads, predecessor, salt);
    }

    function isOperation(bytes32 id) external view returns (bool registered) {
        return LibGovernance.isOperation(id);
    }

    /**
     * @dev Returns the timestamp at which an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */

    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) external assertSysAdmin {
        bytes32 id = LibGovernance.hashOperation(target, value, payload, predecessor, salt);

        LibGovernance._beforeCall(id, predecessor);
        LibGovernance._execute(target, value, payload);
        emit LibGovernance.CallExecuted(id, 0, target, value, payload);
        LibGovernance._afterCall(id);
    }

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) external assertSysAdmin {
        bytes32 id = LibGovernance.hashOperationBatch(targets, values, payloads, predecessor, salt);

        LibGovernance._beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            address target = targets[i];
            uint256 value = values[i];
            bytes calldata payload = payloads[i];
            LibGovernance._execute(target, value, payload);
            emit LibGovernance.CallExecuted(id, i, target, value, payload);
        }
        LibGovernance._afterCall(id);
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) external view virtual returns (bool ready) {
        LibGovernance.isOperationReady(id);
    }

    function getTimestamp(bytes32 id) external view virtual returns (uint256 timestamp) {
        LibGovernance.getTimestamp(id);
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) external view virtual returns (bool done) {
        LibGovernance.isOperationDone(id);
    }

    // todo who can cancel?
    function cancel(bytes32 id) external assertSysAdmin {
        LibGovernance.cancel(id);
    }
}
