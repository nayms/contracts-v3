# SimplePolicyStakeholderSignatureInvalid
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/CustomErrors.sol)

*Policy stakeholder signature validation failed*


```solidity
error SimplePolicyStakeholderSignatureInvalid(
    bytes32 signingHash, bytes signature, bytes32 signerId, bytes32 signersParent, bytes32 entityId
);
```

