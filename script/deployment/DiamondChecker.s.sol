// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";

import "script/utils/DeploymentHelpers.sol";

contract DiamondChecker is DeploymentHelpers {
    /// Does this facet address exist in this diamond?
    function run(address _facetAddressToCheck, bytes4 _selectorChk) external returns (bool) {
        IDiamondProxy diamond = IDiamondProxy(address(new DiamondProxy(getDiamondAddressFromFile())));

        address[] memory addresses = diamond.facetAddresses();

        address selectorAddressChk = diamond.facetAddress(_selectorChk);

        console2.log("facet that selector is associated with: ", selectorAddressChk);

        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] == _facetAddressToCheck) {
                return true;
            }
        }
    }
}
