# AssignerCannotUnassignRole
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/CustomErrors.sol)

*Role assigner (msg.sender) must be in the assigners group to unassign a role.*


```solidity
error AssignerCannotUnassignRole(bytes32 assigner, bytes32 assignee, bytes32 context, string roleInContext);
```

