// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// import { INayms } from "src/diamonds/nayms/INayms.sol";
// import "script/utils/DeploymentHelpers.sol";
// import { strings } from "lib/solidity-stringutils/src/strings.sol";

// error EmptyAddressFromSelector(string _facetName);

// enum CheckBytecodeAction {
//     WithMetadata, // With the metadata bytecode hash appended to the runtime bytecode
//     NoMetadata // With the metadata bytecode hash REMOVED from the runtime bytecode
// }

// contract CheckBytecode is DeploymentHelpers {
//     using strings for *;
//     address[] public facetAddresses;
//     mapping(string => bool) public matching;
//     mapping(string => bool) public matchingNoCBOR;
//     mapping(string => address) public facetAddressesByName;
//     string[] public allFacetNames;
//     strings.slice needle1 = "a264".toSlice();

//     function run(CheckBytecodeAction _checkBytecode) external {
//         address diamondAddress = getDiamondAddressFromFile();
//         INayms nayms = INayms(diamondAddress);
//         facetAddresses = nayms.facetAddresses();

//         allFacetNames = LibGeneratedNaymsFacetHelpers.getFacetNames();
//         uint256 numberOfFacets = allFacetNames.length;

//         if (_checkBytecode == CheckBytecodeAction.WithMetadata) {
//             for (uint256 i; i < numberOfFacets; ++i) {
//                 if (compareBytecode(address(nayms), allFacetNames[i])) {
//                     matching[allFacetNames[i]] = true;
//                     console2.log("Bytecode matches for facet:        ", allFacetNames[i]);
//                 }
//             }
//             for (uint256 i; i < numberOfFacets; ++i) {
//                 if (matching[allFacetNames[i]] == false) {
//                     console2.log("Bytecode does NOT match for facet: ", allFacetNames[i]);
//                 }
//             }
//         }

//         if (_checkBytecode == CheckBytecodeAction.NoMetadata) {
//             string memory artifactsDeployedByteccodeString;
//             string memory targetFacetBytecodeString;

//             bool bytecodeMatchFlag;
//             for (uint256 i; i < numberOfFacets; ++i) {
//                 string memory artifactsDeployedByteccodeString = vm.toString(
//                     vm.getDeployedCode(string.concat(artifactsPath, allFacetNames[i], "Facet.sol/", allFacetNames[i], "Facet.json"))
//                 );
//                 strings.slice memory artifactsDeployedByteccodeSlice = artifactsDeployedByteccodeString.toSlice();

//                 bytes4[] memory functionSignatures = generateSelectors(string.concat(allFacetNames[i], "Facet"));
//                 uint256 numberOfFunctionSignaturesFromArtifact = functionSignatures.length;
//                 // get first non zero address
//                 address targetFacetAddress;
//                 for (uint256 j; j < numberOfFunctionSignaturesFromArtifact; j++) {
//                     targetFacetAddress = IDiamondLoupe(diamondAddress).facetAddress(functionSignatures[j]);
//                     if (targetFacetAddress != address(0)) {
//                         facetAddressesByName[allFacetNames[i]] = targetFacetAddress;
//                         break;
//                     }
//                 }

//                 // diamond does not have a facet with selectors from this facet from this repository
//                 if (facetAddressesByName[allFacetNames[i]] == address(0)) {
//                     revert EmptyAddressFromSelector(allFacetNames[i]);
//                 }

//                 bytes memory targetFacetBytecode = targetFacetAddress.code;
//                 targetFacetBytecodeString = vm.toString(targetFacetBytecode);
//                 strings.slice memory targetFacetBytecodeSlice = targetFacetBytecodeString.toSlice();

//                 bytecodeMatchFlag = strEquals(artifactsDeployedByteccodeSlice.rfind(needle1).toString(), targetFacetBytecodeSlice.rfind(needle1).toString());
//                 matchingNoCBOR[allFacetNames[i]] = bytecodeMatchFlag;
//             }

//             for (uint256 i; i < numberOfFacets; ++i) {
//                 if (matchingNoCBOR[allFacetNames[i]] == true) {
//                     console2.log("Bytecode matches for facet", allFacetNames[i], vm.toString(facetAddressesByName[allFacetNames[i]]));
//                 }
//             }

//             for (uint256 i; i < numberOfFacets; ++i) {
//                 if (matchingNoCBOR[allFacetNames[i]] == false) {
//                     console2.log("Bytecode does NOT match for facet: ", allFacetNames[i], vm.toString(facetAddressesByName[allFacetNames[i]]));
//                 }
//             }
//         }

//         // compareContractBytecode("Nayms", 0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5);
//         // compareContractBytecode("PhasedDiamondCutFacet", 0x168bBc195167cd1EbD70584fcEEA54cc630DB7c7);
//         // compareContractBytecode("NaymsOwnershipFacet", 0x073C1a072845D1d87f42309af9911bd3c07fC599);
//     }

//     function strEquals(string memory s1, string memory s2) private pure returns (bool) {
//         return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
//     }

//     function compareContractBytecode(string memory contractName, address targetFacetAddress) internal returns (bool bytecodeMatchFlag) {
//         facetAddressesByName[contractName] = targetFacetAddress;
//         allFacetNames.push(contractName);

//         string memory artifactsDeployedByteccodeString = vm.toString(vm.getDeployedCode(string.concat(artifactsPath, contractName, ".sol/", contractName, ".json")));
//         strings.slice memory artifactsDeployedByteccodeSlice = artifactsDeployedByteccodeString.toSlice();

//         bytes memory targetFacetBytecode = targetFacetAddress.code;
//         string memory targetFacetBytecodeString = vm.toString(targetFacetBytecode);
//         strings.slice memory targetFacetBytecodeSlice = targetFacetBytecodeString.toSlice();

//         bytecodeMatchFlag = strEquals(artifactsDeployedByteccodeSlice.rfind(needle1).toString(), targetFacetBytecodeSlice.rfind(needle1).toString());
//         matchingNoCBOR[contractName] = bytecodeMatchFlag;
//     }
// }
