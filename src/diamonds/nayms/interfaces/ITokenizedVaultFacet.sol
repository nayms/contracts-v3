// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/**
 * @title Token Vault
 * @notice Vault for keeping track of platform tokens
 * @dev Used for internal platform token transfers
 */
interface ITokenizedVaultFacet {
    /**
     * @notice Entity funds deposit
     * @dev Thrown when entity is funded
     * @param caller address of the funder
     * @param receivingEntityId Unique ID of the entity receiving the funds
     * @param assetId Unique ID of the asset being deposited
     * @param shares Amount deposited
     */
    event EntityDeposit(address indexed caller, bytes32 indexed receivingEntityId, bytes32 assetId, uint256 shares);

    /**
     * @notice Entity funds withdrawn
     * @dev Thrown when entity funds are withdrawn
     * @param caller address of the account initiating the transfer
     * @param receiver address of the account receiving the funds
     * @param assetId Unique ID of the asset being transferred
     * @param shares Withdrawn amount
     */
    event EntityWithdraw(address indexed caller, address indexed receiver, address assetId, uint256 shares);

    /**
     * @notice Gets balance of an account within platform
     * @dev Internal balance for given account
     * @param accountId Internal ID of the account
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalBalanceOf(bytes32 accountId, bytes32 tokenId) external view returns (uint256);

    /**
     * @notice Gets balances of accounts within platform
     * @dev Each account should have a corresponding token ID to query for balance
     * @param accountIds Internal ID of the accounts
     * @param tokenIds Internal ID of the assets
     * @return current balance for each account
     */
    function balanceOfBatch(bytes32[] calldata accountIds, bytes32[] calldata tokenIds) external view returns (uint256[] memory);

    /**
     * @notice Current supply for the asset
     * @dev Total supply of platform asset
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalTokenSupply(bytes32 tokenId) external view returns (uint256);

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
    ) external;

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
    ) external;

    /**
     * @notice Get withdrawable dividend amount
     * @dev Divident available for an entity to withdraw
     * @param _entityId Unique ID of the entity
     * @param _tokenId Unique ID of token
     * @return _entityPayout accumulated dividend
     */
    function getWithdrawableDividend(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 _entityPayout);

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
    ) external;

    // /**
    //  * @notice Pay dividends to todo staked NAYM token holders?
    //  * @dev Transfer dividends to the entity
    //  * @param entityId Unique ID of the dividend receiver
    //  * @param dividendTokenId
    //  * @param amount
    //  */

    function payDividend(
        bytes32 to,
        bytes32 dividendTokenId,
        uint256 amount
    ) external;

    function payDividendFromEntity(
        bytes32 to,
        bytes32 dividendTokenId,
        uint256 amount
    ) external;
}
