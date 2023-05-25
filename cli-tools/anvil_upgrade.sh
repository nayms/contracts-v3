#!/bin/bash

GREEN=$'\e[0;32m'
NC=$'\e[0m'

DIAMOND=$(jq -r '."31337"' deployedAddresses.json)


echo " 🚢 [ ${GREEN}Deploying upgrades${NC} ]"
UPGRADE_HASH=$(make anvil-upgrade | tee /dev/stderr | grep 'upgradeHash: bytes32' | head -n 1 | awk '{print $3}')

echo " ⚓️ [ ${GREEN}Schedule upgrades${NC} ]"
make anvil-schedule upgradeHash=$UPGRADE_HASH || exit 1

echo " 🏄‍♂️ [ ${GREEN}Prepare upgrades${NC} ]"
make prep-upgrade broadcastJson=broadcast/SmartDeploy.s.sol/31337/smartDeploy-latest.json

echo " 💎 [ ${GREEN}Cut the upgrades in${NC} ]"
make anvil-diamond-cut