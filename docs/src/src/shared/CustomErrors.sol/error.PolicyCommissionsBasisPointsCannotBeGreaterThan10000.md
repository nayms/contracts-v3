# PolicyCommissionsBasisPointsCannotBeGreaterThan10000
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/CustomErrors.sol)

*Policy commissions among commission receivers cannot sum to be greater than 10_000 basis points.*


```solidity
error PolicyCommissionsBasisPointsCannotBeGreaterThan10000(uint256 calculatedTotalBp);
```

