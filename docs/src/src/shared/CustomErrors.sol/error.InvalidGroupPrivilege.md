# InvalidGroupPrivilege
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/CustomErrors.sol)

Error message for when a sender is not authorized to perform an action with their assigned role in a given context of a group

*In the assertPrivilege modifier, this error message returns the context and the role in the context, not the user's role in the system context.*


```solidity
error InvalidGroupPrivilege(bytes32 msgSenderId, bytes32 context, string roleInContext, string group);
```

