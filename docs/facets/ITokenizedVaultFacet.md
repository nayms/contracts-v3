Vault for keeping track of platform tokens
Used for internal platform token transfers
## Functions
### internalBalanceOf
```solidity
  function internalBalanceOf(
    bytes32 accountId,
    bytes32 tokenId
  ) external returns (uint256)
```
Gets balance of an account within platform
Internal balance for given account
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`accountId` | bytes32 | Internal ID of the account
|`tokenId` | bytes32 | Internal ID of the asset
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`current`| bytes32 | balance
### balanceOfBatch
```solidity
  function balanceOfBatch(
    bytes32[] accountIds,
    bytes32[] tokenIds
  ) external returns (uint256[])
```
Gets balances of accounts within platform
Each account should have a corresponding token ID to query for balance
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`accountIds` | bytes32[] | Internal ID of the accounts
|`tokenIds` | bytes32[] | Internal ID of the assets
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`current`| bytes32[] | balance for each account
### internalTokenSupply
```solidity
  function internalTokenSupply(
    bytes32 tokenId
  ) external returns (uint256)
```
Current supply for the asset
Total supply of platform asset
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`tokenId` | bytes32 | Internal ID of the asset
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`current`| bytes32 | balance
### internalTransferFromEntity
```solidity
  function internalTransferFromEntity(
    bytes32 to,
    bytes32 tokenId
  ) external
```
Internal transfer of `amount` tokens
Transfer tokens internally
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`to` | bytes32 | token receiver
|`tokenId` | bytes32 | Internal ID of the token
### internalTransfer
```solidity
  function internalTransfer(
    bytes32 to,
    bytes32 tokenId
  ) external
```
Internal transfer of `amount` tokens
Transfer tokens internally
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`to` | bytes32 | token receiver
|`tokenId` | bytes32 | Internal ID of the token
### getWithdrawableDividend
```solidity
  function getWithdrawableDividend(
    bytes32 _entityId,
    bytes32 _tokenId
  ) external returns (uint256 _entityPayout)
```
Get withdrawable dividend amount
Divident available for an entity to withdraw
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | Unique ID of the entity
|`_tokenId` | bytes32 | Unique ID of token
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`_entityPayout`| bytes32 | accumulated dividend
### withdrawDividend
```solidity
  function withdrawDividend(
    bytes32 ownerId,
    bytes32 tokenId,
    bytes32 dividendTokenId
  ) external
```
Withdraw available dividend
Transfer dividends to the entity
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`ownerId` | bytes32 | Unique ID of the dividend receiver
|`tokenId` | bytes32 | Unique ID of token
|`dividendTokenId` | bytes32 | Unique ID of dividend token
### payDividend
```solidity
  function payDividend(
  ) external
```
### payDividendFromEntity
```solidity
  function payDividendFromEntity(
  ) external
```
## Events
### EntityDeposit
```solidity
  event EntityDeposit(
    address caller,
    bytes32 receivingEntityId,
    bytes32 assetId,
    uint256 shares
  )
```
Entity funds deposit
Thrown when entity is funded
#### Parameters:
| Name                           | Type          | Description                                    |
| :----------------------------- | :------------ | :--------------------------------------------- |
|`caller`| address | address of the funder
|`receivingEntityId`| bytes32 | Unique ID of the entity receiving the funds
|`assetId`| bytes32 | Unique ID of the asset being deposited
|`shares`| uint256 | Amount deposited
### EntityWithdraw
```solidity
  event EntityWithdraw(
    address caller,
    address receiver,
    address assetId,
    uint256 shares
  )
```
Entity funds withdrawn
Thrown when entity funds are withdrawn
#### Parameters:
| Name                           | Type          | Description                                    |
| :----------------------------- | :------------ | :--------------------------------------------- |
|`caller`| address | address of the account initiating the transfer
|`receiver`| address | address of the account receiving the funds
|`assetId`| address | Unique ID of the asset being transferred
|`shares`| uint256 | Withdrawn amount
