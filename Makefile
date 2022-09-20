# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# inspiration from Patrick Collins: https://github.com/smartcontractkit/foundry-starter-kit/blob/main/Makefile
# wip (don't use "all" yet)
all: clean remove install update build

# Clean the repo
clean  :; forge clean

# deps
update       :; rustup update && foundryup && forge update
updatey      :; yarn up -R
install_ozv3 :; forge remove ozv3 && git submodule add -b release-v3.4 https://github.com/openzeppelin/openzeppelin-contracts lib/ozv3

# format, lint
formatsol   :; yarn run prettier
lintsol	    :; yarn run lint

# run development node
devnet      :; anvil -f ${ETH_RPC_URL} \
					--fork-block-number 15078000 \
					-vvvv

# forge build
b           :; forge build --names --sizes
build 	    :; forge build --names --sizes
buniswap    :; forge build --root . --contracts lib/v3-core/contracts --remappings @openzeppelin/=lib/ozv3/ && forge build --root . --contracts lib/v3-periphery/contracts --remappings @openzeppelin/=lib/ozv3/
bscript     :; forge build --root . --contracts script/

# forge test local
t           :; forge test
test        :; forge test

tlocal      :; forge t --no-match-contract T03NaymsTokenTest

tlocalgs    :; forge t --no-match-contract T03NaymsTokenTest \
				--gas-report \
				-j

# forge test fork
testfork    :; forge test -f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--gas-report
	
# unique fork tests
tCreatePool :; forge test -f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testWithNaymsTokenCreateLiquidityPool \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				-vvvv -w
tswap		:; forge test -f ${ETH_RPC_URL} \
				--mt testSwapNayms \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				-vvvv -w
tswapf		:; forge test -f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testSwapNayms \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				-vvvv -w
tdiscount	:; forge test -f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testPurchaseDiscountedNAYMFromNDF \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				-vvvv -w
tStaking 	:; forge test -f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testStaking \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				-vvvv -w				
tWithdrawS  :; forge test -f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testWithdrawStakedTokens \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				-vvvv -w
tMarket01   :; forge test -f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testWithFeesSwapEntityTokenToExternalToken \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				-vvvv -w
# gas snapshot
gas				:; forge snapshot --check
gasforksnap     :; forge snapshot --snap .gas-snapshot \
					-f ${ETH_RPC_URL} \
					--fork-block-number 15078000
gasforkcheck    :; forge snapshot --check \
					-f ${ETH_RPC_URL} \
					--fork-block-number 15078000 \
					--via-ir
gasforkdiff     :; forge snapshot --diff \
					-f ${ETH_RPC_URL} \
					--fork-block-number 15078000 \
					--via-ir
# common tests
tv4 		 :; forge test --mt testStaking -vvvv -w

# coverage
cov         :; forge coverage -vvv
coverage    :; forge coverage -vvv --report lcov && node ./cli-tools/filter-lcov.js
lcov        :; forge coverage --report lcov \
				--via-ir
lcovfork    :; forge coverage --report lcov \
				-f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				--via-ir

# solidity scripts
swap        :; @forge script Swap \
				-f ${ETH_RPC_URL} \
				-vvvv


swapc       :; @forge script Swap \
				-f ${ETH_RPC_URL} \
				--fork-block-number 15078000 \
				-vvvv
erc20       :; forge script DeployERC20 \
				-s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
				Test TT 18 \
				-vvvv
