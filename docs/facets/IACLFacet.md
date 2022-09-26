Use it to authorise various actions on the contracts
Use it to (un)assign or check role membership
## Functions
### assignRole
```solidity
  function assignRole(
    bytes32 _objectId,
    bytes32 _contextId,
    string _roleId
  ) external
```
Assign a `_roleId` to the object in given context
Any object ID can be a context, system is a special context with highest priority
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_objectId` | bytes32 | ID of an object that is being assigned a role
|`_contextId` | bytes32 | ID of the context in which a role is being assigned
|`_roleId` | string | ID of a role bein assigned
### unassignRole
```solidity
  function unassignRole(
    bytes32 _objectId,
    bytes32 _contextId
  ) external
```
Unassign object from a role in given context
Any object ID can be a context, system is a special context with highest priority
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_objectId` | bytes32 | ID of an object that is being unassigned from a role
|`_contextId` | bytes32 | ID of the context in which a role membership is being revoked
### isInGroup
```solidity
  function isInGroup(
    bytes32 _objectId,
    bytes32 _contextId,
    string _group
  ) external returns (bool)
```
Checks if an object belongs to `_group` group in given context
Assigning a role to the object makes it a member of a corresponding role group
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_objectId` | bytes32 | ID of an object that is being checked for role group membership
|`_contextId` | bytes32 | Context in which memebership should be checked
|`_group` | string | name of the role group
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`true`| bytes32 | if object with given ID is a member, false otherwise
### isParentInGroup
```solidity
  function isParentInGroup(
    bytes32 _objectId,
    bytes32 _contextId,
    string _group
  ) external returns (bool)
```
Check wheter a parent object belongs to the `_group` group in given context
Objects can have a parent object, i.e. entity is a parent of a user
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_objectId` | bytes32 | ID of an object who's parent is being checked for role group membership
|`_contextId` | bytes32 | Context in which the role group membership is being checked
|`_group` | string | name of the role group
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`true`| bytes32 | if object's parent is a member of this role group, false otherwise
### canAssign
```solidity
  function canAssign(
    bytes32 _objectId,
    bytes32 _contextId,
    bytes32 _role
  ) external returns (bool)
```
Check wheter a user can assign specific object to the `_role` role in given context
Check permission to assign to a role
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_objectId` | bytes32 | ID of an object that is being checked for assign rights
|`_contextId` | bytes32 | ID of the context in which permission is checked
|`_role` | bytes32 | name of the role to check
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`true`| bytes32 | if user the right to assign, false otherwise
### getRoleInContext
```solidity
  function getRoleInContext(
    bytes32 objectId,
    bytes32 contextId
  ) external returns (bytes32)
```
Get a user's (an objectId's) assigned role in a specific context
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`objectId` | bytes32 | ID of an object that is being checked for its assigned role in a specific context
|`contextId` | bytes32 | ID of the context in which the objectId's role is being checked
#### Return Values:
| Name                           | Type          | Description                                                                  |
| :----------------------------- | :------------ | :--------------------------------------------------------------------------- |
|`roleId`| bytes32 | objectId's role in the contextId
