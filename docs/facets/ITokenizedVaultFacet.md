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
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`current` | balance|
<br></br>
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
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`current` | balance|
<br></br>
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
|`tokenId` | bytes32 | Internal ID of the token|
<br></br>
### wrapperInternalTransferFrom
Internal transfer of `amount` tokens `from` -> `to`
Transfer tokens internally between two IDs
```solidity
  function wrapperInternalTransferFrom(
    bytes32 from,
    bytes32 to,
    bytes32 tokenId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`from` | bytes32 | token sender
|`to` | bytes32 | token receiver
|`tokenId` | bytes32 | Internal ID of the token|
<br></br>
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
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`_entityPayout` | accumulated dividend|
<br></br>
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
|`dividendTokenId` | bytes32 | Unique ID of dividend token|
<br></br>
### withdrawAllDividends
Withdraws a user's available dividends.
Dividends can be available in more than one dividend denomination. This method will withdraw all available dividends in the different dividend denominations.
```solidity
  function withdrawAllDividends(
    bytes32 ownerId,
    bytes32 tokenId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`ownerId` | bytes32 | Unique ID of the dividend receiver
|`tokenId` | bytes32 | Unique ID of token|
<br></br>
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
|`amount` | uint256 | the mamount of the dividend token to be distributed to NAYMS token holders.|
<br></br>
### getLockedBalance
Get the amount of tokens that an entity has for sale in the marketplace.
```solidity
  function getLockedBalance(
    bytes32 _entityId,
    bytes32 _tokenId
  ) external returns (uint256 amount)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 |  Unique platform ID of the entity.
|`_tokenId` | bytes32 | The ID assigned to an external token.
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`amount` | of tokens that the entity has for sale in the marketplace.|
<br></br>
### internalTransferBySystemAdmin
No description
```solidity
  function internalTransferBySystemAdmin(
  ) external
```
