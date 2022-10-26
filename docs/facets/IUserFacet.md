Manage user entity
## Functions
### getUserIdFromAddress
Get the platform ID of `addr` account
```solidity
  function getUserIdFromAddress(
    address addr
  ) external returns (bytes32 userId)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`addr` | address | Account address
#### Returns:
| Type | Description |
| --- | --- |
|`userId` | Unique platform ID
### getAddressFromExternalTokenId
Get the token address from ID of the external token
```solidity
  function getAddressFromExternalTokenId(
    bytes32 _externalTokenId
  ) external returns (address tokenAddress)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_externalTokenId` | bytes32 | The ID assigned to an external token
#### Returns:
| Type | Description |
| --- | --- |
|`tokenAddress` | Contract address
### setEntity
Set the entity for the user
```solidity
  function setEntity(
    bytes32 _userId,
    bytes32 _entityId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_userId` | bytes32 | Unique platform ID of the user account
|`_entityId` | bytes32 | Unique platform ID of the entity
### getEntity
Get the entity for the user
```solidity
  function getEntity(
    bytes32 _userId
  ) external returns (bytes32 entityId)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_userId` | bytes32 | Unique platform ID of the user account
#### Returns:
| Type | Description |
| --- | --- |
|`entityId` | Unique platform ID of the entity
### getBalanceOfTokensForSale
Get the amount of tokens that an entity has for sale in the marketplace.
```solidity
  function getBalanceOfTokensForSale(
    bytes32 _entityId,
    bytes32 _tokenId
  ) external returns (uint256 amount)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 |  Unique platform ID of the entity.
|`_tokenId` | bytes32 | The ID assigned to an external token.
#### Returns:
| Type | Description |
| --- | --- |
|`amount` | of tokens that the entity has for sale in the marketplace.
