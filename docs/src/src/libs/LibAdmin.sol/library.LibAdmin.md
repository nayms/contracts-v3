# LibAdmin
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/libs/LibAdmin.sol)


## Functions
### _getSystemId


```solidity
function _getSystemId() internal pure returns (bytes32);
```

### _updateMaxDividendDenominations


```solidity
function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal;
```

### _getMaxDividendDenominations


```solidity
function _getMaxDividendDenominations() internal view returns (uint8);
```

### _isSupportedExternalTokenAddress


```solidity
function _isSupportedExternalTokenAddress(address _tokenId) internal view returns (bool);
```

### _isSupportedExternalToken


```solidity
function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool);
```

### _addSupportedExternalToken


```solidity
function _addSupportedExternalToken(address _tokenAddress, uint256 _minimumSell) internal;
```

### _getSupportedExternalTokens


```solidity
function _getSupportedExternalTokens() internal view returns (address[] memory);
```

### _lockFunction


```solidity
function _lockFunction(bytes4 functionSelector) internal;
```

### _unlockFunction


```solidity
function _unlockFunction(bytes4 functionSelector) internal;
```

### _isFunctionLocked


```solidity
function _isFunctionLocked(bytes4 functionSelector) internal view returns (bool);
```

### _lockAllFundTransferFunctions


```solidity
function _lockAllFundTransferFunctions() internal;
```

### _unlockAllFundTransferFunctions


```solidity
function _unlockAllFundTransferFunctions() internal;
```

### _approveSelfOnboarding


```solidity
function _approveSelfOnboarding(address _userAddress, bytes32 _entityId, string calldata _role) internal;
```

### _onboardUser


```solidity
function _onboardUser(address _userAddress) internal;
```

### _cancelSelfOnboarding


```solidity
function _cancelSelfOnboarding(address _userAddress) internal;
```

## Events
### MaxDividendDenominationsUpdated

```solidity
event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
```

### SupportedTokenAdded

```solidity
event SupportedTokenAdded(address indexed tokenAddress);
```

### FunctionsLocked

```solidity
event FunctionsLocked(bytes4[] functionSelectors);
```

### FunctionsUnlocked

```solidity
event FunctionsUnlocked(bytes4[] functionSelectors);
```

### ObjectMinimumSellUpdated

```solidity
event ObjectMinimumSellUpdated(bytes32 objectId, uint256 newMinimumSell);
```

### SelfOnboardingApproved

```solidity
event SelfOnboardingApproved(address indexed userAddress);
```

### SelfOnboardingCompleted

```solidity
event SelfOnboardingCompleted(address indexed userAddress);
```

### SelfOnboardingCancelled

```solidity
event SelfOnboardingCancelled(address indexed userAddress);
```

