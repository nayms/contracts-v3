#!/bin/bash

GREEN=$'\e[0;32m'
NC=$'\e[0m'

GTOKEN=0x909677ebf6e09b669dbe01950e9f3ffce7602097
ACC1=0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f
ACC2=0x4C9f9947491c72C668efAA09e033ffe03C976456
ACC3=0x2328d0d782B9939a982997F2C3F35C2E0f069D86
ACC4=0x9ADCcEb795F3DBffd66B0b2792225269794C2603
ACC5=0x946FbF8a719CaEA5909B0f0Ac297384376DfD8AA

echo " 💎 [ ${GREEN}Deploying the diamond${NC} ]"
yarn build && yarn deploy local --fresh || exit 1

DIAMOND=$(jq '.local.contracts[] | select(.name == "DiamondProxy").onChain.address' gemforge.deployments.json)
echo " 💎 Diamond address: $DIAMOND"

echo " 🦋 [ ${GREEN}Deploying GTOKEN${NC} ]"
make anvil-gtoken || exit 5

echo " 🐳 [ ${GREEN}Support GTOKEN${NC}: $GTOKEN ]"
make anvil-add-supported-external-token \
        naymsDiamondAddress=$DIAMOND \
        externalToken=$GTOKEN || exit 6

# fund account 1
echo " 💰 [ Funding ACC1: ${GREEN}$ACC1${NC} ]"
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC1" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --chain-id 31337 \
        --from $ACC1

# fund account 2
echo " 💰 [ Funding ACC2: ${GREEN}$ACC2${NC} ]"
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC2" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 1 \
        --chain-id 31337 \
        --from $ACC2

# fund account 3
echo " 💰 [ Funding ACC3: ${GREEN}$ACC3${NC} ]"
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC3" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 2 \
        --chain-id 31337 \
        --from $ACC3

# fund account 4
echo " 💰 [ Funding ACC4: ${GREEN}$ACC4${NC} ]"
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC4" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 3 \
        --chain-id 31337 \
        --from $ACC4

# fund account 5
echo " 💰 [ Funding ACC5: ${GREEN}$ACC5${NC} ]"
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC5" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 4 \
        --chain-id 31337 \
        --from $ACC5

echo  " ✨ [ ${GREEN}Done${NC} ]"
