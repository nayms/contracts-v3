# InvalidObjectIdForAddress
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/CustomErrors.sol)

*The object ID being passed in is expected to be an address type, but the bottom (least significant) 12 bytes are not empty.*


```solidity
error InvalidObjectIdForAddress(bytes32 objectId);
```

