# LibTokenizedVault
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/libs/LibTokenizedVault.sol)


## Functions
### _internalBalanceOf


```solidity
function _internalBalanceOf(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256);
```

### _internalTokenSupply


```solidity
function _internalTokenSupply(bytes32 _objectId) internal view returns (uint256);
```

### _internalTransfer


```solidity
function _internalTransfer(bytes32 _from, bytes32 _to, bytes32 _tokenId, uint256 _amount)
    internal
    returns (bool success);
```

### _internalMint


```solidity
function _internalMint(bytes32 _to, bytes32 _tokenId, uint256 _amount) internal;
```

### _normalizeDividends


```solidity
function _normalizeDividends(bytes32 _from, bytes32 _to, bytes32 _tokenId, uint256 _amount, bool _updateTotals)
    internal;
```

### _internalBurn


```solidity
function _internalBurn(bytes32 _from, bytes32 _tokenId, uint256 _amount) internal;
```

### _withdrawDividend


```solidity
function _withdrawDividend(bytes32 _ownerId, bytes32 _tokenId, bytes32 _dividendTokenId) internal;
```

### _getWithdrawableDividend


```solidity
function _getWithdrawableDividend(bytes32 _ownerId, bytes32 _tokenId, bytes32 _dividendTokenId)
    internal
    view
    returns (uint256 withdrawableDividend_);
```

### _withdrawAllDividends


```solidity
function _withdrawAllDividends(bytes32 _ownerId, bytes32 _tokenId) internal;
```

### _payDividend


```solidity
function _payDividend(bytes32 _guid, bytes32 _from, bytes32 _to, bytes32 _dividendTokenId, uint256 _amount) internal;
```

### _getWithdrawableDividendAndDeductionMath


```solidity
function _getWithdrawableDividendAndDeductionMath(
    uint256 _amount,
    uint256 _supply,
    uint256 _totalDividend,
    uint256 _withdrawnSoFar
) internal pure returns (uint256 _withdrawableDividend);
```

### _getLockedBalance


```solidity
function _getLockedBalance(bytes32 _accountId, bytes32 _tokenId) internal view returns (uint256 amount);
```

### _totalDividends


```solidity
function _totalDividends(bytes32 _tokenId, bytes32 _dividendDenominationId) internal view returns (uint256);
```

## Events
### InternalTokenBalanceUpdate
*Emitted when a token balance gets updated.*


```solidity
event InternalTokenBalanceUpdate(
    bytes32 indexed ownerId, bytes32 tokenId, uint256 newAmountOwned, string functionName, address indexed msgSender
);
```

### InternalTokenSupplyUpdate
*Emitted when a token supply gets updated.*


```solidity
event InternalTokenSupplyUpdate(
    bytes32 indexed tokenId, uint256 newTokenSupply, string functionName, address indexed msgSender
);
```

### DividendDistribution
*Emitted when a dividend gets paid out.*


```solidity
event DividendDistribution(bytes32 indexed guid, bytes32 from, bytes32 to, bytes32 dividendTokenId, uint256 amount);
```

### DividendWithdrawn
*Emitted when a dividend gets paid out.*


```solidity
event DividendWithdrawn(
    bytes32 indexed accountId,
    bytes32 tokenId,
    uint256 amountOwned,
    bytes32 dividendTokenId,
    uint256 dividendAmountWithdrawn
);
```

