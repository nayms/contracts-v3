// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import "script/utils/DeploymentHelpers.sol";

contract DiamondChecker is DeploymentHelpers {
    /// Does this facet address exist in this diamond?
    function run(address _facetAddressToCheck, bytes4 _selectorChk) external returns (bool) {
        INayms nayms = INayms(getDiamondAddressFromFile());

        address[] memory addresses = nayms.facetAddresses();

        address selectorAddressChk = nayms.facetAddress(_selectorChk);

        console2.log("facet that selector is associated with: ", selectorAddressChk);

        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] == _facetAddressToCheck) {
                return true;
            }
        }
    }
}
