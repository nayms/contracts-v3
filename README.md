# Nayms Smart Contracts v3

[![lint](https://github.com/nayms/contracts-v3/actions/workflows/lint.yml/badge.svg)](https://github.com/nayms/contracts-v3/actions/workflows/lint.yml) [![tests](https://github.com/nayms/contracts-v3/actions/workflows/tests.yml/badge.svg)](https://github.com/nayms/contracts-v3/actions/workflows/tests.yml) [![coverage status](https://coveralls.io/repos/github/nayms/contracts-v3/badge.svg?branch=main)](https://coveralls.io/github/nayms/contracts-v3?branch=main) [![license](https://img.shields.io/github/license/nayms/contracts-v3.svg)](https://github.com/nayms/contracts-v3/blob/main/LICENSE)
 [![npm version](https://img.shields.io/npm/v/@nayms/contracts/latest.svg)](https://www.npmjs.com/package/@nayms/contracts/v/latest)

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

### Generate Interfaces

```zsh
make gen-i
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

Current deployment flow, 2022-09-21:

Simulate the deployment:

```zsh
make smart-deploy-sim newDiamond=<bool> initNewDiamond=<bool> facetAction=<enum> facetsToCutIn=<string[]>
```

newDiamond -  `true`: Deploy a new Nayms diamond.
             `false`: Read the address from deployedAddresses.json.

initNewDiamond -  `true`: Deploy a new InitDiamond and call `initialize()` when calling `diamondCut()`.
                 `false`: Does not call `initialize()` when calling `diamondCut()`.
                 
facetAction - Check the enum `FacetDeploymentAction` in `script/utils/DeploymentHelpers.sol`.
              `0`: DeployAllFacets
              `1`: UpgradeFacetsWithChangesOnly
              `2`: UpgradeFacetsListedOnly
              
facetsToCutIn - If facetAction=`2`, then the script will deploy and cut in the methods from the names of the facets listed from this parameter. For example, facetsToCutIn=`"["ACL", "System"]"` will cut in the ACLFacet and SystemFacet. Note: It will remove facet methods that do not exist in the "current" facet, replace methods that exist in both the "current" and "previous" facet, and add methods that only exist in the "current" facet. "Current" is referring to the facet in the current repository.

## Development Flow

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
