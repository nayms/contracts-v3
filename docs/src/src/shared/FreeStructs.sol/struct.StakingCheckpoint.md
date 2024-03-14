# StakingCheckpoint
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/FreeStructs.sol)


```solidity
struct StakingCheckpoint {
    int128 bias;
    int128 slope;
    uint256 ts;
    uint256 blk;
}
```

