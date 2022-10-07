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

# helper scripts
gen-i :; forge script GenerateInterfaces \
			-s "run(string memory, string memory)" src/diamonds/nayms/interfaces/ 0.8.13 \
			--ffi

# prepare buld
prep-build :; node ./cli-tools/prep-build.js 

# forge build
b           :; forge build --names --sizes
build 	    :; forge build --names --sizes
buniswap    :; forge build --root . --contracts lib/v3-core/contracts --remappings @openzeppelin/=lib/ozv3/ && forge build --root . --contracts lib/v3-periphery/contracts --remappings @openzeppelin/=lib/ozv3/
bscript     :; forge build --root . --contracts script/

# forge test local
test        :; forge test
t           :; forge test
tt          :; forge test -vv
ttt         :; forge test -vvv
tttt        :; forge test -vvvv

tlocal      :; @forge t --no-match-contract T03NaymsTokenTest --ffi

tlocalgs    :; forge t --no-match-contract T03NaymsTokenTest \
				--gas-report \
				-j \
				--ffi

.PHONY: testGoerli
testGoerli:	# test forking goerli
						forge test -f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
							--fork-block-number 7602168 \
							--mt $(MT) \
							--etherscan-api-key ${ETHERSCAN_API_KEY} \
							-vvvv
tg:	testGoerli

.PHONY: testMainnet
testMainnet:	# test forking mainnet
							forge test -f ${ALCHEMY_ETH_MAINNET_RPC_URL} \
							--fork-block-number 7602168 \
							--mt $(MT) \
							--etherscan-api-key ${ETHERSCAN_API_KEY} \
							-vvvv
tm:	testMainnet

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

# coverage
cov         :; forge coverage -vvv
coverage    :; forge coverage -vvv --report lcov && node ./cli-tools/filter-lcov.js 
lcov        :; forge coverage --report lcov --via-ir
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

smart-deploy :; @forge script SmartDeploy \
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

smart-deploy-sim :; forge script SmartDeploy \
				-s "smartDeploy(bool, bool, uint8, string[] memory)" \
				${newDiamond} ${initNewDiamond} ${facetAction} ${facetsToCutIn} \
				-f ${ALCHEMY_ETH_GOERLI_RPC_URL} \
				--chain-id 5 \
				--etherscan-api-key ${ETHERSCAN_API_KEY} \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vv \
				--ffi

anvil-fork :; anvil -f ${ALCHEMY_ETH_GOERLI_RPC_URL}

smart-deploy-anvil :; forge script SmartDeploy \
				-s "smartDeploy(bool, bool, uint8, string[] memory)" \
				${newDiamond} ${initNewDiamond} ${facetAction} ${facetsToCutIn} \
				-f http:\\127.0.0.1:8545 \
				--sender 0x2b09BfCA423CB4c8E688eE223Ab00a9a0092D271 \
				--mnemonic-paths ./nayms_mnemonic.txt \
				--mnemonic-indexes 0 \
				-vv \
				--ffi \
				--broadcast


subgraph-abi :; yarn subgraph:abi

doc :; yarn docgen
