Use it to perform system level operations
Use it to perform system level operations
## Functions
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
### isObject
```solidity
  function isObject(
    bytes32 _id
  ) external returns (bool)
```
Get whether given id is an object in the system.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_id` | bytes32 | object id.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`true`| bytes32 | if it is an object, false otherwise
### getObjectMeta
```solidity
  function getObjectMeta(
    bytes32 _id
  ) external returns (bytes32 parent, bytes32 dataHash, bytes32 tokenSymbol)
```
Get meta of given object.
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_id` | bytes32 | object id.
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`parent`| bytes32 | object parent
|`dataHash`|  | object data hash
|`tokenSymbol`|  | object token symbol
