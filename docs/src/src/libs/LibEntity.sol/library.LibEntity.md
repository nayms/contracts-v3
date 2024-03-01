# LibEntity
[Git Source](https://github.com/nayms/contracts-v3/blob/ea2c06f70609c813d27d424e0330651d3c634d21/src/libs/LibEntity.sol)


## Functions
### _validateSimplePolicyCreation

*If an entity passes their checks to create a policy, ensure that the entity's capacity is appropriately decreased by the amount of capital that will be tied to the new policy being created.*


```solidity
function _validateSimplePolicyCreation(
    bytes32 _entityId,
    SimplePolicy memory simplePolicy,
    Stakeholders calldata _stakeholders
) internal view;
```

### _createSimplePolicy


```solidity
function _createSimplePolicy(
    bytes32 _policyId,
    bytes32 _entityId,
    Stakeholders calldata _stakeholders,
    SimplePolicy calldata _simplePolicy,
    bytes32 _offchainDataHash
) internal;
```

### getSigner


```solidity
function getSigner(bytes32 signingHash, bytes memory signature) private pure returns (address);
```

### _startTokenSale


```solidity
function _startTokenSale(bytes32 _entityId, uint256 _amount, uint256 _totalPrice) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`||
|`_amount`|`uint256`|the amount of entity token that is minted and put on sale|
|`_totalPrice`|`uint256`|the buy amount|


### _createEntity


```solidity
function _createEntity(bytes32 _entityId, bytes32 _accountAdmin, Entity memory _entity, bytes32 _dataHash) internal;
```

### _updateEntity

*This currently updates a non cell type entity and a cell type entity, but
we should consider splitting the functionality*


```solidity
function _updateEntity(bytes32 _entityId, Entity calldata _updateEntityStruct) internal;
```

### validateEntity


```solidity
function validateEntity(Entity memory _entity) internal view;
```

### _getEntityInfo


```solidity
function _getEntityInfo(bytes32 _entityId) internal view returns (Entity memory entity);
```

### _isEntity


```solidity
function _isEntity(bytes32 _entityId) internal view returns (bool);
```

## Events
### EntityCreated
New entity has been created

*Emitted when entity is created*


```solidity
event EntityCreated(bytes32 indexed entityId, bytes32 entityAdmin);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`entityId`|`bytes32`|Unique ID for the entity|
|`entityAdmin`|`bytes32`|Unique ID of the entity administrator|

### EntityUpdated
An entity has been updated

*Emitted when entity is updated*


```solidity
event EntityUpdated(bytes32 indexed entityId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`entityId`|`bytes32`|Unique ID for the entity|

### SimplePolicyCreated
New policy has been created

*Emitted when policy is created*


```solidity
event SimplePolicyCreated(bytes32 indexed id, bytes32 entityId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`id`|`bytes32`|Unique ID for the policy|
|`entityId`|`bytes32`|ID of the entity|

### TokenSaleStarted
New token sale has been started

*Emitted when token sale is started*


```solidity
event TokenSaleStarted(bytes32 indexed entityId, uint256 offerId, string tokenSymbol, string tokenName);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`entityId`|`bytes32`|Unique ID for the entity|
|`offerId`|`uint256`|ID of the sale offer|
|`tokenSymbol`|`string`|symbol of the token|
|`tokenName`|`string`|name of the token|

### CollateralRatioUpdated
Collateral ratio has been updated

*Emitted when collateral ratio is updated*


```solidity
event CollateralRatioUpdated(bytes32 indexed entityId, uint256 collateralRatio, uint256 utilizedCapacity);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`entityId`|`bytes32`|ID of the entity|
|`collateralRatio`|`uint256`|required collateral ratio|
|`utilizedCapacity`|`uint256`|capacity utilization according to the new ratio|

