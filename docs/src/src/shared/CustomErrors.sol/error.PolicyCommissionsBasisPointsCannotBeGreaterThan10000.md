# PolicyCommissionsBasisPointsCannotBeGreaterThan10000
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/CustomErrors.sol)

*Policy commissions among commission receivers cannot sum to be greater than 10_000 basis points.*


```solidity
error PolicyCommissionsBasisPointsCannotBeGreaterThan10000(uint256 calculatedTotalBp);
```

