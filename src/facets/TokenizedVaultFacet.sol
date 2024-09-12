// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Modifiers } from "../shared/Modifiers.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibEntity } from "../libs/LibEntity.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";

/**
 * @title Token Vault
 * @notice Vault for keeping track of platform tokens
 * @dev Used for internal platform token transfers
 * @dev Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
contract TokenizedVaultFacet is Modifiers, ReentrancyGuard {
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
     * @return total supply
     */
    function internalTokenSupply(bytes32 tokenId) external view returns (uint256) {
        return LibTokenizedVault._internalTokenSupply(tokenId);
    }

    /**
     * @notice Internal transfer of `amount` tokens from the entity associated with the sender
     * @dev Transfer tokens internally
     * @param to token receiver
     * @param tokenId Internal ID of the token
     * @param amount being transferred
     */
    function internalTransferFromEntity(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external notLocked nonReentrant assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_INTERNAL_TRANSFER_FROM_ENTITY) {
        bytes32 senderEntityId = LibObject._getParentFromAddress(msg.sender);
        LibTokenizedVault._internalTransfer(senderEntityId, to, tokenId, amount);
    }

    /**
     * @notice Internal transfer of `amount` tokens `from` -> `to`
     * @dev Transfer tokens internally between two IDs
     * @param from token sender
     * @param to token receiver
     * @param tokenId Internal ID of the token
     * @param amount being transferred
     */
    function wrapperInternalTransferFrom(bytes32 from, bytes32 to, bytes32 tokenId, uint256 amount) external notLocked nonReentrant assertERC20Wrapper(tokenId) {
        LibTokenizedVault._internalTransfer(from, to, tokenId, amount);
    }

    /**
     *
     * @param from @notice Internal burn of `amount` of `tokenId` tokens of `from` userId
     * @param tokenId tokenID to be burned internally
     * @param amount to be burned
     */
    function internalBurn(bytes32 from, bytes32 tokenId, uint256 amount) external notLocked assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibTokenizedVault._internalBurn(from, tokenId, amount);
    }

    /**
     * @notice Get withdrawable dividend amount
     * @dev Dividend available for an entity to withdraw
     * @param ownerId Unique ID of the entity
     * @param tokenId Unique ID of token
     * @param dividendTokenId Unique ID of dividend token
     * @return _entityPayout accumulated dividend
     */
    function getWithdrawableDividend(bytes32 ownerId, bytes32 tokenId, bytes32 dividendTokenId) external view returns (uint256) {
        return LibTokenizedVault._getWithdrawableDividend(ownerId, tokenId, dividendTokenId);
    }

    /**
     * @notice Withdraw available dividend
     * @dev Transfer dividends to the entity
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     * @param dividendTokenId Unique ID of dividend token
     */
    function withdrawDividend(bytes32 ownerId, bytes32 tokenId, bytes32 dividendTokenId) external notLocked {
        LibTokenizedVault._withdrawDividend(ownerId, tokenId, dividendTokenId);
    }

    /**
     * @notice Withdraws a user's available dividends.
     * @dev Dividends can be available in more than one dividend denomination. This method will withdraw all available dividends in the different dividend denominations.
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     */
    function withdrawAllDividends(bytes32 ownerId, bytes32 tokenId) external notLocked {
        LibTokenizedVault._withdrawAllDividends(ownerId, tokenId);
    }

    /**
     * @notice Pay `amount` of dividends
     * @dev Transfer dividends to the entity
     * @param guid Globally unique identifier of a dividend distribution.
     * @param amount the amount of the dividend token to be distributed to NAYMS token holders.
     */
    function payDividendFromEntity(
        bytes32 guid,
        uint256 amount
    ) external notLocked assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_PAY_DIVIDEND_FROM_ENTITY) {
        bytes32 entityId = LibObject._getParentFromAddress(msg.sender);
        bytes32 dividendTokenId = LibEntity._getEntityInfo(entityId).assetId;

        require(LibTokenizedVault._internalBalanceOf(entityId, dividendTokenId) >= amount, "payDividendFromEntity: insufficient balance");

        // note: The from and to are both entityId. In the case where a dividend is paid to an entity that was not tokenized to have participation tokens, the dividend payment
        // will go to the user's entity.
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

    /**
     * @notice A system admin can transfer funds from an ID to another one.
     *
     * @param _fromId Unique platform ID to send the funds from.
     * @param _toId The ID to transfer funds to.
     * @param _tokenId The ID assigned to an external token.
     * @param _amount The amount of internal tokens to transfer.
     */
    function internalTransferBySystemAdmin(
        bytes32 _fromId,
        bytes32 _toId,
        bytes32 _tokenId,
        uint256 _amount
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) {
        LibTokenizedVault._internalTransfer(_fromId, _toId, _tokenId, _amount);
    }

    /**
     * @notice Get the total amount of dividends paid to a cell.
     * @param _tokenId The entity ID of the cell. In otherwords, the participation token ID.
     * @param _dividendDenominationId The ID of the dividend token that the dividends were paid in.
     */
    function totalDividends(bytes32 _tokenId, bytes32 _dividendDenominationId) external view returns (uint256) {
        return LibTokenizedVault._totalDividends(_tokenId, _dividendDenominationId);
    }

    function accruedInterest(bytes32 _tokenId) external view returns (uint256) {
        return LibTokenizedVault._accruedInterest(_tokenId);
    }

    function distributeAccruedInterest(bytes32 _tokenId, uint256 _amount, bytes32 _guid) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS) {
        // The _claimRebasingInterest method verifies the token is valid, and that there is available interest.
        // No need to do it again.
        LibTokenizedVault._claimRebasingInterest(_tokenId, _amount);
        LibTokenizedVault._payDividend(_guid, _tokenId, _tokenId, _tokenId, _amount);
    }
}
