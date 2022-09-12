// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Script.sol";
import { LibDeployNayms } from "script/utils/LibDeployNayms.sol";
import { LibNaymsFacetHelpers } from "script/utils/LibNaymsFacetHelpers.sol";

import { SystemFacet } from "src/diamonds/nayms/facets/SystemFacet.sol";
import { ISystemFacet } from "src/diamonds/nayms/interfaces/ISystemFacet.sol";
import { INayms } from "src/diamonds/nayms/INayms.sol";
import { IDiamondCut } from "src/diamonds/shared/interfaces/IDiamondCut.sol";
import "ds-test/test.sol";

contract DeploySystemFacet is Script, DSTest {
    bytes4[] replaceSelectors;
    bytes4[] addSelectors;

    function deploy(bool upgradeFlag) external {
        console2.log("deploying to", block.chainid);
        console2.log("msg.sender during broadcast", msg.sender);
        console2.log("msg.sender's coin balance", address(msg.sender).balance);
        console2.log("msg.sender's starting nonce", vm.getNonce(msg.sender));

        string memory deployFile = "deployedAddresses.json";
        string memory deployData = vm.readFile(deployFile);

        address naymsDiamondAddress = abi.decode(vm.parseJson(deployData, string.concat(".NaymsDiamond.", vm.toString(block.chainid), ".address")), (address));

        INayms nayms = INayms(naymsDiamondAddress);
        uint256 replaceCount;
        uint256 addCount;

        vm.startBroadcast();

        SystemFacet systemFacet = new SystemFacet();

        bytes4[] memory functionSelectorsSystemFacet = new bytes4[](3);
        functionSelectorsSystemFacet[0] = ISystemFacet.createEntity.selector;
        functionSelectorsSystemFacet[1] = ISystemFacet.approveUser.selector;
        functionSelectorsSystemFacet[2] = ISystemFacet.stringToBytes32.selector;

        // upgrade
        if (upgradeFlag) {
            for (uint256 i; i < functionSelectorsSystemFacet.length; ++i) {
                // replace
                if (nayms.facetAddress(functionSelectorsSystemFacet[i]) != address(0)) {
                    replaceCount++;
                    replaceSelectors.push(functionSelectorsSystemFacet[i]);
                    // add
                } else if (nayms.facetAddress(functionSelectorsSystemFacet[i]) == address(0)) {
                    addCount++;
                    addSelectors.push(functionSelectorsSystemFacet[i]);
                }
            }
            IDiamondCut.FacetCut[] memory cut;
            if (addCount > 0 && replaceCount > 0) {
                cut = new IDiamondCut.FacetCut[](2);

                cut[0] = IDiamondCut.FacetCut({ facetAddress: address(systemFacet), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: replaceSelectors });
                cut[1] = IDiamondCut.FacetCut({ facetAddress: address(systemFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: addSelectors });
            } else {
                cut = new IDiamondCut.FacetCut[](1);
                if (addCount > 0) {
                    cut[0] = IDiamondCut.FacetCut({ facetAddress: address(systemFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: addSelectors });
                } else if (replaceCount > 0) {
                    cut[0] = IDiamondCut.FacetCut({ facetAddress: address(systemFacet), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: replaceSelectors });
                }
            }
            nayms.diamondCut(cut, address(0), "");
        }
        vm.stopBroadcast();
    }
}
