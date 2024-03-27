# LibConstants
[Git Source](https://github.com/nayms/contracts-v3/blob/0aa70a4d39a9875c02cd43cc38c09012f52d800e/src/libs/LibConstants.sol)

*Settings keys.*


## State Variables
### OBJECT_TYPE_ADDRESS
Object Types


```solidity
bytes12 internal constant OBJECT_TYPE_ADDRESS = "ADDRESS";
```


### OBJECT_TYPE_ENTITY

```solidity
bytes12 internal constant OBJECT_TYPE_ENTITY = "ENTITY";
```


### OBJECT_TYPE_POLICY

```solidity
bytes12 internal constant OBJECT_TYPE_POLICY = "POLICY";
```


### OBJECT_TYPE_FEE

```solidity
bytes12 internal constant OBJECT_TYPE_FEE = "FEE";
```


### OBJECT_TYPE_CLAIM

```solidity
bytes12 internal constant OBJECT_TYPE_CLAIM = "CLAIM";
```


### OBJECT_TYPE_DIVIDEND

```solidity
bytes12 internal constant OBJECT_TYPE_DIVIDEND = "DIVIDEND";
```


### OBJECT_TYPE_PREMIUM

```solidity
bytes12 internal constant OBJECT_TYPE_PREMIUM = "PREMIUM";
```


### OBJECT_TYPE_ROLE

```solidity
bytes12 internal constant OBJECT_TYPE_ROLE = "ROLE";
```


### OBJECT_TYPE_GROUP

```solidity
bytes12 internal constant OBJECT_TYPE_GROUP = "GROUP";
```


### OBJECT_TYPE_STAKED

```solidity
bytes12 internal constant OBJECT_TYPE_STAKED = "VTOK";
```


### EMPTY_IDENTIFIER
Reserved IDs


```solidity
string internal constant EMPTY_IDENTIFIER = "";
```


### SYSTEM_IDENTIFIER

```solidity
string internal constant SYSTEM_IDENTIFIER = "System";
```


### NDF_IDENTIFIER

```solidity
string internal constant NDF_IDENTIFIER = "NDF";
```


### NLF_IDENTIFIER

```solidity
string internal constant NLF_IDENTIFIER = "NLF";
```


### STM_IDENTIFIER

```solidity
string internal constant STM_IDENTIFIER = "Staking Mechanism";
```


### SSF_IDENTIFIER

```solidity
string internal constant SSF_IDENTIFIER = "SSF";
```


### NAYM_TOKEN_IDENTIFIER

```solidity
string internal constant NAYM_TOKEN_IDENTIFIER = "NAYM";
```


### DIVIDEND_BANK_IDENTIFIER

```solidity
string internal constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank";
```


### NAYMS_LTD_IDENTIFIER

```solidity
string internal constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";
```


### ROLE_SYSTEM_ADMIN
Roles


```solidity
string internal constant ROLE_SYSTEM_ADMIN = "System Admin";
```


### ROLE_SYSTEM_MANAGER

```solidity
string internal constant ROLE_SYSTEM_MANAGER = "System Manager";
```


### ROLE_SYSTEM_UNDERWRITER

```solidity
string internal constant ROLE_SYSTEM_UNDERWRITER = "System Underwriter";
```


### ROLE_ENTITY_ADMIN

```solidity
string internal constant ROLE_ENTITY_ADMIN = "Entity Admin";
```


### ROLE_ENTITY_MANAGER

```solidity
string internal constant ROLE_ENTITY_MANAGER = "Entity Manager";
```


### ROLE_ENTITY_BROKER

```solidity
string internal constant ROLE_ENTITY_BROKER = "Broker";
```


### ROLE_ENTITY_INSURED

```solidity
string internal constant ROLE_ENTITY_INSURED = "Insured";
```


### ROLE_ENTITY_CP

```solidity
string internal constant ROLE_ENTITY_CP = "Capital Provider";
```


### ROLE_ENTITY_CONSULTANT

```solidity
string internal constant ROLE_ENTITY_CONSULTANT = "Consultant";
```


### ROLE_ENTITY_TOKEN_HOLDER

```solidity
string internal constant ROLE_ENTITY_TOKEN_HOLDER = "Token Holder";
```


### ROLE_ENTITY_COMPTROLLER_COMBINED

```solidity
string internal constant ROLE_ENTITY_COMPTROLLER_COMBINED = "Comptroller Combined";
```


### ROLE_ENTITY_COMPTROLLER_WITHDRAW

```solidity
string internal constant ROLE_ENTITY_COMPTROLLER_WITHDRAW = "Comptroller Withdraw";
```


### ROLE_ENTITY_COMPTROLLER_CLAIM

```solidity
string internal constant ROLE_ENTITY_COMPTROLLER_CLAIM = "Comptroller Claim";
```


### ROLE_ENTITY_COMPTROLLER_DIVIDEND

```solidity
string internal constant ROLE_ENTITY_COMPTROLLER_DIVIDEND = "Comptroller Dividend";
```


### ROLE_SPONSOR
old roles


```solidity
string internal constant ROLE_SPONSOR = "Sponsor";
```


### ROLE_CAPITAL_PROVIDER

```solidity
string internal constant ROLE_CAPITAL_PROVIDER = "Capital Provider";
```


### ROLE_INSURED_PARTY

```solidity
string internal constant ROLE_INSURED_PARTY = "Insured";
```


### ROLE_BROKER

```solidity
string internal constant ROLE_BROKER = "Broker";
```


### ROLE_SERVICE_PROVIDER

```solidity
string internal constant ROLE_SERVICE_PROVIDER = "Service Provider";
```


### ROLE_UNDERWRITER

```solidity
string internal constant ROLE_UNDERWRITER = "Underwriter";
```


### ROLE_CLAIMS_ADMIN

```solidity
string internal constant ROLE_CLAIMS_ADMIN = "Claims Admin";
```


### ROLE_TRADER

```solidity
string internal constant ROLE_TRADER = "Trader";
```


### ROLE_SEGREGATED_ACCOUNT

```solidity
string internal constant ROLE_SEGREGATED_ACCOUNT = "Segregated Account";
```


### ROLE_ONBOARDING_APPROVER

```solidity
string internal constant ROLE_ONBOARDING_APPROVER = "Onboarding Approver";
```


### GROUP_SYSTEM_ADMINS
Groups


```solidity
string internal constant GROUP_SYSTEM_ADMINS = "System Admins";
```


### GROUP_SYSTEM_MANAGERS

```solidity
string internal constant GROUP_SYSTEM_MANAGERS = "System Managers";
```


### GROUP_SYSTEM_UNDERWRITERS

```solidity
string internal constant GROUP_SYSTEM_UNDERWRITERS = "System Underwriters";
```


### GROUP_TENANTS

```solidity
string internal constant GROUP_TENANTS = "Tenants";
```


### GROUP_MANAGERS

```solidity
string internal constant GROUP_MANAGERS = "Managers";
```


### GROUP_START_TOKEN_SALE

```solidity
string internal constant GROUP_START_TOKEN_SALE = "Start Token Sale";
```


### GROUP_EXECUTE_LIMIT_OFFER

```solidity
string internal constant GROUP_EXECUTE_LIMIT_OFFER = "Execute Limit Offer";
```


### GROUP_CANCEL_OFFER

```solidity
string internal constant GROUP_CANCEL_OFFER = "Cancel Offer";
```


### GROUP_INTERNAL_TRANSFER_FROM_ENTITY

```solidity
string internal constant GROUP_INTERNAL_TRANSFER_FROM_ENTITY = "Internal Transfer From Entity";
```


### GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY

```solidity
string internal constant GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY = "External Withdraw From Entity";
```


### GROUP_EXTERNAL_DEPOSIT

```solidity
string internal constant GROUP_EXTERNAL_DEPOSIT = "External Deposit";
```


### GROUP_PAY_SIMPLE_CLAIM

```solidity
string internal constant GROUP_PAY_SIMPLE_CLAIM = "Pay Simple Claim";
```


### GROUP_PAY_SIMPLE_PREMIUM

```solidity
string internal constant GROUP_PAY_SIMPLE_PREMIUM = "Pay Simple Premium";
```


### GROUP_PAY_DIVIDEND_FROM_ENTITY

```solidity
string internal constant GROUP_PAY_DIVIDEND_FROM_ENTITY = "Pay Dividend From Entity";
```


### GROUP_POLICY_HANDLERS

```solidity
string internal constant GROUP_POLICY_HANDLERS = "Policy Handlers";
```


### GROUP_ENTITY_ADMINS

```solidity
string internal constant GROUP_ENTITY_ADMINS = "Entity Admins";
```


### GROUP_ENTITY_MANAGERS

```solidity
string internal constant GROUP_ENTITY_MANAGERS = "Entity Managers";
```


### GROUP_APPROVED_USERS

```solidity
string internal constant GROUP_APPROVED_USERS = "Approved Users";
```


### GROUP_BROKERS

```solidity
string internal constant GROUP_BROKERS = "Brokers";
```


### GROUP_INSURED_PARTIES

```solidity
string internal constant GROUP_INSURED_PARTIES = "Insured Parties";
```


### GROUP_UNDERWRITERS

```solidity
string internal constant GROUP_UNDERWRITERS = "Underwriters";
```


### GROUP_CAPITAL_PROVIDERS

```solidity
string internal constant GROUP_CAPITAL_PROVIDERS = "Capital Providers";
```


### GROUP_CLAIMS_ADMINS

```solidity
string internal constant GROUP_CLAIMS_ADMINS = "Claims Admins";
```


### GROUP_TRADERS

```solidity
string internal constant GROUP_TRADERS = "Traders";
```


### GROUP_SEGREGATED_ACCOUNTS

```solidity
string internal constant GROUP_SEGREGATED_ACCOUNTS = "Segregated Accounts";
```


### GROUP_SERVICE_PROVIDERS

```solidity
string internal constant GROUP_SERVICE_PROVIDERS = "Service Providers";
```


### GROUP_ONBOARDING_APPROVERS

```solidity
string internal constant GROUP_ONBOARDING_APPROVERS = "Onboarding Approvers";
```


### GROUP_TOKEN_HOLDERS

```solidity
string internal constant GROUP_TOKEN_HOLDERS = "Token Holders";
```


### FEE_TYPE_PREMIUM

```solidity
uint256 internal constant FEE_TYPE_PREMIUM = 1;
```


### FEE_TYPE_TRADING

```solidity
uint256 internal constant FEE_TYPE_TRADING = 2;
```


### FEE_TYPE_INITIAL_SALE

```solidity
uint256 internal constant FEE_TYPE_INITIAL_SALE = 3;
```


### DEFAULT_FEE_SCHEDULE

```solidity
bytes32 internal constant DEFAULT_FEE_SCHEDULE = 0;
```


### OFFER_STATE_ACTIVE

```solidity
uint256 internal constant OFFER_STATE_ACTIVE = 1;
```


### OFFER_STATE_CANCELLED

```solidity
uint256 internal constant OFFER_STATE_CANCELLED = 2;
```


### OFFER_STATE_FULFILLED

```solidity
uint256 internal constant OFFER_STATE_FULFILLED = 3;
```


### DUST

```solidity
uint256 internal constant DUST = 1;
```


### BP_FACTOR

```solidity
uint256 internal constant BP_FACTOR = 10000;
```


### SIMPLE_POLICY_STATE_CREATED

```solidity
uint256 internal constant SIMPLE_POLICY_STATE_CREATED = 0;
```


### SIMPLE_POLICY_STATE_APPROVED

```solidity
uint256 internal constant SIMPLE_POLICY_STATE_APPROVED = 1;
```


### SIMPLE_POLICY_STATE_ACTIVE

```solidity
uint256 internal constant SIMPLE_POLICY_STATE_ACTIVE = 2;
```


### SIMPLE_POLICY_STATE_MATURED

```solidity
uint256 internal constant SIMPLE_POLICY_STATE_MATURED = 3;
```


### SIMPLE_POLICY_STATE_CANCELLED

```solidity
uint256 internal constant SIMPLE_POLICY_STATE_CANCELLED = 4;
```


### STAKING_WEEK

```solidity
uint256 internal constant STAKING_WEEK = 7 days;
```


### STAKING_MINTIME

```solidity
uint256 internal constant STAKING_MINTIME = 60 days;
```


### STAKING_MAXTIME

```solidity
uint256 internal constant STAKING_MAXTIME = 4 * 365 days;
```


### SCALE

```solidity
uint256 internal constant SCALE = 1e18;
```


### STAKING_DEPOSIT_FOR_TYPE
_depositFor Types for events


```solidity
int128 internal constant STAKING_DEPOSIT_FOR_TYPE = 0;
```


### STAKING_CREATE_LOCK_TYPE

```solidity
int128 internal constant STAKING_CREATE_LOCK_TYPE = 1;
```


### STAKING_INCREASE_LOCK_AMOUNT

```solidity
int128 internal constant STAKING_INCREASE_LOCK_AMOUNT = 2;
```


### STAKING_INCREASE_UNLOCK_TIME

```solidity
int128 internal constant STAKING_INCREASE_UNLOCK_TIME = 3;
```


### VE_NAYM_NAME

```solidity
string internal constant VE_NAYM_NAME = "veNAYM";
```


### VE_NAYM_SYMBOL

```solidity
string internal constant VE_NAYM_SYMBOL = "veNAYM";
```


### VE_NAYM_DECIMALS

```solidity
uint8 internal constant VE_NAYM_DECIMALS = 18;
```


### INTERNAL_TOKEN_DECIMALS

```solidity
uint8 internal constant INTERNAL_TOKEN_DECIMALS = 18;
```


### DAI_CONSTANT

```solidity
address internal constant DAI_CONSTANT = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
```


