// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title Nayms token facet.
 * @dev Use it to access and manipulate Nayms token.
 */
interface INaymsTokenFacet {
    /**
     * @dev Get total supply of token.
     * @return total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Get token balance of given wallet.
     * @param addr wallet whose balance to get.
     * @return balance of wallet.
     */
    function balanceOf(address addr) external view returns (uint256);
}