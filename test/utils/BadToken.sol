// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "src/interfaces/IERC20.sol";

contract BadToken is IERC20 {
    uint256 public totalSupply = 0;
    mapping(address => mapping(address => uint256)) public allowance;

    function name() external pure returns (string memory) {
        revert("no name");
    }

    function symbol() external pure returns (string memory) {
        revert("no symbol");
    }

    function decimals() external pure returns (uint8) {
        revert("no decimals");
    }

    function balanceOf(address) external pure returns (uint256) {
        revert("not supported");
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert("not supported");
    }

    function approve(address, uint256) external pure returns (bool) {
        revert("not supported");
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert("not supported");
    }

    function mint(address, uint256) external pure {
        revert("not supported");
    }

    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external pure {
        revert("not supported");
    }
}
