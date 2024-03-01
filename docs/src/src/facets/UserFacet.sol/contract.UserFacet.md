# UserFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/facets/UserFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md)

Utility functions for managing a user's entity.

*This contract includes functions to set and get user-entity relationships,
and to convert wallet addresses to platform IDs and vice versa.*


## Functions
### getUserIdFromAddress

Get the platform ID of `addr` account

*Convert address to platform ID*


```solidity
function getUserIdFromAddress(address addr) external pure returns (bytes32 userId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`addr`|`address`|Account address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`userId`|`bytes32`|Unique platform ID|


### getAddressFromExternalTokenId

Get the token address from ID of the external token

*Convert the bytes32 external token ID to its respective ERC20 contract address*


```solidity
function getAddressFromExternalTokenId(bytes32 _externalTokenId) external pure returns (address tokenAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_externalTokenId`|`bytes32`|The ID assigned to an external token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|Contract address|


### setEntity

Set the entity for the user

*Assign the user an entity. The entity must exist in order to associate it with a user.*


```solidity
function setEntity(bytes32 _userId, bytes32 _entityId)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_userId`|`bytes32`|Unique platform ID of the user account|
|`_entityId`|`bytes32`|Unique platform ID of the entity|


### getEntity

Get the entity for the user

*Gets the entity related to the user*


```solidity
function getEntity(bytes32 _userId) external view returns (bytes32 entityId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_userId`|`bytes32`|Unique platform ID of the user account|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`entityId`|`bytes32`|Unique platform ID of the entity|


