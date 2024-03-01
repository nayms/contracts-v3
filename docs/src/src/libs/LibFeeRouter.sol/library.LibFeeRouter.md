# LibFeeRouter
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/libs/LibFeeRouter.sol)


## Functions
### _calculatePremiumFees


```solidity
function _calculatePremiumFees(bytes32 _policyId, uint256 _premiumPaid)
    internal
    view
    returns (CalculatedFees memory cf);
```

### _payPremiumFees

*The total bp for a policy premium fee schedule cannot exceed LibConstants.BP_FACTOR since the policy's additional fee receivers and fee schedule are each checked to be less than LibConstants.BP_FACTOR / 2 when they are being set.*


```solidity
function _payPremiumFees(bytes32 _policyId, uint256 _premiumPaid) internal;
```

### _calculateTradingFees


```solidity
function _calculateTradingFees(bytes32 _buyerId, bytes32 _sellToken, bytes32 _buyToken, uint256 _buyAmount)
    internal
    view
    returns (uint256 totalFees_, uint256 totalBP_);
```

### _payTradingFees

*The total bp for a marketplace fee schedule cannot exceed LibConstants.BP_FACTOR since the maker BP and fee schedules are each checked to be less than LibConstants.BP_FACTOR / 2 when they are being set.*


```solidity
function _payTradingFees(
    uint256 _feeScheduleType,
    bytes32 _buyer,
    bytes32 _makerId,
    bytes32 _takerId,
    bytes32 _tokenId,
    uint256 _buyAmount
) internal returns (uint256 totalFees_);
```

### _replaceMakerBP


```solidity
function _replaceMakerBP(uint16 tradingCommissionMakerBP) internal;
```

### _addFeeSchedule


```solidity
function _addFeeSchedule(
    bytes32 _entityId,
    uint256 _feeScheduleType,
    bytes32[] calldata _receiver,
    uint16[] calldata _basisPoints
) internal;
```

### _getFeeSchedule

*VERY IMPORTANT: always use this method to fetch the fee schedule because of fallback to default one!*


```solidity
function _getFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) internal view returns (FeeSchedule memory);
```

### _removeFeeSchedule


```solidity
function _removeFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) internal;
```

### _getMakerBP


```solidity
function _getMakerBP() internal view returns (uint16);
```

## Events
### FeePaid

```solidity
event FeePaid(bytes32 indexed fromId, bytes32 indexed toId, bytes32 tokenId, uint256 amount, uint256 feeType);
```

### MakerBasisPointsUpdated

```solidity
event MakerBasisPointsUpdated(uint16 tradingCommissionMakerBP);
```

### FeeScheduleAdded

```solidity
event FeeScheduleAdded(bytes32 entityId, uint256 feeType, FeeSchedule feeSchedule);
```

