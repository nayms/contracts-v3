# LibAppStorage
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/AppStorage.sol)


## State Variables
### NAYMS_DIAMOND_STORAGE_POSITION

```solidity
bytes32 internal constant NAYMS_DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.nayms.storage");
```


### FUNCTION_LOCK_STORAGE_POSITION

```solidity
bytes32 internal constant FUNCTION_LOCK_STORAGE_POSITION = keccak256("diamond.function.lock.storage");
```


## Functions
### diamondStorage


```solidity
function diamondStorage() internal pure returns (AppStorage storage ds);
```

### functionLockStorage


```solidity
function functionLockStorage() internal pure returns (FunctionLockedStorage storage ds);
```

