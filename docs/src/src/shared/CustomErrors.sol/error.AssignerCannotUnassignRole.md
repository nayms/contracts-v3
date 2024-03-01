# AssignerCannotUnassignRole
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

*Role assigner (msg.sender) must be in the assigners group to unassign a role.*


```solidity
error AssignerCannotUnassignRole(bytes32 assigner, bytes32 assignee, bytes32 context, string roleInContext);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assigner`|`bytes32`|Id of the role assigner, LibHelpers._getIdForAddress(msg sender)|
|`assignee`|`bytes32`|ObjectId that the role is being assigned to|
|`context`|`bytes32`|Context that the role is being assigned in|
|`roleInContext`|`string`|Role that is being assigned|

