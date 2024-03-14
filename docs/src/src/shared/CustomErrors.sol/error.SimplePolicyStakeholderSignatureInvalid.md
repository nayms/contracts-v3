# SimplePolicyStakeholderSignatureInvalid
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/CustomErrors.sol)

*Policy stakeholder signature validation failed*


```solidity
error SimplePolicyStakeholderSignatureInvalid(
    bytes32 signingHash, bytes signature, bytes32 signerId, bytes32 signersParent, bytes32 entityId
);
```

