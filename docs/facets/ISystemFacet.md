Use it to perform system level operations
Use it to perform system level operations
## Functions
### whitelistExternalToken
```solidity
  function whitelistExternalToken(
    address _underlyingToken
  ) external
```
Deprocated. Function in admin facet replaces this
Whitelist `_underlyingToken` as underlying asset for the entity
Whitelist an underlying asset
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_underlyingToken` | address | underlying asset address
### createEntity
```solidity
  function createEntity(
    bytes32 _entityId,
    bytes32 _entityAdmin,
    struct Entity _entityData,
    bytes32 _dataHash
  ) external
```
Create an entity
An entity can be created with a zero max capacity! This is in the event where an entity cannot write any policies.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | Unique ID for the entity
|`_entityAdmin` | bytes32 | Unique ID of the entity administrator
|`_entityData` | struct Entity | remaining entity metadata
|`_dataHash` | bytes32 | hash of the offchain data
### approveUser
```solidity
  function approveUser(
    bytes32 _userId,
    bytes32 _entityId
  ) external
```
Approve user on entity
Assign user the approved user role in context of entity
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_userId` | bytes32 | Unique ID of the user
|`_entityId` | bytes32 | Unique ID for the entity
### stringToBytes32
```solidity
  function stringToBytes32(
    string _strIn
  ) external returns (bytes32 result)
```
Convert a string type to a bytes32 type
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_strIn` | string | a string
## Events
### NewEntity
```solidity
  event NewEntity(
    bytes32 entityId,
    bytes32 entityAdminId
  )
```
New entity has been created
Thrown when entity is created
#### Parameters:
| Name                           | Type          | Description                                    |
| :----------------------------- | :------------ | :--------------------------------------------- |
|`entityId`| bytes32 | Unique ID for the entity
|`entityAdminId`| bytes32 | Unique ID of the entity administrator
