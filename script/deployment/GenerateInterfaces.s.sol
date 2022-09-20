// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9;

import "script/utils/DeploymentHelpers.sol";

contract GenerateInterfaces is DeploymentHelpers {
    function run(string memory pathToOutput) external {
        if (keccak256(abi.encodePacked(pathToOutput)) == keccak256(abi.encodePacked(""))) {
            pathToOutput = "test-interfaces";
        }
        string[] memory facetNames = ffiFindFacetNames();

        string memory artifactFile;
        string memory outputPathAndName;

        string[] memory inputs = new string[](5);
        inputs[0] = "cast";
        inputs[1] = "interface";
        inputs[2] = artifactFile;
        inputs[3] = "-o";
        inputs[4] = outputPathAndName;

        for (uint256 i; i < facetNames.length; i++) {
            artifactFile = string.concat(artifactsPath, facetNames[i], "Facet.sol/", facetNames[i], "Facet.json");
            outputPathAndName = string.concat(pathToOutput, "/I", facetNames[i], ".sol");
            inputs[2] = artifactFile;
            inputs[4] = outputPathAndName;
            bytes memory res = vm.ffi(inputs);
        }
    }
}
