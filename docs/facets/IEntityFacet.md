Used to handle policies and token sales
Mainly used for token sale and policies
## Functions
### updateAllowSimplePolicy
```solidity
  function updateAllowSimplePolicy(
    bytes32 _entityId,
    bool _allow
  ) external
```
Enable/Disable Simple Policy creation for Entity ID: `_entityId`
Update simple policy creation allow flag
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | ID of the entity to update
|`_allow` | bool | Allow or not simple policy creation
### createSimplePolicy
```solidity
  function createSimplePolicy(
    bytes32 _policyId,
    bytes32 _entityId,
    struct Stakeholders stakeholders,
    struct SimplePolicy simplePolicy,
    bytes32 _dataHash
  ) external
```
Create a Simple Policy
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_policyId` | bytes32 | id of the policy
|`_entityId` | bytes32 | id of the entity
|`stakeholders` | struct Stakeholders | Struct of roles, entity IDs and signatures for the policy
|`simplePolicy` | struct SimplePolicy | policy to create
|`_dataHash` | bytes32 | hash of the offchain data
### enableEntityTokenization
```solidity
  function enableEntityTokenization(
    bytes32 _entityId,
    string _symbol
  ) external
```
Enable an entity to be tokenized
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | ID of the entity
|`_symbol` | string | The symbol assigned to the entity token
### startTokenSale
```solidity
  function startTokenSale(
    bytes32 _entityId,
    uint256 _amount,
    uint256 _totalPrice
  ) external
```
Start token sale of `_amount` tokens for total price of `_totalPrice`
Entity tokens are minted when the sale is started
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | ID of the entity
|`_amount` | uint256 | amount of entity tokens to put on sale
|`_totalPrice` | uint256 | total price of the tokens
### updateEntity
```solidity
  function updateEntity(
    bytes32 _entityId,
    struct Entity _entity
  ) external
```
Update entity metadata
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | ID of the entity
|`_entity` | struct Entity | metadata of the entity
### getEntityInfo
```solidity
  function getEntityInfo(
    bytes32 _entityId
  ) external returns (struct Entity)
```
Get the the data for entity with ID: `_entityId`
Get the Entity data for a given entityId
#### Parameters:
| Name | Type | Description                                                          |
| :--- | :--- | :------------------------------------------------------------------- |
|`_entityId` | bytes32 | ID of the entity
