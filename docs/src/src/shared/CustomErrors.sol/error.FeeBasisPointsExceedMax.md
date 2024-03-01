# FeeBasisPointsExceedMax
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

*The total fees can never exceed the premium payment or the marketplace trade.*


```solidity
error FeeBasisPointsExceedMax(uint256 actual, uint256 expected);
```

