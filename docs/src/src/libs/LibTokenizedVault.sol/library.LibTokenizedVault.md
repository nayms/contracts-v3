# LibTokenizedVault
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/libs/LibTokenizedVault.sol)


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

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`ownerId`|`bytes32`|Id of owner|
|`tokenId`|`bytes32`|ID of token|
|`newAmountOwned`|`uint256`|new amount owned|
|`functionName`|`string`|Function name|
|`msgSender`|`address`|msg.sender|

### InternalTokenSupplyUpdate
*Emitted when a token supply gets updated.*


```solidity
event InternalTokenSupplyUpdate(
    bytes32 indexed tokenId, uint256 newTokenSupply, string functionName, address indexed msgSender
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`bytes32`|ID of token|
|`newTokenSupply`|`uint256`|New token supply|
|`functionName`|`string`|Function name|
|`msgSender`|`address`|msg.sender|

### DividendDistribution
*Emitted when a dividend gets paid out.*


```solidity
event DividendDistribution(bytes32 indexed guid, bytes32 from, bytes32 to, bytes32 dividendTokenId, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`guid`|`bytes32`|dividend distribution ID|
|`from`|`bytes32`|distribution initiator|
|`to`|`bytes32`|distribution receiver|
|`dividendTokenId`|`bytes32`||
|`amount`|`uint256`|distributed amount|

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

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`accountId`|`bytes32`|ID of the account withdrawing the dividend|
|`tokenId`|`bytes32`|ID of the participation token that is paying out the dividends to holders|
|`amountOwned`|`uint256`|owned amount of the participation tokens|
|`dividendTokenId`|`bytes32`|ID of the dividend denomination token|
|`dividendAmountWithdrawn`|`uint256`|amount withdrawn|

