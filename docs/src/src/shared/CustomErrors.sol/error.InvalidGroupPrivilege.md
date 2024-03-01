# InvalidGroupPrivilege
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

Error message for when a sender is not authorized to perform an action with their assigned role in a given context of a group

*In the assertPrivilege modifier, this error message returns the context and the role in the context, not the user's role in the system context.*


```solidity
error InvalidGroupPrivilege(bytes32 msgSenderId, bytes32 context, string roleInContext, string group);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`msgSenderId`|`bytes32`|Id of the sender|
|`context`|`bytes32`|Context in which the sender is trying to perform an action|
|`roleInContext`|`string`|Role of the sender in the context|
|`group`|`string`|Group to check the sender's role in|

