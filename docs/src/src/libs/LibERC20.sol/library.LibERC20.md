# LibERC20
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/libs/LibERC20.sol)

\
Author: Nick Mudge
/*****************************************************************************


## Functions
### decimals


```solidity
function decimals(address _token) internal returns (uint8);
```

### symbol


```solidity
function symbol(address _token) internal returns (string memory);
```

### balanceOf


```solidity
function balanceOf(address _token, address _who) internal returns (uint256);
```

### transferFrom


```solidity
function transferFrom(address _token, address _from, address _to, uint256 _value) internal;
```

### transfer


```solidity
function transfer(address _token, address _to, uint256 _value) internal;
```

### handleReturn


```solidity
function handleReturn(bool _success, bytes memory _result) internal pure;
```

### _assertNotEmptyContract


```solidity
function _assertNotEmptyContract(address _token) internal view;
```

