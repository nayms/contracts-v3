# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Deployment defaults
facetsToCutIn="[]"
newDiamond=false
initNewDiamond=false
facetAction=1		# 0 - all, 1 - changed, 2 - listed
deploymentSalt=0xdeffffffff
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

gen-i: ## generate solidity interfaces from facet implementations
	forge script GenerateInterfaces \
		-s "run(string memory, string memory)" src/diamonds/nayms/interfaces/ 0.8.13 \
		--ffi

prep-build: ## prepare buld, generate LibGeneratedNaymsFacetHelpers. This excludes ACL and Governance facets, which are deployed with the Nayms diamond.
	node ./cli-tools/prep-build.js ACL Governance

prep-build-all: ## prepare buld, generate LibGeneratedNaymsFacetHelpers. This includes all facets in the src/diamonds/nayms/facets folder.
	node ./cli-tools/prep-build.js

prep-upgrade: ## Generate upgrade script S03UpgradeDiamond.s.sol with cut information from broadcast json file. Pass in e.g. broadcastJson=broadcast/S01DeployContract.s.sol/31337/run-latest.json
	node ./cli-tools/prep-upgrade.js ${broadcastJson}

build: ## forge build
	forge build --names --sizes
b: build

bscript: ## build forge scripts
	forge build --root . --contracts script/

test: ## forge test local, alias t. Skip "one off" tests, For example a test created for a specific upgrade only. These tests are no longer relevant after the upgrade is complete.
	forge test --no-match-test testReplaceDiamondCut
t: test

tt: ## forge test local -vv
	forge test -vv

ttt: ## forge test local -vvv
	forge test -vvv
	
tttt: ## forge test local -vvvv
	forge test -vvvv

test-goerli: ## test forking goerli with match test regex, i.e. `make test-goerli MT=testStartTokenSale`
	forge test -f ${ETH_GOERLI_RPC_URL} \
		--fork-block-number 7602168 \
		--mt $(MT) \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		-vvvv
tg:	test-goerli

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
	forge coverage -vvv --report lcov --via-ir && node ./cli-tools/filter-lcov.js

lcov: ## coverage report (lcov)
	forge coverage --report lcov --via-ir

lcov-fork: ## coverage report (lcov) for mainnet fork
	forge coverage --report lcov \
		-f ${ETH_MAINNET_RPC_URL} \
		--fork-block-number 15078000 \
		--via-ir

# solidity scripts
erc20: ## deploy test ERC20
	forge script DeployERC20 \
		-s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
		${ERC20_NAME} ${ERC20_SYMBOL} ${ERC20_DECIMALS} \
		-vvvv

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

# use the "@" to hide the command from your shell 
erc20g: ## deploy test ERC20 to Goerli
	@forge script DeployERC20 -s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
		${ERC20_NAME} ${ERC20_SYMBOL} ${ERC20_DECIMALS} \
		-f ${ETH_GOERLI_RPC_URL} \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		--broadcast \
		--verify \
		-vvvv

schedule-upgrade-goerli: ## schedule upgrade to goerli diamond, then upgrade
	@forge script SmartDeploy \
		-s "scheduleAndUpgradeDiamond()" \
		-f ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		--private-key ${OWNER_ACCOUNT_KEY} \
		-vv \
		--ffi \
		--broadcast \
		--verify --delay 30 --retries 10 \
		; node cli-tools/postproc-broadcasts.js

deploy-goerli: ## smart deploy to goerli
	@forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		-f ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		--verify --delay 30 --retries 10 \
		; node cli-tools/postproc-broadcasts.js

deploy-goerli-sim: ## simulate smart deploy to goerli
	forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		-f ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		-vv \
		--ffi

deploy-sepolia: ## smart deploy to sepolia
	@forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		-f ${ETH_SEPOLIA_RPC_URL} \
		--chain-id 11155111 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		--verify --delay 30 --retries 10 \
		; node cli-tools/postproc-broadcasts.js

deploy-sepolia-fork: ## smart deploy to local sepolia fork
	@forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 11155111 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		; node cli-tools/postproc-broadcasts.js

deploy-sepolia-sim: ## simulate smart deploy to sepolia
	forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		-f ${ETH_SEPOLIA_RPC_URL} \
		--chain-id 11155111 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		-vv \
		--ffi

deploy-mainnet: ## smart deploy to mainnet
	@forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		-f ${ETH_MAINNET_RPC_URL} \
		--chain-id 1 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		--slow \
		--verify --delay 30 --retries 10 \
		; node cli-tools/postproc-broadcasts.js

deploy-mainnet-sim: ## simulate deploy to mainnet
	@forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		-f ${ETH_MAINNET_RPC_URL} \
		--chain-id 1 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		-vv \
		--ffi 

deploy-mainnet-fork: ## smart deploy to local mainnet fork
	@forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 1 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		--slow \
		; node cli-tools/postproc-broadcasts.js

