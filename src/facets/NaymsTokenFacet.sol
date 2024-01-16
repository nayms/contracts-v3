// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibNaymsToken } from "../libs/LibNaymsToken.sol";
import { TransferHelper } from "src/utils/TransferHelper.sol";

import { IERC20 } from "@openzeppelin5/contracts/token/ERC20/IERC20.sol";

/**
 * @title Nayms token facet.
 * @notice Use it to access and manipulate Nayms token.
 * @dev Use it to access and manipulate Nayms token.
 */
contract NaymsTokenFacet is IERC20 {
    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view returns (uint256) {
        return LibNaymsToken._totalSupply();
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address addr) external view returns (uint256) {
        return LibNaymsToken._balanceOf(addr);
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(address to, uint256 value) external returns (bool) {
        TransferHelper.safeTransfer(address(this), to, value);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        TransferHelper.safeTransferFrom(address(this), from, to, value);
        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return LibNaymsToken._allowance(owner, spender);
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 value) external returns (bool) {
        uint256 current = LibNaymsToken._allowance(msg.sender, spender);
        if (value > current) {
            LibNaymsToken._increaseAllowance(spender, value - current);
        } else {
            LibNaymsToken._increaseAllowance(spender, current - value);
        }
        return true;
    }
}
