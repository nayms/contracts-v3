# ACLFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/facets/ACLFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md)

Use it to authorize various actions on the contracts

*Use it to (un)assign or check role membership*


## Functions
### assignRole

Assign a `_roleId` to the object in given context

*Any object ID can be a context, system is a special context with highest priority*


```solidity
function assignRole(bytes32 _objectId, bytes32 _contextId, string memory _role) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of an object that is being assigned a role|
|`_contextId`|`bytes32`|ID of the context in which a role is being assigned|
|`_role`|`string`|Name of the role being assigned|


### unassignRole

Unassign object from a role in given context

*First, assigner attempts to unassign the role.*

*Second, assign the role.*

*Any object ID can be a context, system is a special context with highest priority*


```solidity
function unassignRole(bytes32 _objectId, bytes32 _contextId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of an object that is being unassigned from a role|
|`_contextId`|`bytes32`|ID of the context in which a role membership is being revoked|


### isInGroup

Checks if an object belongs to `_group` group in given context

*Assigning a role to the object makes it a member of a corresponding role group*


```solidity
function isInGroup(bytes32 _objectId, bytes32 _contextId, string memory _group) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of an object that is being checked for role group membership|
|`_contextId`|`bytes32`|Context in which membership should be checked|
|`_group`|`string`|name of the role group|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if object with given ID is a member, false otherwise|


### isParentInGroup

Check whether a parent object belongs to the `_group` group in given context

*Objects can have a parent object, i.e. entity is a parent of a user*


```solidity
function isParentInGroup(bytes32 _objectId, bytes32 _contextId, string memory _group) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of an object whose parent is being checked for role group membership|
|`_contextId`|`bytes32`|Context in which the role group membership is being checked|
|`_group`|`string`|name of the role group|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if object's parent is a member of this role group, false otherwise|


### canAssign

Check whether a user can assign specific object to the `_role` role in given context

*Check permission to assign to a role*


```solidity
function canAssign(bytes32 _assignerId, bytes32 _objectId, bytes32 _contextId, string memory _role)
    external
    view
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_assignerId`|`bytes32`|The object ID of the user who is assigning a role to another object.|
|`_objectId`|`bytes32`|ID of an object that is being checked for assigning rights|
|`_contextId`|`bytes32`|ID of the context in which permission is checked|
|`_role`|`string`|name of the role to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if user has the right to assign, false otherwise|


### hasGroupPrivilege

Check whether a user can call a specific function.


```solidity
function hasGroupPrivilege(bytes32 _userId, bytes32 _contextId, bytes32 _groupId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_userId`|`bytes32`|The object ID of the user who is calling the function.|
|`_contextId`|`bytes32`|ID of the context in which permission is checked.|
|`_groupId`|`bytes32`|ID of the group in which permission is checked.|


### getRoleInContext

Get a user's (an objectId's) assigned role in a specific context


```solidity
function getRoleInContext(bytes32 objectId, bytes32 contextId) external view returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`objectId`|`bytes32`|ID of an object that is being checked for its assigned role in a specific context|
|`contextId`|`bytes32`|ID of the context in which the objectId's role is being checked|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|roleId objectId's role in the contextId|


### isRoleInGroup

Get whether role is in group.

*Get whether role is in group.*


```solidity
function isRoleInGroup(string memory role, string memory group) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`string`|the role.|
|`group`|`string`|the group.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if role is in group, false otherwise.|


### canGroupAssignRole

Get whether given group can assign given role.

*Get whether given group can assign given role.*


```solidity
function canGroupAssignRole(string memory role, string memory group) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`string`|the role.|
|`group`|`string`|the group.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if role can be assigned by group, false otherwise.|


### updateRoleAssigner

Update who can assign `_role` role

*Update who has permission to assign this role*


```solidity
function updateRoleAssigner(string memory _role, string memory _assignerGroup)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_role`|`string`|name of the role|
|`_assignerGroup`|`string`|Group who can assign members to this role|


### updateRoleGroup

Update role group membership for `_role` role and `_group` group

*Update role group membership*


```solidity
function updateRoleGroup(string memory _role, string memory _group, bool _roleInGroup)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_role`|`string`|name of the role|
|`_group`|`string`|name of the group|
|`_roleInGroup`|`bool`|is member of|


### strEquals

Compare two strings

*compares keccak256 hashes of ABI encoded strings*


```solidity
function strEquals(string memory s1, string memory s2) private pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`s1`|`string`|first string to compare|
|`s2`|`string`|second string to compare|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true is strings are equal|


