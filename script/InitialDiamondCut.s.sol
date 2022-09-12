// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Script.sol";

import { INayms } from "src/diamonds/nayms/INayms.sol";

import { LibNaymsFacetHelpers } from "script/utils/LibNaymsFacetHelpers.sol";

interface IInitDiamond {
    function initialize() external;
}

contract InitialDiamondCut is Script {
    address initDiamondAddress = 0xa07580EcE683A6b5e013DF92a22985808d598f6E;
    address naymsDiamondAddress = 0x0340939CDC873A3869e9E280a747F983642A1e3D;

    INayms public nayms = INayms(naymsDiamondAddress);

    address[] public naymsFacetAddresses = [
        0x0A959115a6a2451dE84693B15a637753da26421f, // ACL
        0xE20a522D8dde275eE590598D7A57b6B193d2D511, // NAYMS_ERC20
        0x8422b00d9d61b6319ed73Fa5a079A3e444F5D0cd, // ADMIN
        0x6520664ccb920c6764aeE349dBB41377f033E4B1, // USER
        0xcf3A9D64dC5CD17b8246668FA9a16b5A7eAcc4dd, // SYSTEM
        0x65C0A9652FBE9bD140d421aEc0818F43D10423F5, // TOKENIZED_VAULT
        0xC0F6Ce2D23AD487a29f2654dEdd2bfDd8c8a1b63, // TOKENIZED_VAULT_IO
        0xf6f8F965fB60d7a1B2861fBA266FEe7371770c1f, // MARKET
        0x3aC8B50598fC1B015CfE6D77bdaD82DA653B9Cc5, // ENTITY
        0x55FbeaA15215747fc2d8d9A655d5e1C97Cc8Bf65, // SIMPLE_POLICY
        0xc7bf919d7Fe54C01CBfC15d74360898250D44107, // NDF
        0xd01BfDb0435F726c23e19E6Fcfd7B4AE11420CAf, // SSF
        0x03e13a105D298Cb8BF3De40A337052f83eEF3571  // STAKING
    ];

    IInitDiamond initDiamond = IInitDiamond(initDiamondAddress);

    function run() external {
        vm.startBroadcast();

        // initialize state, add facet methods
        INayms.FacetCut[] memory cut = LibNaymsFacetHelpers.createNaymsDiamondFunctionsCut(naymsFacetAddresses);
        nayms.diamondCut(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));

        vm.stopBroadcast();
    }
}
