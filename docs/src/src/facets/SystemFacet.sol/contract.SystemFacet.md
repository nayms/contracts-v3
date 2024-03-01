# SystemFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/facets/SystemFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md), [ReentrancyGuard](/src/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)

Use it to perform system level operations

*Use it to perform system level operations*


## Functions
### createEntity

Create an entity

*An entity can be created with a zero max capacity! This is in the event where an entity cannot write any policies.*


```solidity
function createEntity(bytes32 _entityId, bytes32 _entityAdmin, Entity calldata _entityData, bytes32 _dataHash)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|Unique ID for the entity|
|`_entityAdmin`|`bytes32`|Unique ID of the entity administrator|
|`_entityData`|`Entity`|remaining entity metadata|
|`_dataHash`|`bytes32`|hash of the offchain data|


### stringToBytes32

Convert a string type to a bytes32 type


```solidity
function stringToBytes32(string memory _strIn) external pure returns (bytes32 result);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_strIn`|`string`|a string|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`result`|`bytes32`|Bytes32 representation of input string|


### isObject

*Get whether given id is an object in the system.*


```solidity
function isObject(bytes32 _id) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_id`|`bytes32`|object id.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if it is an object, false otherwise|


### getObjectMeta

*Get meta of given object.*


```solidity
function getObjectMeta(bytes32 _id)
    external
    view
    returns (bytes32 parent, bytes32 dataHash, string memory tokenSymbol, string memory tokenName, address tokenWrapper);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_id`|`bytes32`|object id.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`parent`|`bytes32`|object parent|
|`dataHash`|`bytes32`|object data hash|
|`tokenSymbol`|`string`|object token symbol|
|`tokenName`|`string`|object token name|
|`tokenWrapper`|`address`|object token ERC20 wrapper address|


### wrapToken

Wrap an object token as ERC20


```solidity
function wrapToken(bytes32 _objectId)
    external
    nonReentrant
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of the tokenized object|


### getObjectType

Returns the object's type

*An object's type is the most significant 12 bytes of its bytes32 ID*


```solidity
function getObjectType(bytes32 _objectId) external pure returns (bytes12);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of the object|


### isObjectType

Check to see if an object is of a given type


```solidity
function isObjectType(bytes32 _objectId, bytes12 _objectType) external pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of the object|
|`_objectType`|`bytes12`|The object type to check against|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the object is of the given type, false otherwise|


