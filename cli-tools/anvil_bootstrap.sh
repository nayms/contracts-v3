#!/bin/sh

DIAMOND=$(cat deployedAddresses.json | jq -r '."31337"')
GTOKEN=0xb7F738c0eb4fEe74DBC9D7949EE5497a01F531bd
ACC1=0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f
ACC2=0x4C9f9947491c72C668efAA09e033ffe03C976456
ACC3=0x2328d0d782B9939a982997F2C3F35C2E0f069D86
ACC4=0x9ADCcEb795F3DBffd66B0b2792225269794C2603

make anvil-deploy

make anvil-gtoken

make anvil-add-supported-external-token \
        naymsDiamondAddress=$DIAMOND \
        externalToken=$GTOKEN

# fund acc1
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC1" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --from $ACC1

# fund acc2
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC2" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --from $ACC2

# fund acc3
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC3" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --from $ACC3

# fund acc4
cast send $GTOKEN "mint(address,uint256)" \
        "$ACC4" '1000000000000000000000000' \
        -r http:\\127.0.0.1:8545 \
        --from $ACC4
