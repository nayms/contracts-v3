# Modifiers
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/shared/Modifiers.sol)

modifiers

Function modifiers to control access

*Function modifiers to control access*


## Functions
### notLocked


```solidity
modifier notLocked(bytes4 functionSelector);
```

### assertPrivilege


```solidity
modifier assertPrivilege(bytes32 _context, string memory _group);
```

### assertIsInGroup

Note: If the role returned by `_getRoleInContext` is empty (represented by bytes32(0)), we explicitly return an empty string.
This ensures the user doesn't receive a string that could potentially include unwanted data (like pointer and length) without any meaningful content.


```solidity
modifier assertIsInGroup(bytes32 _objectId, bytes32 _contextId, bytes32 _group);
```

### assertERC20Wrapper


```solidity
modifier assertERC20Wrapper(bytes32 _tokenId);
```

