// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Script.sol";

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";

contract DeployInitDiamond is Script {
    InitDiamond public initDiamond;

    function run() external {
        // set sender address to Nayms account1
        vm.startBroadcast();
        console2.log("msg.sender during broadcast", msg.sender);
        console2.log("msg.sender's coin balance", address(msg.sender).balance);

        initDiamond = new InitDiamond();

        vm.stopBroadcast();
    }
}
