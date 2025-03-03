# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Deployment defaults
ownerAddress=0x931c3aC09202650148Edb2316e97815f904CF4fa
systemAdminAddress=0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f

.DEFAULT_GOAL := help

.PHONY: help docs test
help:		## display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# inspiration from Patrick Collins: https://github.com/smartcontractkit/foundry-starter-kit/blob/main/Makefile
# wip (don't use "all" yet)
all: clean update build

clean: ## clean the repo
	forge clean

update: ## update rust, foundry and submodules
	rustup update && foundryup && forge update

formatsol: ## run prettier on src, test and scripts
	yarn run prettier

lintsol: ## run prettier and solhint
	yarn run lint

build: ## forge build
	yarn build
b: build

bscript: ## build forge scripts
	forge build --root . --contracts script/

test: ## forge test local, alias t. Skip "one off" tests, For example a test created for a specific upgrade only. These tests are no longer relevant after the upgrade is complete.
	forge test --no-match-test testFork
t: test

tt: ## forge test local -vv
	forge test -vv

ttt: ## forge test local -vvv
	forge test -vvv
	
tttt: ## forge test local -vvvv
	forge test -vvvv

test-mainnet: ## test forking mainnet with match test regex, i.e. `make test-mainnet MT=testStartTokenSale`
	forge test -f ${ETH_MAINNET_RPC_URL} \
		--fork-block-number 7602168 \
		--mt $(MT) \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		-vvvv
tm:	test-mainnet

gas: ## gas snapshot
	forge snapshot --check

