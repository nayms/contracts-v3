# FeeBasisPointsExceedMax
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/CustomErrors.sol)

*The total fees can never exceed the premium payment or the marketplace trade.*


```solidity
error FeeBasisPointsExceedMax(uint256 actual, uint256 expected);
```

