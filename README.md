# Nayms Smart Contracts v3

[![lint](https://github.com/nayms/contracts-v3/actions/workflows/lint.yml/badge.svg)](https://github.com/nayms/contracts-v3/actions/workflows/lint.yml) [![test](https://github.com/nayms/contracts-v3/actions/workflows/test.yml/badge.svg)](https://github.com/nayms/contracts-v3/actions/workflows/test.yml) [![coverage status](https://coveralls.io/repos/github/nayms/contracts-v3/badge.svg?branch=main)](https://coveralls.io/github/nayms/contracts-v3?branch=main) [![license](https://img.shields.io/github/license/nayms/contracts-v3.svg)](https://github.com/nayms/contracts-v3/blob/main/LICENSE)
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

This step is optional, it updates the interfaces to match the facet implementations. Normally you will not need to run it. It is more to be used during development to ensure the interfaces and their respective implementations are aligned. Be aware that when running this target, natspec documentation in the interfaces gets wiped, and it is needed there for the generated markdown files. After running this task take care and ensure the docs are up to date.

```zsh
make gen-i
```

### Prepare the build

```zsh
make prep-build
```

### Build Project

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
├── cli-tools
├── script
│   ├── deployment
│   └── utils
├── src
│   ├── diamonds
│   │   ├── nayms
│   │   │   ├── facets
│   │   │   ├── interfaces
│   │   │   └── libs
│   │   └── shared
│   │       ├── facets
│   │       ├── interfaces
│   │       └── libs
│   ├── erc20
│   └── utils
└── test
    ├── defaults
    ├── fixtures
    └── utils
        └── users
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

Current deployment flow:

Simulate the deployment:

```zsh
make deploy-sim newDiamond=<bool> initNewDiamond=<bool> facetAction=<enum> facetsToCutIn=<string[]> deploymentSalt=<bytes32>
```

|                           |                                                                                                                                                                                                                                                                                                                                                                                                                 |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| _newDiamond_              |                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `true`                    | Deploy a new Nayms diamond                                                                                                                                                                                                                                                                                                                                                                                      |
| `false`                   | Read the address from deployedAddresses.json                                                                                                                                                                                                                                                                                                                                                                    |
|                           |                                                                                                                                                                                                                                                                                                                                                                                                                 |
| _initNewDiamond_          |                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `true`                    | Deploy a new InitDiamond and call `initialize()` when calling `diamondCut()`                                                                                                                                                                                                                                                                                                                                    |
| `false`                   | Does not call `initialize()` when calling `diamondCut()`                                                                                                                                                                                                                                                                                                                                                        |
|                           |                                                                                                                                                                                                                                                                                                                                                                                                                 |
| _facetAction_             | See [`FacetDeploymentAction`](https://github.com/nayms/contracts-v3/tree/main/script/utils/DeploymentHelpers.sol) enum                                                                                                                                                                                                                                                                                          |
| `0`                       | DeployAllFacets                                                                                                                                                                                                                                                                                                                                                                                                 |
| `1`                       | UpgradeFacetsWithChangesOnly                                                                                                                                                                                                                                                                                                                                                                                    |
| `2`                       | UpgradeFacetsListedOnly                                                                                                                                                                                                                                                                                                                                                                                         |
| _facetsToCutIn_           | Requires facetAction=`2`                                                                                                                                                                                                                                                                                                                                                                                        |
| `["Facet1","Facet2",...]` | List of facets to cut into the diamond. For example, facetsToCutIn=`"["ACL", "System"]"` will cut in the ACLFacet and SystemFacet. _Note_: It will remove facet methods that do not exist in the "current" facet, replace methods that exist in both the "current" and "previous" facet, and add methods that only exist in the "current" facet. "Current" is referring to the facet in the current repository. |

Below are several examples on how you would use the smart deploy scripts.

For a __fresh new deployment__ of the entire project, execute this command:

```zsh
make deploy-sim newDiamond=true initNewDiamond=true facetAction=0
```

To __upgrade the facets that have been changed__ since the last deployment, run the following:

```zsh
make deploy-sim newDiamond=false initNewDiamond=false facetAction=1
```

To __upgrade specific set of facets__, run command like this one:

```zsh
make deploy-sim newDiamond=false initNewDiamond=false facetAction=2 facetsToCutIn="["Market","Entity"]"
```

Include a bytes32 salt to deploy the diamond with a deterministic address. Including a salt will first deploy a contract that is used to predetermine the diamond deployment address. If a salt is not included, then the script will deploy the diamond non-deterministically. Currently, there is a default deployment salt given in the make file.

> :warning: Examples above are __dry-run__ probes, to actually do a deploy remove the `-sim` sufix from the target name

### Running a Local Node

For development purposes, you can run a node locally using foundry's `anvil`. It's a simple way to bring up a local node exposing a JSON-RPC endpoint at `http://127.0.0.1:8545`. Make sure to start `anvil` in one of your terminal windows and in another one run a make target to deploy the Nayms' contracts to it.

Following commands are provided for working with `anvil`, to make it more convenient:

| Command | Description |
| ----------- | ----------- |
| `make anvil` | Run the local node seeding it with Nayms' shared wallet |
| `make anvil-debug` | Run Anvil in debug mode to get verbose log output |
| `make anvil-deploy` | Do a full deployment of Nayms' contracts to local node |
| `make anvil-upgrade` | Upgrade deployment of Nayms' contracts on local node |
| `make anvil-gtoken` | Deploy `GToken` to local node |
| `make anvil-add-supported-external-token` | Add `GToken` as supported external token |

> :warning: Anvil state is kept in `anvil.json` file in project root. If this file is not present, node starts fresh and creates this file. In which case you need to do the deployment and setup.

One of the things you will need, to do proper testing with local node, is to deploy an ERC-20 compatible token along with Nayms contracts and make that token a supported external token. Below is aan example how to do that.

```zsh
make anvil-gtoken

make anvil-add-supported-external-token \
        naymsDiamondAddress=0x942757fa0b73257AC3393730dCC59c8Aa15de6f5 \
        externalToken=0x5Dc9485A39f64A5BF0E34904949aF7Cc62EE6Bd7
```

After making a token supported, you might want to mint some coins to a wallet address to make deposits etc. To mint some coins use `cast` tool from Foundry.

```zsh
cast send 0x5Dc9485A39f64A5BF0E34904949aF7Cc62EE6Bd7 "mint(address,uint256)" \
        '0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f' '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --from 0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f
```

Check balance to confirm previous action was successful

```zsh
cast call 0x5Dc9485A39f64A5BF0E34904949aF7Cc62EE6Bd7 "balanceOf(address)(uint256)" \
        '0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f' \
        -r http:\\127.0.0.1:8545
```

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

### Fork testing

Convenience targets are provided in the Makefile for running a specific test against a forked network.

To run a test against a Goerli fork use the following command passing in the test matching expression i.e. `testStartTokenSale`

```zsh
make test-goerli MT=testStartTokenSale
```

Similarly a Mainnet fork test can be executed via:

```zsh
make test-mainnet MT=testStartTokenSale
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
