Use it to perform system level operations
## Functions
### createEntity
Create an entity
An entity can be created with a zero max capacity! This is in the event where an entity cannot write any policies.
```solidity
  function createEntity(
    bytes32 _entityId,
    bytes32 _entityAdmin,
    struct Entity _entityData,
    bytes32 _dataHash
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | Unique ID for the entity
|`_entityAdmin` | bytes32 | Unique ID of the entity administrator
|`_entityData` | struct Entity | remaining entity metadata
|`_dataHash` | bytes32 | hash of the offchain data|
<br></br>
### stringToBytes32
Convert a string type to a bytes32 type
```solidity
  function stringToBytes32(
    string _strIn
  ) external returns (bytes32 result)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_strIn` | string | a string|
<br></br>
### isObject
No description
Get whether given id is an object in the system.
```solidity
  function isObject(
    bytes32 _id
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_id` | bytes32 | object id.
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`true` | if it is an object, false otherwise|
<br></br>
### getObjectMeta
No description
Get meta of given object.
```solidity
  function getObjectMeta(
    bytes32 _id
  ) external returns (bytes32 parent, bytes32 dataHash, string tokenSymbol, string tokenName, address tokenWrapper)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_id` | bytes32 | object id.
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`parent` | object parent
|`dataHash` | object data hash
|`tokenSymbol` | object token symbol
|`tokenName` | object token name
|`tokenWrapper` | object token ERC20 wrapper address|
<br></br>
### wrapToken
Wrap an object token as ERC20
```solidity
  function wrapToken(
    bytes32 _objectId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_objectId` | bytes32 | ID of the tokenized object|
<br></br>
