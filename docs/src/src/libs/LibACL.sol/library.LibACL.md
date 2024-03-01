# LibACL
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/libs/LibACL.sol)


## Functions
### _assignRole


```solidity
function _assignRole(bytes32 _objectId, bytes32 _contextId, bytes32 _roleId) internal;
```

### _unassignRole


```solidity
function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal;
```

### _isInGroup

*_isInGroup no longer falls back to check the _objectId's role in the system context*


```solidity
function _isInGroup(bytes32 _objectId, bytes32 _contextId, bytes32 _groupId) internal view returns (bool ret);
```

### _isParentInGroup


```solidity
function _isParentInGroup(bytes32 _objectId, bytes32 _contextId, bytes32 _groupId) internal view returns (bool);
```

### _canAssign

Checks if assigner has the authority to assign object to a role in given context

*Any object ID can be a context, system is a special context with highest priority*


```solidity
function _canAssign(bytes32 _assignerId, bytes32 _objectId, bytes32 _contextId, bytes32 _roleId)
    internal
    view
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_assignerId`|`bytes32`|ID of an account wanting to assign a role to an object|
|`_objectId`|`bytes32`|ID of an object that is being assigned a role|
|`_contextId`|`bytes32`|ID of the context in which a role is being assigned|
|`_roleId`|`bytes32`|ID of a role being assigned|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if allowed false otherwise|


### _hasGroupPrivilege


```solidity
function _hasGroupPrivilege(bytes32 _userId, bytes32 _contextId, bytes32 _groupId) internal view returns (bool);
```

### _getRoleInContext


```solidity
function _getRoleInContext(bytes32 _objectId, bytes32 _contextId) internal view returns (bytes32);
```

### _isRoleInGroup


```solidity
function _isRoleInGroup(string memory role, string memory group) internal view returns (bool);
```

### _canGroupAssignRole


```solidity
function _canGroupAssignRole(string memory role, string memory group) internal view returns (bool);
```

### _updateRoleAssigner


```solidity
function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal;
```

### _updateRoleGroup


```solidity
function _updateRoleGroup(string memory _role, string memory _group, bool _roleInGroup) internal;
```

## Events
### RoleUpdated
*Emitted when a role gets updated. Empty roleId is assigned upon role removal*


```solidity
event RoleUpdated(bytes32 indexed objectId, bytes32 contextId, bytes32 assignedRoleId, string functionName);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`objectId`|`bytes32`|The user or object that was assigned the role.|
|`contextId`|`bytes32`|The context where the role was assigned to.|
|`assignedRoleId`|`bytes32`|The ID of the role which got (un)assigned. (empty ID when unassigned)|
|`functionName`|`string`|The function performing the action|

### RoleGroupUpdated
*Emitted when a role group gets updated.*


```solidity
event RoleGroupUpdated(string role, string group, bool roleInGroup);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`string`|The role name.|
|`group`|`string`|the group name.|
|`roleInGroup`|`bool`|whether the role is now in the group or not.|

### RoleCanAssignUpdated
*Emitted when a role assigners get updated.*


```solidity
event RoleCanAssignUpdated(string role, string group);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`string`|The role name.|
|`group`|`string`|the name of the group that can now assign this role.|

