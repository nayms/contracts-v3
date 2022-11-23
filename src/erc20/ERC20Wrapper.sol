// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { IERC20 } from "./IERC20.sol";
import { INayms } from "../diamonds/nayms/INayms.sol";
import { LibHelpers } from "../diamonds/nayms/libs/LibHelpers.sol";
import { LibAdmin } from "../diamonds/nayms/libs/LibAdmin.sol";
import { LibConstants } from "../diamonds/nayms/libs/LibConstants.sol";

import { console2 } from "forge-std/console2.sol";

contract ERC20Wrapper is IERC20 {
    bytes32 internal tokenId;
    INayms internal nayms;
    mapping(address => mapping(address => uint256)) public allowances;

    constructor(bytes32 _tokenId, address _diamondAddress) {
        nayms = INayms(_diamondAddress);

        bytes32 senderId = LibHelpers._addressToBytes32(msg.sender);
        console2.log(" >> senderID");
        console2.logBytes32(senderId);
        console2.log(msg.sender);

        require(nayms.isInGroup(senderId, LibAdmin._getSystemId(), LibConstants.GROUP_SYSTEM_MANAGERS), "not a system manager");
        require(nayms.isObjectTokenizable(_tokenId), "must be tokenizable");

        tokenId = _tokenId;
    }

    function name() external view returns (string memory) {
        (, , , bytes32 nameBytes32, ) = nayms.getObjectMeta(tokenId);
        return LibHelpers._bytes32ToString(nameBytes32);
    }

    function symbol() external view returns (string memory) {
        (, , bytes32 symbolBytes32, , ) = nayms.getObjectMeta(tokenId);
        return LibHelpers._bytes32ToString(symbolBytes32);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return nayms.internalTokenSupply(tokenId);
    }

    function balanceOf(address who) external view returns (uint256) {
        return nayms.internalBalanceOf(LibHelpers._addressToBytes32(who), tokenId);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        bytes32 receiverId = LibHelpers._addressToBytes32(to);
        nayms.wrapperInternalTransfer(receiverId, tokenId, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowances[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (value == 0) {
            revert();
        }
        uint256 allowed = allowances[from][msg.sender]; // Saves gas for limited approvals.
        require(allowed >= value, "not enough allowance");

        if (allowed != type(uint256).max) allowances[from][msg.sender] = allowed - value;

        bytes32 fromId = LibHelpers._addressToBytes32(from);
        bytes32 toId = LibHelpers._addressToBytes32(to);
        nayms.wrapperInternalTransferFrom(fromId, toId, tokenId, value);

        emit Transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // TODO implement permit
    }
}