gasforksnap: ## gas snapshot mainnet fork
	forge snapshot --snap .gas-snapshot \
		-f ${ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000
		
gasforkcheck: ## gas check mainnet fork
	forge snapshot --check \
		-f ${ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000 \
		--via-ir

gasforkdiff: ## gas snapshot diff mainnet fork
	forge snapshot --diff \
		-f ${ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000 \
		--via-ir

cov: ## coverage report -vvv
	forge coverage -vvv

coverage: ## coverage report (lcov), filtered for CI
	forge coverage --no-match-test testFork -vvv --report lcov --via-ir && node ./cli-tools/filter-lcov.js

gencov: ## generate html coverage report
	forge coverage --report lcov && genhtml -o cov-html --branch-coverage lcov.info

gencovf: ## generate filtered html coverage report 
	forge coverage --report lcov && node ./cli-tools/filter-lcov.js && genhtml -o cov-html --branch-coverage lcov-filtered.info

# solidity scripts
erc20: ## deploy test ERC20
	forge script DeployERC20 \
		-s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" "Ether" "ETH" 18 \
		-f ${AURORA_TESTNET_RPC_URL} \
        --chain-id 1313161555 \
        --sender 0x931c3aC09202650148Edb2316e97815f904CF4fa \
        --mnemonic-paths ./nayms_mnemonic.txt \
        --mnemonic-indexes 19 \
		-vvvv --broadcast --legacy --verify --delay 30 --retries 10

erc20-mainnet: ## deploy mock ERC20
	forge script DeployERC20 \
		-s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
		${ERC20_NAME} ${ERC20_SYMBOL} ${ERC20_DECIMALS} \
		-f ${ETH_MAINNET_RPC_URL} \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		--verify --delay 30 --retries 10 \
		; node cli-tools/postproc-broadcasts.js

erc20-mainnet-sim: ## simulate deploy mock ERC20
	forge script DeployERC20 \
		-s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
		${ERC20_NAME} ${ERC20_SYMBOL} ${ERC20_DECIMALS} \
		-f ${ETH_MAINNET_RPC_URL} \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		-vv \
		--ffi \
		; node cli-tools/postproc-broadcasts.js

anvil:	## run anvil with shared wallet
	anvil --host 0.0.0.0 --chain-id 31337 --accounts 20 -m "${shell cat ./nayms_mnemonic.txt}" --state anvil.json

anvil-docker:	## run anvil in a container
	docker run --platform linux/amd64 -d \
		-p 8545:8545 \
		--mount src=`pwd`,target=/nayms,type=bind \
		--name anvil \
		ghcr.io/nayms/contracts-builder:latest \
		-c "cd nayms && make anvil"

fork-mainnet: ## fork mainnet locally with anvil
	anvil -f ${ETH_MAINNET_RPC_URL} --accounts 20 -m "${shell cat ./nayms_mnemonic.txt}"

fork-sepolia: ## fork sepolia locally with anvil
	anvil -f ${ETH_SEPOLIA_RPC_URL} --accounts 20 -m "${shell cat ./nayms_mnemonic.txt}"

fork-base: ## fork base locally with anvil
	anvil -f ${BASE_MAINNET_RPC_URL} --accounts 20 -m "${shell cat ./nayms_mnemonic.txt}"

fork-base-sepolia: ## fork base sepolia locally with anvil
	anvil -f ${BASE_SEPOLIA_RPC_URL} --accounts 20 -m "${shell cat ./nayms_mnemonic.txt}"

fork-aurora: ## fork aurora locally with anvil
	anvil -f ${AURORA_MAINNET_RPC_URL} --accounts 20 -m "${shell cat ./nayms_mnemonic.txt}"

fork-aurora-testnet: ## fork aurora testnet locally with anvil
	anvil -f ${AURORA_TESTNET_RPC_URL} --accounts 20 -m "${shell cat ./nayms_mnemonic.txt}"

otterscan: ## run otterscan locally. otterscan is a local block explorer
	docker run --rm -p 5100:80 --name otterscan -d otterscan/otterscan:latest
	
anvil-gtoken:	## deploy dummy erc20 token to local node
	forge script DeployERC20 \
		-s "deploy(string memory, string memory, uint8)" "GToken" "GTK" 18 \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast

anvil-add-supported-external-token: ## Add a supported external token (anvil)
	@forge script AddSupportedExternalToken \
		-s "addSupportedExternalToken(address naymsDiamondAddress, address externalToken, uint256 minimumSell)" ${naymsDiamondAddress} ${externalToken} 10000000000000 \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${systemAdminAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--broadcast

add-supported-external-token: ## Add a supported external token (goerli)
	@forge script AddSupportedExternalToken \
		-s "addSupportedExternalToken(address naymsDiamondAddress, address externalToken, uint256 minimumSell)" ${naymsDiamondAddress} ${externalToken} 10000000000000 \
		-f ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--broadcast

create-entity: ## create an entity on the Nayms platform (using some default values, on anvil)
	forge script CreateEntity \
		-s "createAnEntity(address)" ${naymsDiamondAddress} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--broadcast

slither:	## run slither static analysis
	slither src/generated --config-file=slither.config.json --fail-none

bn-mainnet: ## get block number for mainnet and replace FORK_BLOCK_1 in .env
	@result=$$(cast bn -r mainnet) && \
	sed -i '' "s/^export FORK_BLOCK_1=.*/export FORK_BLOCK_1=$$result/" .env

bn-sepolia: ## get block number for sepolia and replace FORK_BLOCK_11155111 in .env
	@result=$$(cast bn -r sepolia) && \
	sed -i '' "s/^export FORK_BLOCK_11155111=.*/export FORK_BLOCK_11155111=$$result/" .env

tf: ## Toggle forking of tests. true == fork a node, false == no fork
	@result=$$(grep -q 'BOOL_FORK_TEST=true' .env && echo "false" || echo "true"); \
	sed -i '' -e "s/BOOL_FORK_TEST=.*/BOOL_FORK_TEST=$$result/" .env; \
	echo "BOOL_FORK_TEST is now set to $$result"

tu: ## Toggle upgrading the diamond in the forked tests. true == upgrade, false == no upgrade
	@result=$$(grep -q 'TESTS_FORK_UPGRADE_DIAMOND=true' .env && echo "false" || echo "true"); \
	sed -i '' -e "s/TESTS_FORK_UPGRADE_DIAMOND=.*/TESTS_FORK_UPGRADE_DIAMOND=$$result/" .env; \
	echo "TESTS_FORK_UPGRADE_DIAMOND is now set to $$result"

filter-abi:
	@jq '[.[] | select(.name !="facets")]' src/generated/abi.json | \
    jq '[.[] | select(.name !="calculateUpgradeId")]' | \
    jq '[.[] | select(.name !="diamondCut")]' > src/generated/naymsDiamond.json