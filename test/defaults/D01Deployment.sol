// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./D00GlobalDefaults.sol";

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";

import { INayms } from "src/diamonds/nayms/INayms.sol";
import { Nayms } from "src/diamonds/nayms/Nayms.sol";

import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";
import { LibAdmin } from "src/diamonds/nayms/libs/LibAdmin.sol";
import { LibObject } from "src/diamonds/nayms/libs/LibObject.sol";

import "solmate/utils/CREATE3.sol";

import { LibDeployNayms, NaymsFacetAddresses } from "script/utils/LibDeployNayms.sol";
import { LibNaymsFacetHelpers } from "script/utils/LibNaymsFacetHelpers.sol";

/// @notice Default test setup part 01
///         Deploy and initialize Nayms platform
contract D01Deployment is D00GlobalDefaults {
    InitDiamond public initDiamond;

    Nayms public naymsDiamond;
    INayms public nayms;

    address public naymsPredeterminedAddress;

    //// test constant variables ////
    bytes32 public immutable salt = keccak256(bytes("A salt!"));

    function setUp() public virtual override {
        super.setUp();

        console2.log("\n -- D01 Deployment  \n");

        // deploy the init contract
        initDiamond = new InitDiamond();

        // deploy all facets
        NaymsFacetAddresses memory naymsFacetAddresses = LibDeployNayms.deployNaymsFacets();

        // deterministically deploy Nayms diamond
        console2.log("Deterministic contract address for Nayms", CREATE3.getDeployed(salt));
        naymsPredeterminedAddress = CREATE3.getDeployed(salt);
        vm.label(CREATE3.getDeployed(salt), "Nayms Diamond");

        nayms = INayms(CREATE3.deploy(salt, abi.encodePacked(type(Nayms).creationCode, abi.encode(account0)), 0));

        assertEq(address(nayms), CREATE3.getDeployed(salt));

        // initialize the diamond as well as cut in all facets
        INayms.FacetCut[] memory cut = LibNaymsFacetHelpers.createNaymsDiamondFunctionsCut(naymsFacetAddresses);

        nayms.diamondCut(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));
    }
}
