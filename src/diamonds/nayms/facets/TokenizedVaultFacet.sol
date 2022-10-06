// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, Modifiers, LibConstants, LibHelpers, LibObject, MultiToken } from "../AppStorage.sol";

import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";

/**
 * @title Token Vault
 * @notice Vault for keeping track of platform tokens
 * @dev Used for internal platform token transfers
 * @dev Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
contract TokenizedVaultFacet is Modifiers {
    /**
     * @notice Gets balance of an account within platform
     * @dev Internal balance for given account
     * @param ownerId Internal ID of the account
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalBalanceOf(bytes32 ownerId, bytes32 tokenId) external view returns (uint256) {
        return LibTokenizedVault._internalBalanceOf(ownerId, tokenId);
    }

    /**
     * @notice Current supply for the asset
     * @dev Total supply of platform asset
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalTokenSupply(bytes32 tokenId) external view returns (uint256) {
        return LibTokenizedVault._internalTokenSupply(tokenId);
    }

    /**
     * @notice Internal transfer of `amount` tokens
     * @dev Transfer tokens internally
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
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

    /**
     * @notice Internal transfer of `amount` tokens
     * @dev Transfer tokens internally
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
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

    /**
     * @notice Get withdrawable dividend amount
     * @dev Divident available for an entity to withdraw
     * @param ownerId Unique ID of the entity
     * @param tokenId Unique ID of token
     * @param dividendTokenId Unique ID of dividend token
     * @return _entityPayout accumulated dividend
     */
    function getWithdrawableDividend(
        bytes32 ownerId,
        bytes32 tokenId,
        bytes32 dividendTokenId
    ) external view returns (uint256) {
        return LibTokenizedVault._getWithdrawableDividend(ownerId, tokenId, dividendTokenId);
    }

    /**
     * @notice Withdraw available dividend
     * @dev Transfer dividends to the entity
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     * @param dividendTokenId Unique ID of dividend token
     */
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

    /**
     * @notice Pay dividends
     * @dev Transfer dividends to the entity
     * @param guid Globally unique identifier of a dividend distribution.
     * @param to object ID of the dividend receiver.
     * @param dividendTokenId the internal token Id of the token to be paid as dividends.
     * @param amount the mamount of the dividend token to be distributed to NAYMS token holders.
     */
    function payDividendFromEntity(
        bytes32 guid,
        bytes32 to,
        bytes32 dividendTokenId,
        uint256 amount
    ) external {
        bytes32 senderId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 senderEntityId = LibObject._getParent(senderId);
        require(LibTokenizedVault._internalBalanceOf(senderEntityId, dividendTokenId) >= amount, "_payDividend: insufficient balance");

        LibTokenizedVault._payDividend(guid, senderEntityId, to, dividendTokenId, amount);
    }
}
