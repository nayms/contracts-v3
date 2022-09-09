// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice This script is to deploy and initialize the entire Nayms protocol.

import "forge-std/Script.sol";

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";

import { INayms } from "src/diamonds/nayms/INayms.sol";
import { Nayms } from "src/diamonds/nayms/Nayms.sol";

import { Create3Deployer } from "src/utils/Create3Deployer.sol";

import { LibDeployNayms, NaymsFacetAddresses } from "script/utils/LibDeployNayms.sol";
import { LibNaymsFacetHelpers } from "script/utils/LibNaymsFacetHelpers.sol";

contract DeployNayms is Script {
    InitDiamond public initDiamond;

    INayms public nayms;

    struct DeploymentInfo {
        bytes32 salt01;
        address initDiamond;
        address naymsDiamond;
    }

    function deploy(bytes32 _salt) external returns (DeploymentInfo memory deploymentInfo) {
        console2.log("Script's contract address", address(this));

        // set sender address to Nayms account1
        vm.startBroadcast();
        console2.log("msg.sender during broadcast", msg.sender);
        console2.log("msg.sender's coin balance", address(msg.sender).balance);

        // deploy a contract with a method you can delegatecall to set the initial state variable values.
        initDiamond = new InitDiamond();
        deploymentInfo.initDiamond = address(initDiamond);

        // deploy all facets
        NaymsFacetAddresses memory naymsFacetAddresses = LibDeployNayms.deployNaymsFacets();

        Create3Deployer c3Deployer = new Create3Deployer();

        // deploy Nayms diamond
        deploymentInfo.salt01 = _salt;
        console2.log("Deterministic contract address for Nayms", c3Deployer.getDeployed(deploymentInfo.salt01));
        deploymentInfo.naymsDiamond = c3Deployer.getDeployed(deploymentInfo.salt01);

        nayms = INayms(c3Deployer.deployContract(deploymentInfo.salt01, abi.encodePacked(type(Nayms).creationCode, abi.encode(address(msg.sender))), 0));

        require(deploymentInfo.naymsDiamond == address(nayms), "deterministic address and actual deployed address don't match");

        // initialize state, add facet methods
        INayms.FacetCut[] memory cut = LibNaymsFacetHelpers.createNaymsDiamondFunctionsCut(naymsFacetAddresses);
        nayms.diamondCut(cut, address(initDiamond), abi.encodeCall(initDiamond.initialize, ()));

        vm.stopBroadcast();
    }
}
