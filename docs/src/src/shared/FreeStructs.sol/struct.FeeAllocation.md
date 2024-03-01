# FeeAllocation
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/FreeStructs.sol)


```solidity
struct FeeAllocation {
    bytes32 from;
    bytes32 to;
    bytes32 token;
    uint256 fee;
    uint256 basisPoints;
}
```

