// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";

contract AddSupportedExternalToken is Script {
    function addSupportedExternalToken(address naymsDiamondAddress, address externalToken) public {
        INayms nayms = INayms(naymsDiamondAddress);

        vm.startPrank(msg.sender);

        nayms.addSupportedExternalToken(externalToken);

        bytes32 tokenId = LibHelpers._getIdForAddress(externalToken);

        if (!nayms.isSupportedExternalToken(tokenId)) {
            revert("External token has not been added");
        }
    }
}
