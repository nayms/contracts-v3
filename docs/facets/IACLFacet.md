Use it to authorize various actions on the contracts
## Functions
### assignRole
Assign a `_roleId` to the object in given context
Any object ID can be a context, system is a special context with highest priority
```solidity
  function assignRole(
    bytes32 _objectId,
    bytes32 _contextId,
    string _role
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_objectId` | bytes32 | ID of an object that is being assigned a role
|`_contextId` | bytes32 | ID of the context in which a role is being assigned
|`_role` | string | Name of the role being assigned|
<br></br>
### unassignRole
Unassign object from a role in given context
Any object ID can be a context, system is a special context with highest priority
```solidity
  function unassignRole(
    bytes32 _objectId,
    bytes32 _contextId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_objectId` | bytes32 | ID of an object that is being unassigned from a role
|`_contextId` | bytes32 | ID of the context in which a role membership is being revoked|
<br></br>
### isInGroup
Checks if an object belongs to `_group` group in given context
Assigning a role to the object makes it a member of a corresponding role group
```solidity
  function isInGroup(
    bytes32 _objectId,
    bytes32 _contextId,
    string _group
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_objectId` | bytes32 | ID of an object that is being checked for role group membership
|`_contextId` | bytes32 | Context in which membership should be checked
|`_group` | string | name of the role group
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`true` | if object with given ID is a member, false otherwise|
<br></br>
### isParentInGroup
Check whether a parent object belongs to the `_group` group in given context
Objects can have a parent object, i.e. entity is a parent of a user
```solidity
  function isParentInGroup(
    bytes32 _objectId,
    bytes32 _contextId,
    string _group
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_objectId` | bytes32 | ID of an object whose parent is being checked for role group membership
|`_contextId` | bytes32 | Context in which the role group membership is being checked
|`_group` | string | name of the role group
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`true` | if object's parent is a member of this role group, false otherwise|
<br></br>
### canAssign
Check whether a user can assign specific object to the `_role` role in given context
Check permission to assign to a role
```solidity
  function canAssign(
    bytes32 _assignerId,
    bytes32 _objectId,
    bytes32 _contextId,
    string _role
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_assignerId` | bytes32 | The object ID of the user who is assigning a role to  another object.
|`_objectId` | bytes32 | ID of an object that is being checked for assigning rights
|`_contextId` | bytes32 | ID of the context in which permission is checked
|`_role` | string | name of the role to check
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`true` | if user the right to assign, false otherwise|
<br></br>
### hasGroupPrivilege
Check whether a user can call a specific function.
```solidity
  function hasGroupPrivilege(
    bytes32 _userId,
    bytes32 _contextId,
    bytes32 _groupId
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_userId` | bytes32 | The object ID of the user who is calling the function.
|`_contextId` | bytes32 | ID of the context in which permission is checked.
|`_groupId` | bytes32 | ID of the group in which permission is checked.|
<br></br>
### getRoleInContext
Get a user's (an objectId's) assigned role in a specific context
```solidity
  function getRoleInContext(
    bytes32 objectId,
    bytes32 contextId
  ) external returns (bytes32)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`objectId` | bytes32 | ID of an object that is being checked for its assigned role in a specific context
|`contextId` | bytes32 | ID of the context in which the objectId's role is being checked
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`roleId` | objectId's role in the contextId|
<br></br>
### isRoleInGroup
Get whether role is in group.
Get whether role is in group.
```solidity
  function isRoleInGroup(
    string role,
    string group
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`role` | string | the role.
|`group` | string | the group.
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`true` | if role is in group, false otherwise.|
<br></br>
### canGroupAssignRole
Get whether given group can assign given role.
Get whether given group can assign given role.
```solidity
  function canGroupAssignRole(
    string role,
    string group
  ) external returns (bool)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`role` | string | the role.
|`group` | string | the group.
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`true` | if role can be assigned by group, false otherwise.|
<br></br>
### updateRoleAssigner
Update who can assign `_role` role
Update who has permission to assign this role
```solidity
  function updateRoleAssigner(
    string _role,
    string _assignerGroup
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_role` | string | name of the role
|`_assignerGroup` | string | Group who can assign members to this role|
<br></br>
### updateRoleGroup
Update role group memebership for `_role` role and `_group` group
Update role group memebership
```solidity
  function updateRoleGroup(
    string _role,
    string _group,
    bool _roleInGroup
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_role` | string | name of the role
|`_group` | string | name of the group
|`_roleInGroup` | bool | is member of|
<br></br>
