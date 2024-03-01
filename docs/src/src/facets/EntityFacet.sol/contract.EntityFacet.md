# EntityFacet
[Git Source](https://github.com/nayms/contracts-v3/blob/08976c385ed293c18988aa46a13c47179dbb0a28/src/facets/EntityFacet.sol)

**Inherits:**
[Modifiers](/src/shared/Modifiers.sol/contract.Modifiers.md), [ReentrancyGuard](/src/utils/ReentrancyGuard.sol/abstract.ReentrancyGuard.md)

Used to handle policies and token sales

*Mainly used for token sale and policies*


## Functions
### assertSimplePolicyEnabled


```solidity
modifier assertSimplePolicyEnabled(bytes32 _entityId);
```

### domainSeparatorV4

*Returns the domain separator for the current chain.*


```solidity
function domainSeparatorV4() external view returns (bytes32);
```

### hashTypedDataV4


```solidity
function hashTypedDataV4(bytes32 structHash) external view returns (bytes32);
```

### createSimplePolicy

Create a Simple Policy


```solidity
function createSimplePolicy(
    bytes32 _policyId,
    bytes32 _entityId,
    Stakeholders calldata _stakeholders,
    SimplePolicy calldata _simplePolicy,
    bytes32 _dataHash
)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_UNDERWRITERS)
    assertSimplePolicyEnabled(_entityId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_policyId`|`bytes32`|id of the policy|
|`_entityId`|`bytes32`|id of the entity|
|`_stakeholders`|`Stakeholders`|Struct of roles, entity IDs and signatures for the policy|
|`_simplePolicy`|`SimplePolicy`|policy to create|
|`_dataHash`|`bytes32`|hash of the offchain data|


### enableEntityTokenization

Enable an entity to be tokenized


```solidity
function enableEntityTokenization(bytes32 _objectId, string memory _symbol, string memory _name, uint256 _minimumSell)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of the entity|
|`_symbol`|`string`|The symbol assigned to the entity token|
|`_name`|`string`|The name assigned to the entity token|
|`_minimumSell`|`uint256`||


### updateEntityTokenInfo

Update entity token name and symbol


```solidity
function updateEntityTokenInfo(bytes32 _entityId, string memory _symbol, string memory _name)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|ID of the entity|
|`_symbol`|`string`|New entity token symbol|
|`_name`|`string`|New entity token name|


### startTokenSale

Start token sale of `_amount` tokens for total price of `_totalPrice`

*Entity tokens are minted when the sale is started*


```solidity
function startTokenSale(bytes32 _entityId, uint256 _amount, uint256 _totalPrice)
    external
    notLocked(msg.sig)
    nonReentrant
    assertPrivilege(_entityId, LC.GROUP_START_TOKEN_SALE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|ID of the entity|
|`_amount`|`uint256`|amount of entity tokens to put on sale|
|`_totalPrice`|`uint256`|total price of the tokens|


### isTokenWrapped

Check if an entity token is wrapped as ERC20


```solidity
function isTokenWrapped(bytes32 _entityId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|ID of the entity|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if it is, false otherwise|


### updateEntity

Update entity metadata


```solidity
function updateEntity(bytes32 _entityId, Entity calldata _updateEntity)
    external
    assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|ID of the entity|
|`_updateEntity`|`Entity`|metadata of the entity that can be updated|


### getEntityInfo

Get the data for entity with ID: `_entityId`

*Get the Entity data for a given entityId*


```solidity
function getEntityInfo(bytes32 _entityId) external view returns (Entity memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|ID of the entity|


### getFeeSchedule

Get the fee schedule


```solidity
function getFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) external view returns (FeeSchedule memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_entityId`|`bytes32`|ID of the entity|
|`_feeScheduleType`|`uint256`|fee schedule type|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`FeeSchedule`|FeeSchedule of given type for the entity|


### getObjectTokenSymbol

Get the object's token symbol


```solidity
function getObjectTokenSymbol(bytes32 _objectId) external view returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_objectId`|`bytes32`|ID of the object|


