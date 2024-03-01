# FeeBasisPointsExceedMax
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/CustomErrors.sol)

*The total fees can never exceed the premium payment or the marketplace trade.*


```solidity
error FeeBasisPointsExceedMax(uint256 actual, uint256 expected);
```

