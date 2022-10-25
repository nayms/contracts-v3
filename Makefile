# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

.DEFAULT_GOAL := help
.PHONY: help
help:		## display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# inspiration from Patrick Collins: https://github.com/smartcontractkit/foundry-starter-kit/blob/main/Makefile
# wip (don't use "all" yet)
all: clean remove install update build

clean: ## clean the repo
	forge clean

update: ## update rust, foundry and submodules
	rustup update && foundryup && forge update

formatsol: ## run prettier on src, test and scripts
	yarn run prettier

lintsol: ## run prettier and solhint
	yarn run lint

devnet: ## run development node
	anvil -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000 \
		-vvvv

gen-i: ## generate solidity interfaces from facet implementations
	forge script GenerateInterfaces \
		-s "run(string memory, string memory)" src/diamonds/nayms/interfaces/ 0.8.13 \
		--ffi

prep-build: ## prepare buld, generate LibGeneratedNaymsFacetHelpers
	node ./cli-tools/prep-build.js 

build: ## forge build
	forge build --names --sizes
b: build

bscript: ## build forge scripts
	forge build --root . --contracts script/

.PHONY: test
test: ## forge test local, alias t
	forge test
t: test

tt: ## forge test local -vv
	forge test -vv

ttt: ## forge test local -vvv
	forge test -vvv
	
tttt: ## forge test local -vvvv
	forge test -vvvv

test-goerli: ## test forking goerli with match test regex, i.e. `make test-goerli MT=testStartTokenSale`
	forge test -f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
		--fork-block-number 7602168 \
		--mt $(MT) \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		-vvvv
tg:	test-goerli

test-mainnet: ## test forking mainnet with match test regex, i.e. `make test-mainnet MT=testStartTokenSale`
	forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
		--fork-block-number 7602168 \
		--mt $(MT) \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		-vvvv
tm:	test-mainnet

gas: ## gas snapshot
	forge snapshot --check

gasforksnap: ## gas snapshot mainnet fork
	forge snapshot --snap .gas-snapshot \
		-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000

gasforkcheck: ## gas check mainnet fork
	forge snapshot --check \
		-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000 \
		--via-ir

gasforkdiff: ## gas snapshot diff mainnet fork
	forge snapshot --diff \
		-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000 \
		--via-ir

cov: ## coverage report -vvv
	forge coverage -vvv

coverage: ## coverage report (lcov), filtered for CI
	forge coverage -vvv --report lcov --via-ir && node ./cli-tools/filter-lcov.js

lcov: ## coverage report (lcov)
	forge coverage --report lcov --via-ir

lcov-fork: ## coverage report (lcov) for mainnet fork
	forge coverage --report lcov \
		-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000 \
		--via-ir

# solidity scripts
erc20: ## deploy test ERC20
	forge script DeployERC20 \
		-s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
		${ERC20_NAME} ${ERC20_SYMBOL} ${ERC20_DECIMALS} \
		-vvvv

# use the "@" to hide the command from your shell 
erc20g: ## deploy test ERC20 to Goerli
	@forge script DeployERC20 -s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
		${ERC20_NAME} ${ERC20_SYMBOL} ${ERC20_DECIMALS} \
		-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--private-key ${PRIVATE_KEY} \
		--broadcast \
		--verify \
		-vvvv

# Deployment defaults
facetsToCutIn="[]"
newDiamond=false
initNewDiamond=false
facetAction=1

deploy: ## smart deploy to goerli
	@forge script SmartDeploy \
		-s "smartDeploy(bool, bool, uint8, string[] memory)" ${newDiamond} ${initNewDiamond} ${facetAction} ${facetsToCutIn} \
		-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast \
		--verify --delay 30 --retries 10

deploy-sim: ## simulate smart deploy to goerli
	forge script SmartDeploy \
		-s "smartDeploy(bool, bool, uint8, string[] memory)" ${newDiamond} ${initNewDiamond} ${facetAction} ${facetsToCutIn} \
		-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi

anvil-fork: ## fork goerli locally with anvil
	anvil -f ${ALCHEMY_ETH_GOERLI_RPC_URL}

deploy-anvil: ## smart deploy locally to anvil
	forge script SmartDeploy \
		-s "smartDeploy(bool, bool, uint8, string[] memory)" \
		${newDiamond} ${initNewDiamond} ${facetAction} ${facetsToCutIn} \
		-f http:\\127.0.0.1:8545 \
		--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast

subgraph: ## generate diamond ABI for the subgraph
	yarn subgraph:abi

.PHONY: docs
docs: ## generate docs from natspec comments
	yarn docgen

slither:	## run slither static analysis
	slither src/diamonds/nayms --exclude solc-version,assembly-usage,naming-convention --ignore-compile
