Manage user entity
Use manage user entity
## Functions
### getUserIdFromAddress
```solidity
  function getUserIdFromAddress(
    address addr
  ) external returns (bytes32 userId)
```
Get the platform ID of `addr` account
Convert address to platform ID
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`addr` | address | Account address
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`userId`| address | Unique platform ID
### getAddressFromExternalTokenId
```solidity
  function getAddressFromExternalTokenId(
    bytes32 _externalTokenId
  ) external returns (address tokenAddress)
```
Get the token address from ID of the external token
Convert the bytes32 external token ID to its respective ERC20 contract address
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_externalTokenId` | bytes32 | The ID assigned to an external token
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`tokenAddress`| bytes32 | Contract address
### setEntity
```solidity
  function setEntity(
    bytes32 _userId,
    bytes32 _entityId
  ) external
```
Set the entity for the user
Assign the user an entity
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_userId` | bytes32 | Unique platform ID of the user account
|`_entityId` | bytes32 | Unique platform ID of the entity
### getEntity
```solidity
  function getEntity(
    bytes32 _userId
  ) external returns (bytes32 entityId)
```
Get the entity for the user
Gets the entity related to the user
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_userId` | bytes32 | Unique platform ID of the user account
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`entityId`| bytes32 | Unique platform ID of the entity
### getBalanceOfTokensForSale
```solidity
  function getBalanceOfTokensForSale(
  ) external returns (uint256 amount)
```
