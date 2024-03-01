# FeeAllocation
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/FreeStructs.sol)


```solidity
struct FeeAllocation {
    bytes32 from;
    bytes32 to;
    bytes32 token;
    uint256 fee;
    uint256 basisPoints;
}
```
