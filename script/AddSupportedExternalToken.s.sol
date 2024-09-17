// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { LibHelpers } from "src/libs/LibHelpers.sol";

contract AddSupportedExternalToken is Script {
    function addSupportedExternalToken(address naymsDiamondAddress, address externalToken, uint256 minimumSell) public {
        vm.startBroadcast(msg.sender);

        IDiamondProxy nayms = IDiamondProxy(naymsDiamondAddress);

        nayms.addSupportedExternalToken(externalToken, minimumSell);

        bytes32 tokenId = LibHelpers._getIdForAddress(externalToken);

        if (!nayms.isSupportedExternalToken(tokenId)) {
            revert("External token has not been added");
        }
    }
}
