# DuplicateSignerCreatingSimplePolicy
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/CustomErrors.sol)

*There is a duplicate address in the list of signers (the previous signer in the list is not < the next signer in the list).*


```solidity
error DuplicateSignerCreatingSimplePolicy(address previousSigner, address nextSigner);
```

