Used to handle policies and token sales
## Functions
### domainSeparatorV4
No description
Returns the domain separator for the current chain.
```solidity
  function domainSeparatorV4(
  ) external returns (bytes32)
```
### hashTypedDataV4
No description
Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
function returns the hash of the fully encoded EIP712 message for this domain.
This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
```solidity
bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
    keccak256("Mail(address to,string contents)"),
    mailTo,
    keccak256(bytes(mailContents))
)));
address signer = ECDSA.recover(digest, signature);
```
```solidity
  function hashTypedDataV4(
  ) external returns (bytes32)
```
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
### updateEntityTokenInfo
Update entity token name and symbol
```solidity
  function updateEntityTokenInfo(
    bytes32 _entityId,
    string _symbol,
    string _name
  ) external
```
#### Arguments:
| Argument | Type | Description |
| --- | --- | --- |
|`_entityId` | bytes32 | ID of the entity
|`_symbol` | string | New entity token symbol
|`_name` | string | New entity token name|
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
### isTokenWrapped
Check if an entity token is wrapped as ERC20
```solidity
  function isTokenWrapped(
    bytes32 _entityId
  ) external returns (bool)
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
