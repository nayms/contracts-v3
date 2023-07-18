// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { strings } from "lib/solidity-stringutils/src/strings.sol";
import { IDiamondLoupe } from "src/diamonds/shared/interfaces/IDiamondLoupe.sol";
import "script/utils/DeploymentHelpers.sol";

struct ReconResult {
    string contractName;
    address contractAddress;
    bytes artifactCode;
    bytes onChainCode;
    bool isMatchingWithMetadata;
    bool isMatchingWithoutMetadata;
}
struct ReconInfo {
    uint256 chainId;
    uint256 blockNumber;
    uint256 timestamp;
    ReconResult[] reconResult;
    address[] addressesNotMatching;
    string[] namesNotMatching;
}

library LibSearch {
    function arrayIntersection(
        mapping(string => bool) storage matchResultMapping,
        mapping(bytes32 => bool) storage tMap,
        mapping(bytes32 => string) storage codeToName,
        bytes32[] memory arr1,
        bytes32[] memory arr2
    ) internal {
        // Loop through the second array and map all elements to true
        for (uint256 i; i < arr2.length; i++) {
            tMap[arr2[i]] = true;
        }

        // Loop through the first array and check if any element exists in the map
        for (uint256 i; i < arr1.length; i++) {
            if (tMap[arr1[i]]) {
                matchResultMapping[codeToName[arr1[i]]] = true;
            }
        }
    }
}

