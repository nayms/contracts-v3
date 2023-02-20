// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Nayms token facet.
 * @dev Use it to access and manipulate Nayms token.
 */
interface INaymsTokenFacet {
    function decimals() external view returns (uint16);

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

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Get the internal token id of the Nayms token.
     * @return bytes32 nayms token id.
     */
    function getNaymsTokenId() external view returns (bytes32);
}
