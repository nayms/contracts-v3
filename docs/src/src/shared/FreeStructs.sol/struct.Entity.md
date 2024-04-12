# Entity
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/FreeStructs.sol)


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

