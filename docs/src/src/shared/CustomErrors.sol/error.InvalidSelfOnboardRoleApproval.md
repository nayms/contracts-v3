# InvalidSelfOnboardRoleApproval
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/CustomErrors.sol)

only Token Holder or Capital Provider should be approved for self-onboarding


```solidity
error InvalidSelfOnboardRoleApproval(string role);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`string`|The name of the rle which should not be approaved for self-onboarding|

