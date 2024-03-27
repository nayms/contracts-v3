# FeeAllocation
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/FreeStructs.sol)


```solidity
struct FeeAllocation {
    bytes32 from;
    bytes32 to;
    bytes32 token;
    uint256 fee;
    uint256 basisPoints;
}
```