contract CodeRecon is DeploymentHelpers {
    using strings for *;
    using LibSearch for mapping(string => bool);

    mapping(bytes32 => bool) tMap;
    address[] public contractAddresses;
    string[] public contractNames;
    bytes32[] public onChainCode;
    bytes32[] public onChainCodeWithoutMetadata;
    bytes32[] public artifactCode;
    bytes32[] public artifactCodeWithoutMetadata;
    mapping(bytes32 => string) public artifactCodeToName;
    mapping(bytes32 => string) public artifactCodeWithoutMetadataToName;
    mapping(string => bool) public matching;
    mapping(string => bool) public matchingWithoutMetadata;
    address[] addressesNotMatching;
    string[] namesNotMatching;

    mapping(bytes32 => address) onChainCodeToAddress;
    mapping(address => bytes32) addressToOnChainCode;
    mapping(bytes32 => address) onChainCodeWithoutMetadataToAddress;
    mapping(address => bytes32) addressToOnChainCodeWithoutMetadata;

    function getOnchainCode(address proxyDiamondAddress) public {
        strings.slice memory needle1 = "a264".toSlice();

        IDiamondLoupe diamond = IDiamondLoupe(proxyDiamondAddress);
        contractAddresses = diamond.facetAddresses();
        contractAddresses.push(proxyDiamondAddress);

        for (uint256 i; i < contractAddresses.length; ++i) {
            onChainCode.push(keccak256(contractAddresses[i].code));
            onChainCodeWithoutMetadata.push(keccak256(bytes(vm.toString(contractAddresses[i].code).toSlice().rfind(needle1).toString())));

            onChainCodeToAddress[keccak256(contractAddresses[i].code)] = contractAddresses[i];
            addressToOnChainCode[contractAddresses[i]] = keccak256(contractAddresses[i].code);
            onChainCodeWithoutMetadataToAddress[keccak256(bytes(vm.toString(contractAddresses[i].code).toSlice().rfind(needle1).toString()))] = contractAddresses[i];
            addressToOnChainCodeWithoutMetadata[contractAddresses[i]] = keccak256(bytes(vm.toString(contractAddresses[i].code).toSlice().rfind(needle1).toString()));
        }
    }

    function getArtifactCode(string[] memory contractName) public {
        contractNames = contractName;

        strings.slice memory needle1 = "a264".toSlice();
        for (uint256 i; i < contractName.length; ++i) {
            bytes memory artifactCode_ = vm.getDeployedCode(string.concat(contractName[i], ".sol:", contractName[i]));
            bytes32 keccakArtifactCode = keccak256(artifactCode_);
            artifactCode.push(keccak256(artifactCode_));
            artifactCodeToName[keccakArtifactCode] = contractName[i];

            bytes32 artifactCodeWithoutMetadata_ = keccak256(bytes(vm.toString(artifactCode_).toSlice().rfind(needle1).toString()));
            artifactCodeWithoutMetadata.push(artifactCodeWithoutMetadata_);
            artifactCodeWithoutMetadataToName[artifactCodeWithoutMetadata_] = contractName[i];
        }
    }

    function compareCode(string[] memory contractName) public {
        getArtifactCode(contractName);
        getOnchainCode(getDiamondAddressFromFile());

        matching.arrayIntersection(tMap, artifactCodeToName, onChainCode, artifactCode);
        matchingWithoutMetadata.arrayIntersection(tMap, artifactCodeWithoutMetadataToName, onChainCodeWithoutMetadata, artifactCodeWithoutMetadata);
        for (uint256 i; i < contractAddresses.length; ++i) {
            if (matchingWithoutMetadata[artifactCodeWithoutMetadataToName[onChainCodeWithoutMetadata[i]]]) {
                console2.log("Bytecode WITHOUT metadata matches for facet", artifactCodeWithoutMetadataToName[onChainCodeWithoutMetadata[i]], vm.toString(contractAddresses[i]));
            }
        }

        for (uint256 i; i < contractAddresses.length; ++i) {
            if (!matchingWithoutMetadata[artifactCodeWithoutMetadataToName[onChainCodeWithoutMetadata[i]]]) {
                console2.log(
                    "Bytecode WITHOUT metadata DOES NOT MATCH for facet",
                    artifactCodeWithoutMetadataToName[onChainCodeWithoutMetadata[i]],
                    vm.toString(contractAddresses[i])
                );
                addressesNotMatching.push(contractAddresses[i]);
            }
        }
    }

    function genOutput() public {
        string memory path = "codeReconReport.json";

        vm.serializeUint("ReconInfo", "chainId", uint256(block.chainid));
        vm.serializeUint("ReconInfo", "blockNumber", uint256(block.number));
        vm.serializeUint("ReconInfo", "timestamp", uint256(block.timestamp));

        string[] memory reconResults = new string[](contractAddresses.length);

        for (uint256 i; i < contractAddresses.length; ++i) {
            if (!matchingWithoutMetadata[contractNames[i]]) {
                namesNotMatching.push(contractNames[i]);
            }

            vm.serializeString(string.concat("reconResult", vm.toString(i)), "contractName", artifactCodeWithoutMetadataToName[onChainCodeWithoutMetadata[i]]);
            vm.serializeAddress(string.concat("reconResult", vm.toString(i)), "contractAddress", onChainCodeWithoutMetadataToAddress[onChainCodeWithoutMetadata[i]]);
            // vm.serializeBytes(string.concat("reconResult", vm.toString(i)), "artifactCode", reconResult.artifactCode);
            // vm.serializeBytes(string.concat("reconResult", vm.toString(i)), "onChainCode", reconResult.onChainCode);
            vm.serializeBool(string.concat("reconResult", vm.toString(i)), "isMatchingWithMetadata", matching[artifactCodeToName[onChainCode[i]]]);
            reconResults[i] = vm.serializeBool(
                string.concat("reconResult", vm.toString(i)),
                "isMatchingWithoutMetadata",
                matchingWithoutMetadata[artifactCodeWithoutMetadataToName[onChainCodeWithoutMetadata[i]]]
            );
        }

        vm.serializeAddress("ReconInfo", "addressesNotMatching", addressesNotMatching);
        vm.serializeString("ReconInfo", "namesNotMatching", namesNotMatching);

        string memory finalJson = vm.serializeString("ReconInfo", "reconResult", reconResults);
        vm.writeJson(finalJson, path);
    }

    function run() public {
        string[] memory contractName = new string[](15);
        contractName[0] = "ACLFacet";
        contractName[1] = "AdminFacet";
        contractName[2] = "EntityFacet";
        contractName[3] = "GovernanceFacet";
        contractName[4] = "MarketFacet";
        contractName[5] = "NaymsTokenFacet";
        contractName[6] = "SimplePolicyFacet";
        contractName[7] = "SystemFacet";
        contractName[8] = "TokenizedVaultFacet";
        contractName[9] = "TokenizedVaultIOFacet";
        contractName[10] = "UserFacet";
        contractName[11] = "DiamondLoupeFacet";
        contractName[12] = "NaymsOwnershipFacet";
        contractName[13] = "PhasedDiamondCutFacet";
        contractName[14] = "Nayms";

        compareCode(contractName);
        genOutput();
    }
}
