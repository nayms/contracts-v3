# MarketInfo
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/shared/FreeStructs.sol)


```solidity
struct MarketInfo {
    bytes32 creator;
    bytes32 sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    bytes32 buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    uint256 feeSchedule;
    uint256 state;
    uint256 rankNext;
    uint256 rankPrev;
}
```

