# DuplicateSignerCreatingSimplePolicy
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/CustomErrors.sol)

*There is a duplicate address in the list of signers (the previous signer in the list is not < the next signer in the list).*


```solidity
error DuplicateSignerCreatingSimplePolicy(address previousSigner, address nextSigner);
```

