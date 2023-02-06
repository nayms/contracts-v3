// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "script/utils/DeploymentHelpers.sol";

import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { DiamondCutFacet } from "src/diamonds/shared/facets/PhasedDiamondCutFacet.sol";

contract ReplaceDiamondCut is DeploymentHelpers {
    function run() public {
        INayms nayms = INayms(getDiamondAddressFromFile());

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
