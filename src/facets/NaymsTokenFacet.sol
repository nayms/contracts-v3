// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibNaymsToken } from "../libs/LibNaymsToken.sol";
import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
/**
 * @title Nayms token facet.
 * @notice Use it to access and manipulate Nayms token.
 * @dev Use it to access and manipulate Nayms token.
 */
contract NaymsTokenFacet {
    /**
     * @dev Get total supply of token.
     * @return total supply.
     */
    function totalSupply() external view returns (uint256) {
        return LibNaymsToken._totalSupply();
    }

    /**
     * @dev Get token balance of given wallet.
     * @param addr wallet whose balance to get.
     * @return balance of wallet.
     */
    function balanceOf(address addr) external view returns (uint256) {
        return LibNaymsToken._balanceOf(addr);
    }

    function symbol() external pure returns (string memory) {
        return "NAYMS";
    }
    function decimals() external pure returns (uint8) {
        return 18;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.allowance[msg.sender][spender] = amount;

        // emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.balances[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            s.balances[to] += amount;
        }

        // emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 allowed = s.allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) s.allowance[from][msg.sender] = allowed - amount;

        s.balances[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            s.balances[to] += amount;
        }

        // emit Transfer(from, to, amount);

        return true;
    }
}
