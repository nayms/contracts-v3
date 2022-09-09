// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Script.sol";
import { LibDeployNayms, NaymsFacetAddresses } from "script/utils/LibDeployNayms.sol";

contract DeployFacets is Script {
    function run() external {
        vm.startBroadcast();
        console2.log("msg.sender during broadcast", msg.sender);
        console2.log("msg.sender's coin balance", address(msg.sender).balance);
        console2.log("msg.sender's starting nonce", vm.getNonce(msg.sender));

        // deploy all facets
        NaymsFacetAddresses memory naymsFacetAddresses = LibDeployNayms.deployNaymsFacets();

        vm.stopBroadcast();
    }
}
