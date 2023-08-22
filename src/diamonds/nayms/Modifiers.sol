// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice modifiers

import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibConstants as LC } from "./libs/LibConstants.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibObject } from "./libs/LibObject.sol";
import { LibACL } from "./libs/LibACL.sol";

/**
 * @title Modifiers
 * @notice Function modifiers to control access
 * @dev Function modifiers to control access
 */
contract Modifiers {
    using LibHelpers for *;
    using LibACL for *;

    error NotSystemUnderwriter(address msgSender);

    /// @notice Error message for when a sender is not authorized to perform an action with their assigned role in a given context of a group
    /// @param msgSenderId Id of the sender
    /// @param context Context in which the sender is trying to perform an action
    /// @param roleInContext Role of the sender in the context
    /// @param group Tenant group ID (LibConstants.GROUP_TENANTS) displayed as type string
    error InvalidRole(bytes32 msgSenderId, bytes32 context, string roleInContext, string group);

    modifier notLocked(bytes4 functionSelector) {
        require(!LibAdmin._isFunctionLocked(functionSelector), "function is locked");
        _;
    }

    modifier assertSysAdmin() {
        require(msg.sender._getIdForAddress()._isInGroup(LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LC.GROUP_SYSTEM_ADMINS)), "not a system admin");
        _;
    }

    modifier assertSystemUW() {
        if (!msg.sender._getIdForAddress()._isInGroup(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_UNDERWRITERS._stringToBytes32())) revert NotSystemUnderwriter(msg.sender);
        _;
    }

    modifier assertSysMgr() {
        require(msg.sender._getIdForAddress()._isInGroup(LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LC.GROUP_SYSTEM_MANAGERS)), "not a system manager");
        _;
    }

    modifier assertPermissions(string memory _group, bytes32 _context) {
        if (!msg.sender._getIdForAddress()._isInGroup(_context, _group._stringToBytes32()))
            revert InvalidRole(msg.sender._getIdForAddress(), _context, abi.decode(msg.sender._getIdForAddress()._getRoleInContext(_context)._bytes32ToBytes(), (string)), _group);
        _;
    }

    modifier assertEntityAdmin(bytes32 _context) {
        require(msg.sender._getIdForAddress()._isInGroup(_context, LibHelpers._stringToBytes32(LC.GROUP_ENTITY_ADMINS)), "not the entity's admin");
        _;
    }

    // todo delete this - replaced this modifier with assertPolicyHandler with assertPermissions(LC.GROUP_POLICY_HANDLERS, _policyId)
    modifier assertPolicyHandler(bytes32 _context) {
        require(LibACL._isInGroup(LibObject._getParentFromAddress(msg.sender), _context, LibHelpers._stringToBytes32(LC.GROUP_POLICY_HANDLERS)), "not a policy handler");
        _;
    }

    modifier assertIsInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _group
    ) {
        require(LibACL._isInGroup(_objectId, _contextId, _group), "not in group");
        _;
    }

    modifier assertERC20Wrapper(bytes32 _tokenId) {
        (, , , , address erc20Wrapper) = LibObject._getObjectMeta(_tokenId);
        require(msg.sender == erc20Wrapper, "only wrapper calls allowed");
        _;
    }
}
