# LibObject
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/libs/LibObject.sol)

Contains internal methods for core Nayms system functionality


## Functions
### _createObject


```solidity
function _createObject(bytes32 _objectId, bytes12 _objectType, bytes32 _parentId, bytes32 _dataHash) internal;
```

### _createObject


```solidity
function _createObject(bytes32 _objectId, bytes12 _objectType, bytes32 _dataHash) internal;
```

### _createObject


```solidity
function _createObject(bytes32 _objectId, bytes12 _objectType) internal;
```

### _setDataHash


```solidity
function _setDataHash(bytes32 _objectId, bytes32 _dataHash) internal;
```

### _getDataHash


```solidity
function _getDataHash(bytes32 _objectId) internal view returns (bytes32 objectDataHash);
```

### _getParent


```solidity
function _getParent(bytes32 _objectId) internal view returns (bytes32);
```

### _getParentFromAddress


```solidity
function _getParentFromAddress(address addr) internal view returns (bytes32);
```

### _setParent


```solidity
function _setParent(bytes32 _objectId, bytes32 _parentId) internal;
```

### _isObjectTokenizable


```solidity
function _isObjectTokenizable(bytes32 _objectId) internal view returns (bool);
```

### _tokenSymbolNotUsed


```solidity
function _tokenSymbolNotUsed(string memory _symbol) internal view returns (bool);
```

### _validateTokenNameAndSymbol


```solidity
function _validateTokenNameAndSymbol(bytes32 _objectId, string memory _symbol, string memory _name) private view;
```

### _enableObjectTokenization


```solidity
function _enableObjectTokenization(bytes32 _objectId, string memory _symbol, string memory _name, uint256 _minimumSell)
    internal;
```

### _updateTokenInfo


```solidity
function _updateTokenInfo(bytes32 _objectId, string memory _symbol, string memory _name) internal;
```

### _isObjectTokenWrapped


```solidity
function _isObjectTokenWrapped(bytes32 _objectId) internal view returns (bool);
```

### _wrapToken


```solidity
function _wrapToken(bytes32 _entityId) internal;
```

### _isObject


```solidity
function _isObject(bytes32 _id) internal view returns (bool);
```

### _getObjectType


```solidity
function _getObjectType(bytes32 _objectId) internal pure returns (bytes12 objectType);
```

### _isObjectType


```solidity
function _isObjectType(bytes32 _objectId, bytes12 _objectType) internal pure returns (bool);
```

### _getObjectMeta


```solidity
function _getObjectMeta(bytes32 _id)
    internal
    view
    returns (bytes32 parent, bytes32 dataHash, string memory tokenSymbol, string memory tokenName, address tokenWrapper);
```

### _objectTokenSymbol


```solidity
function _objectTokenSymbol(bytes32 _objectId) internal view returns (string memory);
```

## Events
### TokenizationEnabled

```solidity
event TokenizationEnabled(bytes32 objectId, string tokenSymbol, string tokenName);
```

### TokenWrapped

```solidity
event TokenWrapped(bytes32 indexed entityId, address tokenWrapper);
```

### TokenInfoUpdated

```solidity
event TokenInfoUpdated(bytes32 indexed objectId, string symbol, string name);
```

### ObjectCreated

```solidity
event ObjectCreated(bytes32 objectId, bytes32 parentId, bytes32 dataHash);
```

### ObjectUpdated

```solidity
event ObjectUpdated(bytes32 objectId, bytes32 parentId, bytes32 dataHash);
```

