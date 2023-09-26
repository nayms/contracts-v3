## Nayms Deployer

This documents describe how to use the `deployer` script to make use of the `SmartDeploy` more easily.

Basicaly what `deployer` does is, it automates the interaction with the `SmartDeploy` script for some of the most common use cases.

### Basics

Before starting, make sure you have the `nayms_mnemonic.txt` in the root of the project.

Invoke the deployer script from the project root providing arguments and flags, as shown below:

```zsh
cli-tools/deployer.js [operation] [networkID] [flags]
```

Supported operations are:

- `deploy` - deploy a new diamond
- `upgrade` - upgrade an existing diamond

Supported flags are:

- `--fork` - tells the deployer you are working against a forked node
- `--dry-run` - tells the deployer just to print out the commands it would execut without actually executing them

> Make sure to have environment variables defined for JSON RPC endpoints in this format $ETH\_\<networkID\>\_RPC_URL

### Examples

Here is a couple of examples of some things you might want to do.

#### Mainnet fork upgrade

Let's say you want to try and do an upgrade on mainnet fork, here's how it's done.

First off, you need to fork mainnet locally, this can be done with provided makefile target:

```zsh
make anvil-fork-mainnet
```

Leave this shell active, and in another shell window run:

```zsh
cli-tools/deployer.js upgrade 1 --fork --dry-run
```

This will give you a preview of the commands that it would actually execute, should you ommit the `--dry-run` flag. Bare in mind for this to work you will need to have `$ETH_1_RPC_URL` environment variable defined.

There is also a `anvil-fork-sepolia` makefile target available for convenience.

#### Sepolia upgrade

On `sepolia` we might want to upgrade current deployment (no need to fork):

```zsh
cli-tools/deployer.js upgrade 11155111 --dry-run
```

For this to work you will need to have `$ETH_11155111_RPC_URL` environment variable defined.

#### Full deploy on local node

You want a fresh new deployment of the diamond on you local node. Asumption is we use foundry anvil.

```zsh
cli-tools/deployer.js deploy 31337
```

For this to work you will need to have `$ETH_31337_RPC_URL` environment variable defined as `http:\\127.0.0.1:8545`
