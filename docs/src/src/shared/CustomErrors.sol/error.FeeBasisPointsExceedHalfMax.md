# FeeBasisPointsExceedHalfMax
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/CustomErrors.sol)

*The total basis points for a fee schedule, policy fee receivers at policy creation, or maker bp cannot be greater than half of LibConstants.BP_FACTOR.
This is to prevent the total basis points of a fee schedule with additional fee receivers (policy fee receivers for fee payments on premiums) from being greater than 100%.*


```solidity
error FeeBasisPointsExceedHalfMax(uint256 actual, uint256 expected);
```

