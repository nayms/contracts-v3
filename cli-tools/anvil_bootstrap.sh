#!/bin/bash

# set -x 

GREEN=$'\e[0;32m'
NC=$'\e[0m'

GTOKEN=0x909677ebf6e09b669dbe01950e9f3ffce7602097
ACC1=0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f
ACC2=0x4C9f9947491c72C668efAA09e033ffe03C976456
ACC3=0x2328d0d782B9939a982997F2C3F35C2E0f069D86
ACC4=0x9ADCcEb795F3DBffd66B0b2792225269794C2603
ACC5=0x946FbF8a719CaEA5909B0f0Ac297384376DfD8AA
ACC_BACKEND=$(cast wallet address $PRIVATE_KEY)
SYSTEM_ID=0x53797374656d0000000000000000000000000000000000000000000000000000

echo
echo " 💎 [ ${GREEN}Deploying the diamond${NC} ]"
echo
yarn build && yarn deploy local --fresh || exit 1

DIAMOND=$(jq -r '.local.contracts[] | select(.name == "DiamondProxy").onChain.address' gemforge.deployments.json)
echo " 💎 Diamond address: $DIAMOND"

echo
echo " 🔐 [ Assigning System Manager: ${GREEN}$ACC2${NC} ]"
echo
cast send $DIAMOND "assignRole(bytes32,bytes32,string)" \
        $(cast 2b $ACC2) $SYSTEM_ID 'System Manager' \
        --rpc-url http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 0 \
        --chain-id 31337 \
        --from $ACC1 || exit 2

echo
echo " 🔏 [ Assigning Onboarding Approver: ${GREEN}$ACC_BACKEND${NC} ]"
echo
cast send $DIAMOND "assignRole(bytes32,bytes32,string)" \
        $(cast 2b $ACC_BACKEND) $SYSTEM_ID 'Onboarding Approver' \
        --rpc-url http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 1 \
        --chain-id 31337 \
        --from $ACC2 || exit 3

echo
echo " 🦋 [ ${GREEN}Deploying GTOKEN${NC} ]"
echo
make anvil-gtoken || exit 4

echo
echo " 🐳 [ ${GREEN}Support GTOKEN${NC}: $GTOKEN ]"
echo
make anvil-add-supported-external-token \
        naymsDiamondAddress=$DIAMOND \
        externalToken=$GTOKEN || exit 5

# fund account 1
echo
echo " 💰 [ Funding ACC1:${GREEN} $ACC1 ${NC} ]"
echo
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC1" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --chain-id 31337 \
        --from $ACC1 || exit 6

# fund account 2
echo
echo " 💰 [ Funding ACC2:${GREEN} $ACC2 ${NC} ]"
echo
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC2" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 1 \
        --chain-id 31337 \
        --from $ACC2 || exit 7

# fund account 3
echo
echo " 💰 [ Funding ACC3:${GREEN} $ACC3 ${NC} ]"
echo
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC3" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 2 \
        --chain-id 31337 \
        --from $ACC3 || exit 8

# fund account 4
echo
echo " 💰 [ Funding ACC4:${GREEN} $ACC4 ${NC} ]"
echo
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC4" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 3 \
        --chain-id 31337 \
        --from $ACC4 || exit 9

# fund account 5
echo
echo " 💰 [ Funding ACC5:${GREEN} $ACC5 ${NC} ]"
echo
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC5" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 4 \
        --chain-id 31337 \
        --from $ACC5 || exit 10

echo
echo " 🦋 [ ${GREEN}Deploying NAYM${NC} ]"
echo

cd ../naym-coin
yarn deploy local --fresh || exit 11

NAYM=$(jq -r '.local.contracts[] | select(.name == "DiamondProxy").onChain.address' gemforge.deployments.json)
echo " 💎 NAYM address: $NAYM"

echo
echo " 🐳 [ ${GREEN}Support NAYM${NC}: $NAYM ]"
echo

cd ../contracts-v3
make anvil-add-supported-external-token \
        naymsDiamondAddress=$DIAMOND \
        externalToken=$NAYM || exit 12

# fund account 5
echo
echo " 💰 [ Minting NAYM to ACC5:${GREEN} $ACC5 ${NC} ]"
echo
cast send $NAYM "mint(address,uint256)" \
        "$ACC5" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --mnemonic-path ./nayms_mnemonic.txt \
        --mnemonic-index 0 \
        --chain-id 31337 \
        --from $ACC1 || exit 13
