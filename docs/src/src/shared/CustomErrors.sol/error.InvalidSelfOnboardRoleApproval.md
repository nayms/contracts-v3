# InvalidSelfOnboardRoleApproval
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

only Token Holder or Capital Provider should be approved for self-onboarding


```solidity
error InvalidSelfOnboardRoleApproval(string role);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`role`|`string`|The name of the rle which should not be approaved for self-onboarding|

