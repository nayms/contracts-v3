Used to handle policies and token sales
## Functions
### updateAllowSimplePolicy
Enable/Disable Simple Policy creation for Entity ID: `_entityId`
Update simple policy creation allow flag
```solidity
  function updateAllowSimplePolicy(
    bytes32 _entityId,
    bool _allow
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | ID of the entity to update
|`_allow` | bool | Allow or not simple policy creation|
<br></br>
### createSimplePolicy
Create a Simple Policy
```solidity
  function createSimplePolicy(
    bytes32 _policyId,
    bytes32 _entityId,
    struct Stakeholders _stakeholders,
    struct SimplePolicy _simplePolicy,
    bytes32 _dataHash
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_policyId` | bytes32 | id of the policy
|`_entityId` | bytes32 | id of the entity
|`_stakeholders` | struct Stakeholders | Struct of roles, entity IDs and signatures for the policy
|`_simplePolicy` | struct SimplePolicy | policy to create
|`_dataHash` | bytes32 | hash of the offchain data|
<br></br>
### enableEntityTokenization
Enable an entity to be tokenized
```solidity
  function enableEntityTokenization(
    bytes32 _entityId,
    string _symbol,
    string _name
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | ID of the entity
|`_symbol` | string | The symbol assigned to the entity token
|`_name` | string | The name assigned to the entity token|
<br></br>
### startTokenSale
Start token sale of `_amount` tokens for total price of `_totalPrice`
Entity tokens are minted when the sale is started
```solidity
  function startTokenSale(
    bytes32 _entityId,
    uint256 _amount,
    uint256 _totalPrice
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | ID of the entity
|`_amount` | uint256 | amount of entity tokens to put on sale
|`_totalPrice` | uint256 | total price of the tokens|
<br></br>
### wrapToken
Wrap an entity token as ERC20
```solidity
  function wrapToken(
    bytes32 _entityId
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | ID of the entity|
<br></br>
### updateEntity
Update entity metadata
```solidity
  function updateEntity(
    bytes32 _entityId,
    struct Entity _entity
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | ID of the entity
|`_entity` | struct Entity | metadata of the entity|
<br></br>
### getEntityInfo
Get the the data for entity with ID: `_entityId`
Get the Entity data for a given entityId
```solidity
  function getEntityInfo(
    bytes32 _entityId
  ) external returns (struct Entity)
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | ID of the entity
|
<br></br>
#### Returns:
| Type | Description |
| --- | --- |
|`Entity` | struct with metadata of the entity|
<br></br>
