# LibHelpers
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/libs/LibHelpers.sol)

Pure functions


## Functions
### _getIdForObjectAtIndex


```solidity
function _getIdForObjectAtIndex(uint256 _index) internal pure returns (bytes32);
```

### _getIdForAddress


```solidity
function _getIdForAddress(address _addr) internal pure returns (bytes32);
```

### _getSenderId


```solidity
function _getSenderId() internal view returns (bytes32);
```

### _checkBottom12BytesAreEmpty


```solidity
function _checkBottom12BytesAreEmpty(bytes32 value) internal pure returns (bool);
```

### _checkUpper12BytesAreEmpty


```solidity
function _checkUpper12BytesAreEmpty(bytes32 value) internal pure returns (bool);
```

### _getAddressFromId


```solidity
function _getAddressFromId(bytes32 _id) internal pure returns (address);
```

### _isAddress


```solidity
function _isAddress(bytes32 _id) internal pure returns (bool);
```

### _stringToBytes32

*Converts a string to a bytes32 representation.
No length check for the input string is performed in this function, as it is only
used with predefined string constants from LibConstants related to role names,
role group names, and special platform identifiers.
These critical string constants are verified to be 32 bytes or less off-chain
before being used, and can only be set by platform admins.*


```solidity
function _stringToBytes32(string memory strIn) internal pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strIn`|`string`|The input string to be converted|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The bytes32 representation of the input string|


### _bytesToBytes32


```solidity
function _bytesToBytes32(bytes memory source) internal pure returns (bytes32 result);
```

### _bytes32ToBytes


```solidity
function _bytes32ToBytes(bytes32 input) internal pure returns (bytes memory);
```

