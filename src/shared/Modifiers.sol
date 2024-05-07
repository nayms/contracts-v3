// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @notice modifiers

import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibACL } from "../libs/LibACL.sol";
import { InvalidGroupPrivilege } from "./CustomErrors.sol";
import { LibString } from "solady/utils/LibString.sol";

/**
 * @title Modifiers
 * @notice Function modifiers to control access
 * @dev Function modifiers to control access
 */
contract Modifiers {
    using LibHelpers for *;
    using LibACL for *;
    using LibString for *;

    modifier notLocked(bytes4 functionSelector) {
        require(!LibAdmin._isFunctionLocked(functionSelector), "function is locked");
        _;
    }

    modifier assertPrivilege(bytes32 _context, string memory _group) {
        if (!msg.sender._getIdForAddress()._hasGroupPrivilege(_context, _group._stringToBytes32()))
            /// Note: If the role returned by `_getRoleInContext` is empty (represented by bytes32(0)), we explicitly return an empty string.
            /// This ensures the user doesn't receive a string that could potentially include unwanted data (like pointer and length) without any meaningful content.
            revert InvalidGroupPrivilege(
                msg.sender._getIdForAddress(),
                _context,
                (msg.sender._getIdForAddress()._getRoleInContext(_context) == bytes32(0)) ? "" : msg.sender._getIdForAddress()._getRoleInContext(_context).fromSmallString(),
                _group
            );
        _;
    }

    modifier assertERC20Wrapper(bytes32 _tokenId) {
        (, , , , address erc20Wrapper) = LibObject._getObjectMeta(_tokenId);
        require(msg.sender == erc20Wrapper, "only wrapper calls allowed");
        _;
    }
}
