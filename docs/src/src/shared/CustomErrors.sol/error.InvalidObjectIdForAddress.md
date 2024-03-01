# InvalidObjectIdForAddress
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

*The object ID being passed in is expected to be an address type, but the bottom (least significant) 12 bytes are not empty.*


```solidity
error InvalidObjectIdForAddress(bytes32 objectId);
```