# use the "@" to hide the command from your shell 
erc20g      :; @forge script DeployERC20 -s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
				${ERC20_NAME} ${ERC20_SYMBOL} ${ERC20_DECIMALS} \
				-f ${ETH_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--private-key ${PRIVATE_KEY} \
				--broadcast \
				--verify \
				-vvvv

# Deployment
smart-deploy :; forge script SmartDeploy \
				-s "smartDeploy(bool, bool, uint8, string[] memory)" ${newDiamond} ${initNewDiamond} ${facetAction} ${facetsToCutIn} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--chain-id 5 \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv \
				--ffi \
				--broadcast \
				--verify --delay 30 --retries 10

# note:
# pass in 0, 1, 2 for facetAction
# pass in facetsToCutIn as "[]", e.g. "[ACL, Admin]"
smart-deploy-test :; forge script SmartDeploy \
				-s "smartDeploy(bool, bool, uint8, string[] memory)" \
				${newDiamond} ${initNewDiamond} ${facetAction} ${facetsToCutIn} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--chain-id 5 \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv \
				--ffi

deploy-facets-and-cut :; forge script DeployAndUpgradeAllFacets2 \
				-s "deployAndUpgradeAllFacets()" \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--chain-id 5 \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv \
				--ffi


deploy-facets-and-cut-prod :; forge script DeployAndUpgradeAllFacets2 \
				-s "deployAndUpgradeAllFacets()" \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--chain-id 5 \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv \
				--ffi \
				--broadcast \
				--verify --delay 30 --retries 10

deploy-facet-goerli-sim :; @forge script script/deployment/Deploy${contract}.s.sol:Deploy${contract} \
				-s "deploy(bool)" ${upgrade} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--chain-id 5 \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv

deploy-goerli-sim :; @forge script script/deployment/Deploy${contract}.s.sol:Deploy${contract} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv
deploy-mainnet-sim :; @forge script script/deployment/Deploy${contract}.s.sol:Deploy${contract} \
				-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv

deploy-goerli :; @forge script script/deployment/Deploy${contract}.s.sol:Deploy${contract} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				-s "deploy(bool)" ${upgrade} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv \
				--chain-id 5 \
				--broadcast \
				--verify --delay 10 --retries 5

deploy-anvil :;

deploy-goerli-fork :;
deploy-mainnet-fork :;

deploy-nayms-diamond :; @forge script DeployDiamond \
				-s "deploy(bool _create3, bytes32 _salt)" \
				${create3Flag} ${salt} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				-vvvv \
				--chain-id 5 \
				--broadcast \
				--verify --delay 10 --retries 5
	
deployNayms :; @forge script DeployNayms \
				-s "deploy(bytes32 _salt)" \
				${NAYMS_SALT} \
				-f ${ETH_RPC_URL} \
				-vvvv

deployNaymsToLocalNode :; forge script DeployNayms \
				-s "deploy(bytes32 _salt)" 0xff11 \
				-f http://127.0.0.1:8545 \
				--mnemonic-paths test/mnemonic.txt \
				--sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 \
				--broadcast \
				-vvv

deployNaymsToGoerli :; @forge script DeployNayms \
				-s "deploy(bytes32 _salt)" ${NAYMS_SALT} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--chain-id 5 \
				--broadcast \
				--verify --delay 15 --retries 5\
				--slow \
				-vvvv

deployNaymsToSimPROD :; @forge script DeployNayms \
				-s "deploy(bytes32 _salt)" \
				${NAYMS_SALT} \
				-f ${ETH_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				--slow \
				-vvvv

deployNaymsToPROD :; @forge script DeployNayms \
				-s "deploy(bytes32 _salt)" \
				${NAYMS_SALT} \
				-f ${ETH_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				--broadcast \
				--verify \
				--slow \
				-vvvv

deploy-init-diamond :; @forge script DeployInitDiamond \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				--slow \
				-vvvv \
				--broadcast \
				--chain-id 5 \
				--verify --delay 10 --retries 5

deploy-facets :; @forge script DeployFacets \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				--slow \
				-vvvv \
				--chain-id 5  \
				--broadcast \
				--verify --delay 10 --retries 5

deployDiamond :; @forge script DeployDiamond \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				--slow \
				-vvvv \
				--chain-id 5 \
				--broadcast \
				--verify --delay 10 --retries 5
	
initial-diamond-cut :; @forge script InitialDiamondCut \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--etherscan-api-key ${FOUNDRY_ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				--slow \
				-vvvv \
				--chain-id 5 \
				--broadcast

subgraph-abi :; yarn subgraph:abi
