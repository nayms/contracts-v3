## Functions
### internalBalanceOf
Gets balance of an account within platform
Internal balance for given account
```solidity
  function internalBalanceOf(
    bytes32 tokenId
  ) external returns (uint256)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`tokenId` | bytes32 | Internal ID of the asset
#### Returns:
| Type | Description |
| --- | --- |
|`current` | balance
### balanceOfBatch
Gets balances of accounts within platform
Each account should have a corresponding token ID to query for balance
```solidity
  function balanceOfBatch(
    bytes32[] accountIds,
    bytes32[] tokenIds
  ) external returns (uint256[])
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`accountIds` | bytes32[] | Internal ID of the accounts
|`tokenIds` | bytes32[] | Internal ID of the assets
#### Returns:
| Type | Description |
| --- | --- |
|`current` | balance for each account
### internalTokenSupply
Current supply for the asset
Total supply of platform asset
```solidity
  function internalTokenSupply(
    bytes32 tokenId
  ) external returns (uint256)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`tokenId` | bytes32 | Internal ID of the asset
#### Returns:
| Type | Description |
| --- | --- |
|`current` | balance
### internalTransferFromEntity
Internal transfer of `amount` tokens
Transfer tokens internally
```solidity
  function internalTransferFromEntity(
    bytes32 to,
    bytes32 tokenId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`to` | bytes32 | token receiver
|`tokenId` | bytes32 | Internal ID of the token
### internalTransfer
Internal transfer of `amount` tokens
Transfer tokens internally
```solidity
  function internalTransfer(
    bytes32 to,
    bytes32 tokenId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`to` | bytes32 | token receiver
|`tokenId` | bytes32 | Internal ID of the token
### internalBurn
No description
```solidity
  function internalBurn(
  ) external
```
### getWithdrawableDividend
Get withdrawable dividend amount
Divident available for an entity to withdraw
```solidity
  function getWithdrawableDividend(
    bytes32 _entityId,
    bytes32 _tokenId,
    bytes32 _dividendTokenId
  ) external returns (uint256 _entityPayout)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | Unique ID of the entity
|`_tokenId` | bytes32 | Unique ID of token
|`_dividendTokenId` | bytes32 | Unique ID of dividend token
#### Returns:
| Type | Description |
| --- | --- |
|`_entityPayout` | accumulated dividend
### withdrawDividend
Withdraw available dividend
Transfer dividends to the entity
```solidity
  function withdrawDividend(
    bytes32 ownerId,
    bytes32 tokenId,
    bytes32 dividendTokenId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`ownerId` | bytes32 | Unique ID of the dividend receiver
|`tokenId` | bytes32 | Unique ID of token
|`dividendTokenId` | bytes32 | Unique ID of dividend token
### withdrawAllDividends
No description
```solidity
  function withdrawAllDividends(
  ) external
```
### payDividendFromEntity
Pay `amount` of dividends
Transfer dividends to the entity
```solidity
  function payDividendFromEntity(
    bytes32 guid,
    uint256 amount
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`guid` | bytes32 | Globally unique identifier of a dividend distribution.
|`amount` | uint256 | the mamount of the dividend token to be distributed to NAYMS token holders.
