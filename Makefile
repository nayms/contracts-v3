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
devnet      :; anvil -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
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

tlocal      :; forge t --no-match-contract T03NaymsTokenTest --ffi

tlocalgs    :; forge t --no-match-contract T03NaymsTokenTest \
				--gas-report \
				-j \
				--ffi

# forge test fork
testfork    :; forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				--gas-report
	
# unique fork tests
tCreatePool :; forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testWithNaymsTokenCreateLiquidityPool \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				-vvvv -w
tswap		:; forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--mt testSwapNayms \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				-vvvv -w
tswapf		:; forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testSwapNayms \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				-vvvv -w
tdiscount	:; forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testPurchaseDiscountedNAYMFromNDF \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				-vvvv -w
tStaking 	:; forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testStaking \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				-vvvv -w				
tWithdrawS  :; forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testWithdrawStakedTokens \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				-vvvv -w
tMarket01   :; forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				--mt testWithFeesSwapEntityTokenToExternalToken \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				-vvvv -w
# gas snapshot
gas				:; forge snapshot --check
gasforksnap     :; forge snapshot --snap .gas-snapshot \
					-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
					--fork-block-number 15078000
gasforkcheck    :; forge snapshot --check \
					-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
					--fork-block-number 15078000 \
					--via-ir
gasforkdiff     :; forge snapshot --diff \
					-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
					--fork-block-number 15078000 \
					--via-ir
# common tests
tv4 		 :; forge test --mt testStaking -vvvv -w

# coverage
cov         :; forge coverage -vvv --ffi
coverage    :; forge coverage -vvv --report lcov --ffi && node ./cli-tools/filter-lcov.js 
lcov        :; forge coverage --report lcov \
				--via-ir
lcovfork    :; forge coverage --report lcov \
				-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				--via-ir

# solidity scripts
swap        :; @forge script Swap \
				-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				-vvvv


swapc       :; @forge script Swap \
				-f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
				--fork-block-number 15078000 \
				-vvvv
erc20       :; forge script DeployERC20 \
				-s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
				Test TT 18 \
				-vvvv
# use the "@" to hide the command from your shell 
erc20g      :; @forge script DeployERC20 -s "deploy(string memory _name, string memory _symbol, uint8 _decimals)" \
				${ERC20_NAME} ${ERC20_SYMBOL} ${ERC20_DECIMALS} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				--private-key ${PRIVATE_KEY} \
				--broadcast \
				--verify \
				-vvvv

# Deployment

# note:
# pass in 0, 1, 2 for facetAction
# pass in facetsToCutIn as "[]", e.g. "[ACL, Admin]"
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

smart-deploy-sim :; forge script SmartDeploy \
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

anvil-fork :; anvil -f ${ALCHEMY_ETH_GOERLI_RPC_URL}

smart-deploy-anvil :; forge script SmartDeploy \
				-s "smartDeploy(bool, bool, uint8, string[] memory)" \
				${newDiamond} ${initNewDiamond} ${facetAction} ${facetsToCutIn} \
				-f http:\\127.0.0.1:8545 \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vvvv \
				--ffi \
				--broadcast


deploy-goerli-fork :;
deploy-mainnet-fork :;

subgraph-abi :; yarn subgraph:abi
