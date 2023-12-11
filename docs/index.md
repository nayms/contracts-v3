# Nayms Contracts v3

A single beautiful diamond. All functionality should be in facets.

## Technical guidelines

- Comments in the code should be in Natspec format. (https://www.w3schools.io/blockchain/solidity-comments/)
- All low-level methods should be implemented in a library.
- Events generally should be emitted in libraries
- Facets should be used to expose public functionality and control access (apply moderators).
- AppStorage should only be accessed via library

## Introduction

The Nayms application allows insurance contracts to be created, underwritten, tokenized, traded and settled, all on chain.
In brief:

- A user can issue multiple policies on behalf of their company or Cell (represented by an Entity in the system).
- These Cells can manage multiple policies and issue internal tokens that can be sold to fund their portfolio.
- Other users can purchase these Cell tokens on behalf of their Business Entities (Capital Providers).
- The Cell can then share profits by issuing profit distributions to its token holders.

# Key Technical Concepts

## Everything in the ecosystem is defined as an object. Every object:

- has a unique bytes32 id
- can have a parent
- can be tokenized. When an object is tokenized it becomes an internal token and can be traded using the market facet.
- can own internal tokens (other tokenized objects)
- can be paid a dividend in any other tokenized object (internal or external token)
- can have an additional data structure associated with it to hold data (Entity, Policy, etc.)
- can belong to a group within the context of another object in the Access Control List (ACL)
- external addresses for contracts or wallets can be referenced in the system by converting the address to bytes32

### External ERC20 tokens as internal objects

When an ERC20 token is transferred into Nayms, an internal token amount equal to the amount transferred is minted, the ID of which is derived from the address. The internal ledger then keeps track of ownership as long as the currency is in deposit. When the ERC20 is withdrawn from Nayms, the amount is burned and transferred out ouf the contract. All balances and transfers are then done on the internal ledger.

## Access Control List (ACL)

The Access Control List (ACL) powers most of the modifiers in the application. It is also used to control access to off-chain data by the backend.
The ACL is a mechanism of specifying the role an object has in the context of another object. For example, a user can have a role within the context of the business entity or company they represent.
Roles are grouped and user functions are restricted to users in certain groups.
Users are allowed to assign roles to other users based on the group they belong to.

Aspects of roles

- A user can only have one role in any given context.
- The system is a context and roles granted within the context of the system are system roles and apply globally - even to other objects. System roles include "System Manager" and "System Administrator"
- A role may belong to multiple groups. A group can contain multiple roles.
- A role can have only one assigner group

Roles are configured by providing two tables, or two two-dimensional arrays of strings:
[Roles, Groups]
[Roles, Assigner Group]
For details please review the Role and Group configuration tables.

## The Business Ecosystem Consists of the Following:

### Users

All Users:

- are objects that are given an ID that is their wallet address converted to bytes32.
- are authenticated by signing a pass-phrase.
- can have an Entity as their parent
- can have a role in the context of their Entity
- can perform actions on behalf of their Entity depending on their role

### Entities

Entities or (Business Entities) represent companies or organizations in the ecosystem. An Entity can be an insured party, an underwriter, a broker, a claims administrator or a cell. A cell is a type of entity that issues and manages a portfolio of Policies. All user actions are performed on behalf of entities.

Entities:

- can be tokenized
- can own and trade tokens of other entities
- can have dividends paid to the owners of their internal token
- can issue dividends to the owners of their internal token themselves

Users belonging to entities can perform the following actions on policies, on behalf of their Entity, depending on the role their entity has on the policy:

- approve a Policy (off-chain signature)
- issue a policy
- pay a premium
- make a claim
- approve/settle a claim

### External Token

An external token is the bytes32 object ID given to an ERC20 token deposited into the Nayms platform.
When a user deposits an approved ERC20 into the Nayms platform, a bytes32 object ID is assigned to the ERC20 token and is labeled as an external token.

In other words, an external token is the internal representation of the underlying ERC20 token.
I.E. if a user deposits 100 WETH, the user is credited 100 WETH on the internal ledger.
Nayms external token IDs are derived from the respective ERC20 contract address.

### Platform Token

A platform token is the bytes32 object ID given to a tokenized entity.

#### Entity Types

The types of entities are:

- Capital Provider
- Broker
- Underwriter
- Insured Party
  Functionality differs in the app depending on Entity type but not on chain.

#### Policy Types

Currently there is only one type of Policy called "Simple Policy". Other types may be implemented in the future
