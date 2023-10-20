// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "script/utils/DeploymentHelpers.sol";

import { IDiamondCut } from "../../src/diamond/contracts/interfaces/IDiamondCut.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";

import { DiamondCutFacet } from "src/diamond/contracts/facets/DiamondCutFacet.sol";

contract ReplaceDiamondCut is DeploymentHelpers {
    function run() public {
        IDiamondProxy nayms = IDiamondProxy(getDiamondAddressFromFile());

        // Replace diamondCut() with the two phase diamondCut()
        vm.startBroadcast(msg.sender);
        address phasedDiamondCutFacet = address(new DiamondCutFacet());

        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory f0 = new bytes4[](1);
        f0[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(phasedDiamondCutFacet), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: f0 });

        // replace the diamondCut() with the 2-phase diamondCut()
        nayms.diamondCut(cut, address(0), "");
        vm.stopBroadcast();
    }
}
