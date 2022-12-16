// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { Modifiers } from "../Modifiers.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibEntity } from "../libs/LibEntity.sol";
import { ITokenizedVaultFacet } from "../interfaces/ITokenizedVaultFacet.sol";

/**
 * @title Token Vault
 * @notice Vault for keeping track of platform tokens
 * @dev Used for internal platform token transfers
 * @dev Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
contract TokenizedVaultFacet is ITokenizedVaultFacet, Modifiers {
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
     * @notice Internal transfer of `amount` tokens from the entity associated with the sender
     * @dev Transfer tokens internally
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
    function internalTransfer(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external assertEntityAdmin(LibObject._getParent(LibHelpers._getSenderId())) {
        bytes32 senderEntityId = LibObject._getParentFromAddress(msg.sender);
        LibTokenizedVault._internalTransfer(senderEntityId, to, tokenId, amount);
    }

    function internalBurn(
        bytes32 from,
        bytes32 tokenId,
        uint256 amount
    ) external assertSysAdmin {
        LibTokenizedVault._internalBurn(from, tokenId, amount);
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
     * @notice Pay `amount` of dividends
     * @dev Transfer dividends to the entity
     * @param guid Globally unique identifier of a dividend distribution.
     * @param amount the mamount of the dividend token to be distributed to NAYMS token holders.
     */
    function payDividendFromEntity(bytes32 guid, uint256 amount) external {
        bytes32 entityId = LibObject._getParentFromAddress(msg.sender);
        bytes32 dividendTokenId = LibEntity._getEntityInfo(entityId).assetId;

        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(msg.sender), entityId, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)),
            "payDividendFromEntity: not the entity's admin"
        );
        require(LibTokenizedVault._internalBalanceOf(entityId, dividendTokenId) >= amount, "payDividendFromEntity: insufficient balance");

        LibTokenizedVault._payDividend(guid, entityId, entityId, dividendTokenId, amount);
    }

    /**
     * @notice Get the amount of tokens that an entity has for sale in the marketplace.
     * @param _entityId  Unique platform ID of the entity.
     * @param _tokenId The ID assigned to an external token.
     * @return amount of tokens that the entity has for sale in the marketplace.
     */
    function getLockedBalance(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 amount) {
        amount = LibTokenizedVault._getLockedBalance(_entityId, _tokenId);
    }
}
