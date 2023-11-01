// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "script/utils/DeploymentHelpers.sol";

import { IERC173 } from "src/interfaces/IERC173.sol";
import { NaymsOwnershipFacet } from "src/facets/NaymsOwnershipFacet.sol";

import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";

contract ReplaceOwnershipFacet is DeploymentHelpers {
    function run() public returns (bytes32 cutHash) {
        IDiamondProxy nayms = IDiamondProxy(address(new DiamondProxy(getDiamondAddressFromFile())));

        vm.startBroadcast(msg.sender);
        address addressWithUpgrade = address(new NaymsOwnershipFacet());

        IDiamondCut.FacetCut[] memory cut;
        cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory f0 = new bytes4[](1);
        f0[0] = IERC173.transferOwnership.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(addressWithUpgrade), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: f0 });

        cutHash = keccak256(abi.encode(cut));
        if (nayms.getUpgrade(cutHash) > block.timestamp) {
            nayms.diamondCut(cut, address(0), "");
        } else {
            console2.log("Upgrade not allowed - upgrade not registered or upgrade time has passed");
        }

        vm.stopBroadcast();
    }
}
