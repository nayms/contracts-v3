# LibTokenizedVaultStaking
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/libs/LibTokenizedVaultStaking.sol)


## Functions
### _vTokenId

*First 4 bytes: "VTOK", next 8 bytes: interval, next 20 bytes: right 20 bytes of tokenId*


```solidity
function _vTokenId(bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32 vTokenId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_tokenId`|`bytes32`|The internal ID of the token.|
|`_interval`|`uint64`|The interval of staking.|


### _vTokenIdBucket


```solidity
function _vTokenIdBucket(bytes32 _tokenId) internal pure returns (bytes32);
```

### _initStaking


```solidity
function _initStaking(bytes32 _entityId, StakingConfig calldata _config) internal;
```

### _isStakingInitialized


```solidity
function _isStakingInitialized(bytes32 _entityId) internal view returns (bool);
```

### _stakingConfig


```solidity
function _stakingConfig(bytes32 _entityId) internal view returns (StakingConfig memory);
```

### _currentInterval


```solidity
function _currentInterval(bytes32 _entityId) internal view returns (uint64 currentInterval_);
```

### _payReward


```solidity
function _payReward(bytes32 _guid, bytes32 _entityId, bytes32 _rewardTokenId, uint256 _rewardAmount) internal;
```

### _stake


```solidity
function _stake(bytes32 _stakerId, bytes32 _entityId, uint256 _amount) internal;
```

### _unstake


```solidity
function _unstake(bytes32 _stakerId, bytes32 _entityId) internal;
```

### _getStakingStateWithRewardsBalances


```solidity
function _getStakingStateWithRewardsBalances(bytes32 _stakerId, bytes32 _entityId, uint64 _interval)
    internal
    view
    returns (StakingState memory state, RewardsBalances memory rewards);
```

### _getStakingState


```solidity
function _getStakingState(bytes32 _stakerId, bytes32 _entityId) internal view returns (StakingState memory state);
```

### _collectRewards


```solidity
function _collectRewards(bytes32 _stakerId, bytes32 _entityId, uint64 _interval) internal;
```

### _validateStakingParams


```solidity
function _validateStakingParams(StakingConfig calldata _config) internal view;
```

### _getR


```solidity
function _getR(bytes32 _entityId) internal view returns (uint64);
```

### _getA


```solidity
function _getA(bytes32 _entityId) internal view returns (uint64);
```

### _getD


```solidity
function _getD(bytes32 _entityId) internal view returns (uint64);
```

### addUniqueValue


```solidity
function addUniqueValue(RewardsBalances memory rewards, bytes32 newValue)
    public
    pure
    returns (RewardsBalances memory, uint256);
```

### _calculateStartTimeOfInterval

*Get the starting time of a given interval*


```solidity
function _calculateStartTimeOfInterval(bytes32 _entityId, uint64 _interval)
    internal
    view
    returns (uint64 intervalTime_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|The internal ID of the token|
|`_interval`|`uint64`|The interval to get the time for|


### _calculateStartTimeOfCurrentInterval


```solidity
function _calculateStartTimeOfCurrentInterval(bytes32 _entityId) internal view returns (uint64 intervalTime_);
```

### _stakedAmount


```solidity
function _stakedAmount(bytes32 _stakerId, bytes32 _entityId) internal view returns (uint256);
```

## Events
### TokenStakingStarted

```solidity
event TokenStakingStarted(
    bytes32 indexed entityId, bytes32 tokenId, uint256 initDate, uint64 a, uint64 r, uint64 divider, uint64 interval
);
```

### TokenStaked

```solidity
event TokenStaked(bytes32 indexed stakerId, bytes32 entityId, bytes32 tokenId, uint256 amount);
```

### TokenUnstaked

```solidity
event TokenUnstaked(bytes32 indexed stakerId, bytes32 entityId, bytes32 tokenId, uint256 amount);
```

### TokenRewardPaid

```solidity
event TokenRewardPaid(bytes32 guid, bytes32 entityId, bytes32 tokenId, bytes32 rewardTokenId, uint256 rewardAmount);
```

### TokenRewardCollected

```solidity
event TokenRewardCollected(
    bytes32 indexed stakerId,
    bytes32 entityId,
    bytes32 tokenId,
    uint64 interval,
    bytes32 rewardCurrency,
    uint256 rewardAmount
);
```

