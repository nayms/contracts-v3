// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice modifiers

import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibConstants as LC } from "./libs/LibConstants.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibObject } from "./libs/LibObject.sol";
import { LibACL } from "./libs/LibACL.sol";
import { NotSystemUnderwriter, InvalidGroupPrivilege } from "./interfaces/CustomErrors.sol";

/**
 * @title Modifiers
 * @notice Function modifiers to control access
 * @dev Function modifiers to control access
 */
contract Modifiers {
    using LibHelpers for *;
    using LibACL for *;

    modifier notLocked(bytes4 functionSelector) {
        require(!LibAdmin._isFunctionLocked(functionSelector), "function is locked");
        _;
    }

    modifier assertSysAdmin() {
        require(msg.sender._getIdForAddress()._isInGroup(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS._stringToBytes32()), "not a system admin");
        _;
    }

    modifier assertSystemUW() {
        if (!msg.sender._getIdForAddress()._isInGroup(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_UNDERWRITERS._stringToBytes32())) revert NotSystemUnderwriter(msg.sender);
        _;
    }

    modifier assertSysMgr() {
        require(msg.sender._getIdForAddress()._isInGroup(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS._stringToBytes32()), "not a system manager");
        _;
    }

    modifier assertHasGroupPrivilege(bytes32 _context, string memory _group) {
        if (!msg.sender._getIdForAddress()._hasGroupPrivilege(_context, _group._stringToBytes32()))
            /// Note: If the role returned by `_getRoleInContext` is empty (represented by bytes32(0)), we explicitly return an empty string.
            /// This ensures the user doesn't receive a string that could potentially include unwanted data (like pointer and length) without any meaningful content.
            revert InvalidGroupPrivilege(
                msg.sender._getIdForAddress(),
                _context,
                (msg.sender._getIdForAddress()._getRoleInContext(_context) == bytes32(0))
                    ? ""
                    : string(msg.sender._getIdForAddress()._getRoleInContext(_context)._bytes32ToBytes()),
                _group
            );
        _;
    }

    modifier assertEntityAdmin(bytes32 _context) {
        require(msg.sender._getIdForAddress()._isInGroup(_context, LibHelpers._stringToBytes32(LC.GROUP_ENTITY_ADMINS)), "not the entity's admin");
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
