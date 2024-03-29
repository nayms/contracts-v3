# StakingFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/facets/StakingFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md)


## Functions
### vTokenId


```solidity
function vTokenId(bytes32 _tokenId, uint64 _interval) external pure returns (bytes32);
```

### currentInterval


```solidity
function currentInterval(bytes32 _entityId) external view returns (uint64);
```

### getStakingConfig


```solidity
function getStakingConfig(bytes32 _entityId) external view returns (StakingConfig memory);
```

### initStaking


```solidity
function initStaking(bytes32 _entityId, StakingConfig calldata _config)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS);
```

### stake


```solidity
function stake(bytes32 _entityId, uint256 _amount) external notLocked(msg.sig);
```

### unstake


```solidity
function unstake(bytes32 _entityId) external notLocked(msg.sig);
```

### lastCollectedInterval


```solidity
function lastCollectedInterval(bytes32 _entityId, bytes32 _stakerId) external view returns (uint64);
```

### lastIntervalPaid


```solidity
function lastIntervalPaid(bytes32 _entityId) external view returns (uint64);
```

### calculateStartTimeOfInterval


```solidity
function calculateStartTimeOfInterval(bytes32 _entityId, uint64 _interval) external view returns (uint256);
```

### calculateStartTimeOfCurrentInterval


```solidity
function calculateStartTimeOfCurrentInterval(bytes32 _entityId) external view returns (uint256);
```

### getRewardsBalance


```solidity
function getRewardsBalance(bytes32 _entityId)
    external
    view
    returns (bytes32[] memory rewardCurrencies_, uint256[] memory rewardAmounts_);
```

### collectRewards


```solidity
function collectRewards(bytes32 _entityId) external notLocked(msg.sig);
```

### getStakingState


```solidity
function getStakingState(bytes32 _stakerId, bytes32 _entityId) external view returns (StakingState memory);
```

### payReward


```solidity
function payReward(bytes32 _guid, bytes32 _entityId, bytes32 _rewardTokenId, uint256 _amount)
    external
    notLocked(msg.sig)
    assertPrivilege(_entityId, LC.GROUP_ENTITY_ADMINS);
```

### getStakingAmounts


```solidity
function getStakingAmounts(bytes32 _stakerId, bytes32 _entityId)
    external
    view
    returns (uint256 stakedAmount_, uint256 boostedAmount_);
```

