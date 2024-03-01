# LibAppStorage
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/shared/AppStorage.sol)


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

