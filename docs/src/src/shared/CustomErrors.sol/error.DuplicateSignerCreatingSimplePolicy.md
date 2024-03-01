# DuplicateSignerCreatingSimplePolicy
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

*There is a duplicate address in the list of signers (the previous signer in the list is not < the next signer in the list).*


```solidity
error DuplicateSignerCreatingSimplePolicy(address previousSigner, address nextSigner);
```

