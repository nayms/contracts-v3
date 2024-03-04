# Nayms Smart Contracts v3

[![lint](https://github.com/nayms/contracts-v3/actions/workflows/lint.yml/badge.svg)](https://github.com/nayms/contracts-v3/actions/workflows/lint.yml) [![test](https://github.com/nayms/contracts-v3/actions/workflows/test.yml/badge.svg)](https://github.com/nayms/contracts-v3/actions/workflows/test.yml) [![coverage status](https://coveralls.io/repos/github/nayms/contracts-v3/badge.svg?branch=main)](https://coveralls.io/github/nayms/contracts-v3?branch=main) [![license](https://img.shields.io/github/license/nayms/contracts-v3.svg)](https://github.com/nayms/contracts-v3/blob/main/LICENSE)
[![npm version](https://img.shields.io/npm/v/@nayms/contracts/latest.svg)](https://www.npmjs.com/package/@nayms/contracts/v/latest)

This repository contains Nayms V3 smart contracts.

This is a [Foundry](https://book.getfoundry.sh/) based project, so make sure you have it installed.

### Set up your project configuration

Check `.env.example` to see some of the environment variables you should have set in `.env` in order to run some of the commands.

Create a `.env` and ensure it contains:

```
LOCAL_RPC_URL=
ETH_MAINNET_RPC_URL=
ETH_GOERLI_RPC_URL=
ETH_SEPOLIA_RPC_URL=
ETHERSCAN_API_KEY=
```

Create a `nayms_mnemonic.txt` file and ensure it contains the team mnemonic.

### Build Project

```zsh
make build
```
This will generate the diamond proxy interface, diamond helper library and the abi file.

### Test Project

```zsh
make test
```

### Deploy the diamond

Smart contracts in this repository implement the [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535) a.k.a. the diamond standard and use [Gemforge](https://gemforge.xyz/) for deployment. You can read more about it in the official docs.

A script - `script/gemforge/deploy.js` - is provided as a convenience for handling the Nayms phased deployments flow. You can call this directly or just use `yarn deploy ...`

Currently supported deployment targets are:

- `local`: Local Anvil Node
- `sepolia`: Sepolia
- `mainnet`: Mainnet
- `base`: Base
- `baseGoerli`: Base Goerli testnet
- `sepoliaFork`: a local fork of Sepolia
- `mainnetFork`: a local for of Mainnet

#### Querying

To see how the current deployed Diamond differs from the compiled code for a target:

```
yarn query <target>
```

#### Fresh deployments

To do a fresh deployment to a given [target](https://gemforge.xyz/configuration/targets/):

```
yarn deploy <target> --fresh
```

#### Upgrades

To upgrade a deployment on a target:

```
yarn deploy <target> --upgrade-start
yarn deploy <target> --upgrade-finish
```

_Note: For mainnet you will need to enable the upgrade using the MPC wallet. For non-mainnet targets the script will automatically do this for you._

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
| `make fork-sepolia`| Fork `Sepolia` test net locally |
| `make fork-base-sepolia`| Fork `Base Sepolia` test net locally |
| `make fork-mainnet`| Fork `Mainnet` locally |
| `make fork-base`| Fork `Base` locally |

> :warning: Anvil state is kept in `anvil.json` file in project root, except for forks. If this file is not present, node starts fresh and creates this file. In which case you need to do the deployment and setup.

One of the things you will need, to do proper testing with local node, is to deploy an ERC-20 compatible token along with Nayms contracts and make that token a supported external token. Below is an example of how to do that.

#### Bootstrapping a local node

When working with local node, there are a few things you might need to do in preparation to be able to actually use it with client applications. As a convenience, a script is provided automating the following tasks.

- Deploy the diamond to local node
- Deploy test ERC20 compatible token (`GTOKEN`) to local node
- Make this token a supported external token
- Mint some tokens to `acc1`, `acc2`, `acc3` and `acc4` from the `nayms_mnemonic.txt`

Run it from project root folder against fresh new local node instance, otherwise some steps might fail:

```zsh
cli-tools/anvil_bootstrap.sh
```

### Output, compare gas snapshots

```zsh
make gas
```

### Build Troubleshooting Tips

In case you run into an issue of `forge` not being able to find a compatible version of solidity compiler for one of your contracts/scripts, you may want to install the solidity version manager `svm`. To be able to do so, you will need to have [Rust](https://www.rust-lang.org/tools/install) installed on your system and with it the accompanying package manager `cargo`. Once that is done, to install `svm` run the following command:

```zsh
cargo install svm-rs
```

To list the available versions of solidity compiler run:

```zsh
svm list
```

Make sure the version you need is in this list, or choose the closest one and install it:

```zsh
svm install "0.8.20"
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
