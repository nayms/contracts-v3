# SimplePolicyStakeholderSignatureInvalid
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

*Policy stakeholder signature validation failed*


```solidity
error SimplePolicyStakeholderSignatureInvalid(
    bytes32 signingHash, bytes signature, bytes32 signerId, bytes32 signersParent, bytes32 entityId
);
```

