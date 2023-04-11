// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable-next-line no-global-import
import "./D00GlobalDefaults.sol";

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";
import { Nayms } from "src/diamonds/nayms/Nayms.sol";
import { INayms } from "src/diamonds/nayms/INayms.sol";
import { LibAdmin } from "src/diamonds/nayms/libs/LibAdmin.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";
import { LibObject } from "src/diamonds/nayms/libs/LibObject.sol";
import { LibSimplePolicy } from "src/diamonds/nayms/libs/LibSimplePolicy.sol";

import { LibGeneratedNaymsFacetHelpers } from "script/utils/LibGeneratedNaymsFacetHelpers.sol";
import { DiamondCutFacet, IDiamondCut } from "src/diamonds/shared/facets/PhasedDiamondCutFacet.sol";

/*
 * D01Deployment (D01Deployment.sol)
 *
 * This file is responsible for setting up the environment for testing by
 * specifying the chain to fork, initializing the forked environment, and
 * deploying necessary contracts or configurations.
 *
 * Key features and responsibilities of this file include:
 *   - Specifying the chain to be forked for testing purposes.
 *   - Initializing the forked environment and setting up necessary connections.
 *   - Deploying contracts or configurations required for testing.
 *
 * The D01Deployment.sol file should focus on preparing the environment for
 * testing, including deployment of relevant contracts and setting up necessary
 * connections to the specified forked chain.
 */

contract D01Deployment is D00GlobalDefaults {
    address public naymsAddress;
    InitDiamond public initDiamond;

    INayms public nayms;

    address public systemAdmin;
    bytes32 public account0Id;

    //// test constant variables ////
    bytes32 public immutable salt = keccak256(bytes("A salt!"));

    function setUp() public virtual override {
        if (block.chainid == 1) {
            vm.createSelectFork("mainnet", 16980067);
            initDiamond = InitDiamond(0x710323646A36edC22473e45aAf91129ae4af961d);
            naymsAddress = 0x03f2a869915984b9BEd52C53eE492668a326BC18;
            nayms = INayms(naymsAddress);

            // vm.startPrank(0xd5c10a9a09B072506C7f062E4f313Af29AdD9904); // nayms deployer - is not system admin

            systemAdmin = 0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f;
            vm.label(systemAdmin, "System Admin");
            account0Id = LibHelpers._getIdForAddress(systemAdmin);
            vm.startPrank(systemAdmin);

            assertTrue(nayms.isInGroup(account0Id, LibAdmin._getSystemId(), LibConstants.GROUP_SYSTEM_ADMINS));

            // console2.log(string(abi.encodePacked('Test setup:  "', account0Id, '" .')));
        }

        if (block.chainid == 31337) {
            // deploy the init contract
            initDiamond = new InitDiamond();

            systemAdmin = address(this);
            vm.label(systemAdmin, "System Admin");

            // deploy all facets
            address[] memory naymsFacetAddresses = LibGeneratedNaymsFacetHelpers.deployNaymsFacets();

            // deterministically deploy Nayms diamond
            nayms = INayms(address(new Nayms(address(this))));

            naymsAddress = address(nayms);

            // initialize the diamond as well as cut in all facets
            INayms.FacetCut[] memory cut = LibGeneratedNaymsFacetHelpers.createNaymsDiamondFunctionsCut(naymsFacetAddresses);

            nayms.diamondCut(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));

            account0Id = LibHelpers._getIdForAddress(address(this));

            // Replace diamondCut() with the two phase diamondCut()
            address phasedDiamondCutFacet = address(new DiamondCutFacet());

            delete cut;

            cut = new IDiamondCut.FacetCut[](1);

            bytes4[] memory f0 = new bytes4[](1);
            f0[0] = IDiamondCut.diamondCut.selector;

            cut[0] = IDiamondCut.FacetCut({ facetAddress: address(phasedDiamondCutFacet), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: f0 });

            // replace the diamondCut()
            nayms.diamondCut(cut, address(0), "");
        }

        super.setUp();
    }

    function scheduleAndUpgradeDiamond(IDiamondCut.FacetCut[] memory cut) internal {
        // 1. schedule upgrade
        // 2. upgrade
        bytes32 upgradeHash = keccak256(abi.encode(cut));
        if (upgradeHash == 0x569e75fc77c1a856f6daaf9e69d8a9566ca34aa47f9133711ce065a571af0cfd) {
            console2.log("There are no facets to upgrade. This hash is the keccak256 hash of an empty IDiamondCut.FacetCut[]");
        } else {
            nayms.createUpgrade(upgradeHash);
            changePrank(deployer);
            nayms.diamondCut(cut, address(0), new bytes(0));
            changePrank(account0);
        }
    }
}
