# PolicyCommissionsBasisPointsCannotBeGreaterThan10000
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/CustomErrors.sol)

*Policy commissions among commission receivers cannot sum to be greater than 10_000 basis points.*


```solidity
error PolicyCommissionsBasisPointsCannotBeGreaterThan10000(uint256 calculatedTotalBp);
```

