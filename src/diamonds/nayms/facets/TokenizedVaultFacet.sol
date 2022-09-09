// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, Modifiers, LibConstants, LibHelpers, LibObject, MultiToken } from "../AppStorage.sol";

import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";

/**
 * @dev Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */

contract TokenizedVaultFacet is Modifiers {
    function internalBalanceOf(bytes32 ownerId, bytes32 tokenId) external view returns (uint256) {
        return LibTokenizedVault._internalBalanceOf(ownerId, tokenId);
    }

    function internalTokenSupply(bytes32 tokenId) external view returns (uint256) {
        return LibTokenizedVault._internalTokenSupply(tokenId);
    }

    // kp NOTE: currently, this method transfers from the user (userId) to an internal Id of choice
    // do we want an "internalTransferFrom" which allows a user to transfer from a specific Id?
    /// @notice this function allows an entity to transfer an internal token
    /// @param to the user receiving the internal token
    /// @dev only entity admins can transfer internal tokens
    /// @dev make sure staking tokens cannot be transferred
    function internalTransferFromEntity(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external assertEntityAdmin(LibObject._getParent(LibHelpers._getSenderId())) {
        // require(LibTokenizedVault._internalBalanceOf(senderId, tokenId) >= amount, "internalTransfer: insufficient balance");
        bytes32 senderId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 senderEntityId = LibObject._getParent(senderId);
        require(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER) != tokenId, "internalTransfer: can't transfer internal veNAYM");
        LibTokenizedVault._internalTransfer(senderEntityId, to, tokenId, amount);
    }

    function internalTransfer(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external assertEntityAdmin(LibObject._getParent(LibHelpers._getSenderId())) {
        // require(LibTokenizedVault._internalBalanceOf(senderId, tokenId) >= amount, "internalTransfer: insufficient balance");
        bytes32 senderId = LibHelpers._getIdForAddress(msg.sender);
        require(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER) != tokenId, "internalTransfer: can't transfer internal veNAYM");
        LibTokenizedVault._internalTransfer(senderId, to, tokenId, amount);
    }

    function getWithdrawableDividend(
        bytes32 ownerId,
        bytes32 tokenId,
        bytes32 dividendTokenId
    ) external view returns (uint256) {
        return LibTokenizedVault._getWithdrawableDividend(ownerId, tokenId, dividendTokenId);
    }

    function withdrawDividend(
        bytes32 ownerId,
        bytes32 tokenId,
        bytes32 dividendTokenId
    ) external {
        LibTokenizedVault._withdrawDividend(ownerId, tokenId, dividendTokenId);
    }

    function withdrawAllDividends(bytes32 ownerId, bytes32 tokenId) external {
        LibTokenizedVault._withdrawAllDividends(ownerId, tokenId);
    }

    function payDividend(
        bytes32 to,
        bytes32 dividendTokenId,
        uint256 amount
    ) external {
        bytes32 senderId = LibHelpers._getIdForAddress(msg.sender);
        require(LibTokenizedVault._internalBalanceOf(senderId, dividendTokenId) >= amount, "_payDividend: insufficient balance");

        LibTokenizedVault._payDividend(senderId, to, dividendTokenId, amount);
    }

    function payDividendFromEntity(
        bytes32 to,
        bytes32 dividendTokenId,
        uint256 amount
    ) external {
        bytes32 senderId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 senderEntityId = LibObject._getParent(senderId);
        require(LibTokenizedVault._internalBalanceOf(senderEntityId, dividendTokenId) >= amount, "_payDividend: insufficient balance");

        LibTokenizedVault._payDividend(senderEntityId, to, dividendTokenId, amount);
    }
}
