# Entity
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/FreeStructs.sol)


```solidity
struct Entity {
    bytes32 assetId;
    uint256 collateralRatio;
    uint256 maxCapacity;
    uint256 utilizedCapacity;
    bool simplePolicyEnabled;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`assetId`|`bytes32`||
|`collateralRatio`|`uint256`||
|`maxCapacity`|`uint256`|Maximum allowable amount of capacity that an entity is given. Denominated by assetId.|
|`utilizedCapacity`|`uint256`|The utilized capacity of the entity. Denominated by assetId.|
|`simplePolicyEnabled`|`bool`||

