// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface ITokenizedVaultFacet {
    function internalBalanceOf(bytes32 accountId, bytes32 tokenId) external view returns (uint256);

    /**
     * @notice Gets balances of accounts within platform
     * @dev Each account should have a corresponding token ID to query for balance
     * @param accountIds Internal ID of the accounts
     * @param tokenIds Internal ID of the assets
     * @return current balance for each account
     */
    function balanceOfBatch(bytes32[] calldata accountIds, bytes32[] calldata tokenIds) external view returns (uint256[] memory);

    function internalTokenSupply(bytes32 tokenId) external view returns (uint256);

    function internalTransferFromEntity(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external;

    function internalTransfer(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external;

    function getWithdrawableDividend(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 _entityPayout);

    function withdrawDividend(
        bytes32 ownerId,
        bytes32 tokenId,
        bytes32 dividendTokenId
    ) external;

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
