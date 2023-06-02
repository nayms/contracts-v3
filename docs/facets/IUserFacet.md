Utility functions for managing a user's entity.
## Functions
### getUserIdFromAddress
Get the platform ID of `addr` account
Convert address to platform ID
```solidity
  function getUserIdFromAddress(
    address addr
  ) external returns (bytes32 userId)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`addr` | address | Account address
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`userId` | Unique platform ID|
<br></br>
### getAddressFromExternalTokenId
Get the token address from ID of the external token
Convert the bytes32 external token ID to its respective ERC20 contract address
```solidity
  function getAddressFromExternalTokenId(
    bytes32 _externalTokenId
  ) external returns (address tokenAddress)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_externalTokenId` | bytes32 | The ID assigned to an external token
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`tokenAddress` | Contract address|
<br></br>
### setEntity
Set the entity for the user
Assign the user an entity. The entity must exist in order to associate it with a user.
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
|`_entityId` | bytes32 | Unique platform ID of the entity|
<br></br>
### getEntity
Get the entity for the user
Gets the entity related to the user
```solidity
  function getEntity(
    bytes32 _userId
  ) external returns (bytes32 entityId)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_userId` | bytes32 | Unique platform ID of the user account
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`entityId` | Unique platform ID of the entity|
<br></br>
