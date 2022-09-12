# Nayms Smart Contracts v3

![tests](https://github.com/nayms/contracts-v3/actions/workflows/tests.yml/badge.svg) ![lint](https://github.com/nayms/contracts-v3/actions/workflows/lint.yml/badge.svg) [![npm version](https://img.shields.io/npm/v/@nayms/contracts/latest.svg)](https://www.npmjs.com/package/@nayms/contracts/v/latest)


This repository contains Nayms V3 smart contracts.

## Get Started  

### Install Foundry

```zsh
curl -L https://foundry.paradigm.xyz | bash
```

#### Update Foundry

```zsh
foundryup
```

### Install Forge dependencies

```zsh
forge update
```

### Update Rust, Foundry, and Forge dependencies

```zsh
make update
```

### Build Project

In order to test the Nayms platform, first build the platforms that Nayms composes with, such as Uniswap v3:

```zsh
make buniswap
```

```zsh
make build
```

### Formatter and Linter

Run `yarn` to install `package.json` which includes our formatter and linter. We will switch over to Foundry's sol formatter and linter once released.  

## Set your environment variables

Check `.env.example` to see some of the environment variables you should have set in `.env` in order to run some of the commands.

## Current Directory Structure

```md
.
├── contracts
│  ├── diamonds
│  │  ├── nayms
│  │  │  ├── facets
│  │  │  ├── interfaces
│  │  │  └── libs
│  │  └── shared
│  │     ├── facets
│  │     ├── interfaces
│  │     └── libs
│  ├── ERC20
│  └── utils
├── docs
│  └── adr
|── lib
├── scripts
├── src
│  └── test
│     └── utils
│        └── users
└── test
```

## Solidity Scripting

You can now write scripts with Solidity.

```zsh
forge script <name of script in script folder>
```

Give a valid Alchemy Eth mainnet API key in `.env` ALCHEMY_ETH_MAINNET_API_KEY, then try running:

```zsh
make swap
```

## Nayms Deployment Flow

1. Create3 Nayms system deployment contract
2. Deploy all facets
3. Deploy Nayms Diamond using create3 Nayms system deployment contract
4. Call the method `diamondCut()` from the Nayms Diamond and cut in facets. Also, in the same call with the 2nd and 3rd parameter on the `diamondCut()` method, pass in the `InitDiamond` contract address with a signed transaction calling the `initialization()` method in `InitDiamond.sol`. See this being done in, for example, `./script/DeployNayms.s.sol`.

Current deployment flow, 2022-08-31:

Run the following:

```zsh
make deploy-nayms-diamond create3=<bool - use create3? true or false> salt=<salt> && make deploy-facets && make deploy-init-diamond && make init-diamond-cut
```

`make deploy-nayms-diamond create3=<bool - use create3? true or false> salt=<salt>`: Runs the script `script/deployment/DeployDiamond.s.sol`. Deploys the Nayms Diamond, and also verifies it on Etherscan. This script also outputs the file `deployedAddresses.json` which includes the output consumed by our backend and frontend to obtain our latest Diamond address. Eventually, this should be consumed from `broadcast/DeployDiamond.s.sol/run-latest.json`.

`make deploy-facets`: Runs the script `script/deployment/DeployFacets.s.sol`. Deploys all of the facets we want to cut into our Nayms Diamond, and also verifies them on Etherscan.

`make deploy-init-diamond`: Runs the script `script/deployment/DeployInitDiamond.s.sol`. Deploys the initialization contract which is used to initialize the state of the Nayms Diamond.

`make init-diamond-cut`: Runs the script `script/InitialDiamondCut.s.sol`. Calls `diamondCut()` to "cut in" (adding in) the methods into the Nayms Diamond. The methods we are cutting in are listed in 'scripts/utils/LibNaymsFacetHelpers.sol`. If a method is not listed there, then it is not being cut in during this step. This script is also calling the `initialize()` method on the InitDiamond contract to initialize the state of the Nayms Diamond. The initial state that is being set can be checked in `src/diamonds/nayms/InitDiamond.sol`.


Deploy a specific contract:

```zsh
make deploy-<NETWORK_NAME> contract=<CONTRACT_NAME>
```

NETWORK_NAME can be:

 - mainnet
 - goerli
 - anvil

## Development Flow

### Run tests using Forge

```zsh
make test
```

We test with mainnet forking.

We have test defaults in `./test/defaults/`. Defaults follow a hierarchy:

#### D00: Global configuration

#### D01: Nayms protocol deployment

#### D02: Testing defaults such as deploying test tokens and giving addresses starting balances

#### D03: Protocol level defaults such as setting Nayms internal IDs

Tests follow a hierarchy:

#### T01: Test defaults, deployment

#### T02: RBAC, Admin functions

#### T03: Token transfer level

T03SystemFacet - test creating entities

#### T04: Business functions

Tests should be fixed in order of the hierarchy (T01 first).


### Output, compare gas snapshots

```zsh
make gas
```
### Build Troubleshooting Tips

In case you run into an issue of `forge` not being able to find a compatible version of solidity compiler for one of your contracts/scripts, you may want to install the solidity version manager `svm`. To be able to do so, you will need to have [Rust](https://www.rust-lang.org/tools/install) installed on your system and with it the acompanying package manager `cargo`. Once that is done, to install `svm` run the following command:

```zsh
cargo install svm-rs
```

To list the available versions of solidity compiler run:

```zsh
svm list
```

Make sure the version you need is in this list, or choose the closest one and install it: 

```zsh
svm install "0.7.6"
```
## Staging for Production Deployment Flow

Run integration tests with mainnet forking.

Ensure "initialization" of entire system.

Use deterministic deployment.

Monitor all events, Nayms Diamond transactions, mempool.

## Production Flow

### Helpful Links

[Louper Diamond Inspector - Etherscan for Diamonds](https://louper.dev/)

### Acknowledgements  

Ramesh Nair @hiddentao

Foundry

Nick Mudge