deploy-contract: ## deploy any contract to mainnet
	forge script S01DeployContract \
		-s "run(string calldata)" ${contractName} \
		-f ${ETH_MAINNET_RPC_URL} \
		--chain-id 1 \
		--sender ${senderAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast \
		--verify --delay 30 --retries 10 \
		; node cli-tools/postproc-broadcasts.js

deploy-contract-sepolia: ## deploy any contract to Sepolia
	forge script S01DeployContract \
		-s "run(string calldata)" ${contractName} \
		-f ${ETH_SEPOLIA_RPC_URL} \
		--chain-id 1 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		--verify --delay 30 --retries 10 \
		; node cli-tools/postproc-broadcasts.js

schedule-upgrade-mainnet: ## schedule upgrade on mainnet
	forge script S02ScheduleUpgrade \
		-s "run(address, bytes32)" ${systemAdminAddress} ${upgradeHash} \
		-f ${ETH_MAINNET_RPC_URL} \
		--chain-id 1 \
		--sender ${systemAdminAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast \
		; node cli-tools/postproc-broadcasts.js

schedule-upgrade-mainnet-fork:	## schedule upgrade on local mainnet fork (with NaymsAdminB)
	cast rpc anvil_impersonateAccount 0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929 && \
	cast send 0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5 "createUpgrade(bytes32)" \
  	'${upgradeHash}' \
  	--rpc-url http:\\127.0.0.1:8545 \
  	--unlocked \
  	--from 0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929

schedule-upgrade-sepolia: ## schedule upgrade on sepolia
	forge script S02ScheduleUpgrade \
		-s "run(address, bytes32)" ${systemAdminAddress} ${upgradeHash} \
		-f ${ETH_SEPOLIA_RPC_URL} \
		--chain-id 11155111 \
		--sender ${systemAdminAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast \
		; node cli-tools/postproc-broadcasts.js

schedule-upgrade-sepolia-fork: ## schedule upgrade on local sepolia fork
	forge script S02ScheduleUpgrade \
		-s "run(address, bytes32)" ${systemAdminAddress} ${upgradeHash} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 11155111 \
		--sender ${systemAdminAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast \
		; node cli-tools/postproc-broadcasts.js

diamond-cut: ## replace a facet
	forge script S03UpgradeDiamond \
		-s "run(address)" ${ownerAddress} \
		-f ${ETH_MAINNET_RPC_URL} \
		--chain-id 1 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast \
		; node cli-tools/postproc-broadcasts.js

diamond-cut-sepolia: ## replace a facet on sepolia
	forge script S03UpgradeDiamond \
		-s "run(address)" ${ownerAddress} \
		-f ${ETH_SEPOLIA_RPC_URL} \
		--chain-id 11155111 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		; node cli-tools/postproc-broadcasts.js

diamond-cut-sepolia-fork: ## replace a facet on local sepolia fork
	forge script S03UpgradeDiamond \
		-s "run(address)" ${ownerAddress} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 11155111 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		; node cli-tools/postproc-broadcasts.js

anvil:	## run anvil with shared wallet
	anvil --host 0.0.0.0 --chain-id 31337 --accounts 20 -m ./nayms_mnemonic.txt --state anvil.json

anvil-docker:	## run anvil in a container
	docker run -d \
		-p 8545:8545 \
		--mount src=`pwd`,target=/nayms,type=bind \
		--name anvil \
		ghcr.io/nayms/contracts-builder:latest \
		-c "cd nayms && make anvil"

anvil-dbg:	## run anvil in debug mode with shared wallet
	RUST_LOG=backend,api,node,rpc=warn anvil --host 0.0.0.0 --chain-id 31337 -m ./nayms_mnemonic.txt  --state anvil.json

anvil-fork-mainnet: ## fork mainnet locally with anvil
	anvil -f ${ETH_MAINNET_RPC_URL}

anvil-fork-sepolia: ## fork sepolia locally with anvil
	anvil -f ${ETH_SEPOLIA_RPC_URL}

anvil-deploy-sim: ## Simulate smart deploy locally to anvil
	forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" true ${ownerAddress} ${systemAdminAddress} true 0 ${facetsToCutIn} ${deploymentSalt} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		-vv \
		--ffi

anvil-deploy-diamond: ## smart deploy locally to anvil
	forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" true ${ownerAddress} ${systemAdminAddress} false 2 ${facetsToCutIn} ${deploymentSalt} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast

anvil-upgrade-init-sim: ## Anvil - simulate upgrading a diamond WITH InitDiamond to obtain the upgrade hash
	forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" false ${ownerAddress} ${systemAdminAddress} true 1 ${facetsToCutIn} ${deploymentSalt} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		-vv \
		--ffi

anvil-upgrade-init: ## Anvil - upgrading a diamond WITH InitDiamond
	forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" false ${ownerAddress} ${systemAdminAddress} true 1 ${facetsToCutIn} ${deploymentSalt} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast

anvil-deploy-contract: ## deploy contract to anvil
	forge script S01DeployContract \
		-s "run(string calldata)" ${contractName} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${senderAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast
	
anvil-upgrade-sim: ## smart deploy locally to anvil
	forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" false ${ownerAddress} ${systemAdminAddress} false 1 ${facetsToCutIn} ${deploymentSalt} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		-vv \
		--ffi

anvil-upgrade: ## smart deploy locally to anvil
	forge script SmartDeploy \
		-s "smartDeploy(bool, address, address, bool, uint8, string[] memory, bytes32)" false ${ownerAddress} ${systemAdminAddress} false 1 ${facetsToCutIn} ${deploymentSalt} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast

anvil-schedule:	## schedule an upgrade
	forge script SmartDeploy \
		-s "schedule(bytes32)" ${upgradeHash} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${systemAdminAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--ffi \
		--broadcast

anvil-diamond-cut: ## replace a facet
	forge script S03UpgradeDiamond \
		-s "run(address)" ${ownerAddress} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast

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
		-s "addSupportedExternalToken(address naymsDiamondAddress, address externalToken)" ${naymsDiamondAddress} ${externalToken} \
		-f http:\\127.0.0.1:8545 \
		--chain-id 31337 \
		--sender ${systemAdminAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 0 \
		-vv \
		--broadcast

goerli-replace-ownership: ## Replace transferOwnership()
	forge script ReplaceOwnershipFacet \
		-f ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--ffi \
		--broadcast \
		--verify --delay 30 --retries 10

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

add-supported-external-token: ## Add a supported external token (goerli)
	@forge script AddSupportedExternalToken \
		-s "addSupportedExternalToken(address naymsDiamondAddress, address externalToken)" ${naymsDiamondAddress} ${externalToken} \
		-f ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--broadcast

update-commissions: ## update trading and premium commissions
	forge script UpdateCommissions \
		-s "tradingAndPremium(address)" ${naymsDiamondAddress} \
		-f ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vv \
		--broadcast

subgraph: ## generate diamond ABI for the subgraph
	yarn subgraph:abi

docs: ## generate docs from natspec comments
	yarn docgen

slither:	## run slither static analysis
	slither src/diamonds/nayms --exclude solc-version,assembly-usage,naming-convention,low-level-calls --ignore-compile

upgrade-hash-sepolia: ## generate SEPOLIA upgrade hash
	@forge script SmartDeploy \
		-s "hash(bool, address, address, bool, uint8, string[] memory, bytes32)" false ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} 1 "[]" ${deploymentSalt} \
		--fork-url ${ETH_SEPOLIA_RPC_URL} \
		--chain-id 11155111 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--ffi \
		--silent \
		&& jq --raw-output '.returns.upgradeHash.value, .returns.cut.value' broadcast/SmartDeploy.s.sol/11155111/dry-run/hash-latest.json || echo "Not Available"

upgrade-hash-goerli: ## generate GOERLI upgrade hash
	@forge script SmartDeploy \
		-s "hash(bool, address, address, bool, uint8, string[] memory, bytes32)" false ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} 1 "[]" ${deploymentSalt} \
		--fork-url ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--ffi \
		--silent \
		&& jq --raw-output '.returns.upgradeHash.value, .returns.cut.value' broadcast/SmartDeploy.s.sol/5/dry-run/hash-latest.json

upgrade-hash-mainnet: ## generate MAINNET upgrade hash
	@forge script SmartDeploy \
		-s "hash(bool, address, address, bool, uint8, string[] memory, bytes32)" false ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} 1 "[]" ${deploymentSalt} \
		--fork-url ${ETH_MAINNET_RPC_URL} \
		--chain-id 1 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		--etherscan-api-key ${ETHERSCAN_API_KEY} \
		--ffi \
		--silent \
		&& jq --raw-output '.returns.upgradeHash.value, .returns.cut.value' broadcast/SmartDeploy.s.sol/1/dry-run/hash-latest.json

upgrade-hash-anvil: ## generate ANVIL upgrade hash
	forge script SmartDeploy \
		-s "hash(bool, address, address, bool, uint8, string[] memory, bytes32)" ${newDiamond} ${ownerAddress} ${systemAdminAddress} ${initNewDiamond} ${facetAction} ${facetsToCutIn} ${deploymentSalt} \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		--ffi

verify-dry-run:	## dry run verify script, prints out commands to be executed
	node cli-tools/verify.js --dry-run

verify:	## verify contracts on chain (goerli)
	node cli-tools/verify.js

update-e: ## update
	forge script UpdateEntity \
		-f ${ETH_GOERLI_RPC_URL} \
		--chain-id 5 \
		--sender ${ownerAddress} \
		--mnemonic-paths ./nayms_mnemonic.txt \
		--mnemonic-indexes 19 \
		-vvvv \
		--broadcast