// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import "script/utils/DeploymentHelpers.sol";

contract S03UpgradeDiamond is DeploymentHelpers {
    function run(address _ownerAddress, IDiamondCut.FacetCut[] memory cut) external {
        INayms nayms = INayms(getDiamondAddressFromFile());

        if (_ownerAddress == address(0)) {
            _ownerAddress = nayms.owner();
        }

        vm.startBroadcast(_ownerAddress);
        nayms.diamondCut(cut, address(0), new bytes(0));
        vm.stopBroadcast();
    }
}
