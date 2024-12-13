// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @notice modifiers

import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibObject } from "../libs/LibObject.sol";

/**
 * @title Modifiers
 * @notice Function modifiers to control access
 * @dev Function modifiers to control access
 */
contract Modifiers {
    modifier notLocked() {
        require(!LibAdmin._isFunctionLocked(msg.sig), "function is locked");
        _;
    }

    modifier assertPrivilege(bytes32 _context, string memory _group) {
        LibACL._assertPriviledge(_context, _group);
        _;
    }

    modifier assertERC20Wrapper(bytes32 _tokenId) {
        (, , , , address erc20Wrapper) = LibObject._getObjectMeta(_tokenId);
        require(msg.sender == erc20Wrapper, "only wrapper calls allowed");
        _;
    }
}
