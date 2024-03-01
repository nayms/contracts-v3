# InvalidObjectIdForAddress
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/CustomErrors.sol)

*The object ID being passed in is expected to be an address type, but the bottom (least significant) 12 bytes are not empty.*


```solidity
error InvalidObjectIdForAddress(bytes32 objectId);
```

