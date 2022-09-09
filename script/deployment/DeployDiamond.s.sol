// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "forge-std/Script.sol";

import { INayms } from "src/diamonds/nayms/INayms.sol";
import { Nayms } from "src/diamonds/nayms/Nayms.sol";

import { Create3Deployer } from "src/utils/Create3Deployer.sol";
import { Strings } from "src/utils/Strings.sol";

import { LibWriteJson } from "script/utils/LibWriteJson.sol";

contract DeployDiamond is Script {
    using LibWriteJson for string;
    // bytes32 _salt = bytes32("ff003006");
    INayms public nayms;

    function deploy(bool _create3, bytes32 _salt) external {
        vm.startBroadcast();
        console2.log("deploying to", block.chainid);
        console2.log("msg.sender during broadcast", msg.sender);
        console2.log("msg.sender's coin balance", address(msg.sender).balance);
        console2.log("msg.sender's starting nonce", vm.getNonce(msg.sender));

        if (_create3) {
            Create3Deployer c3Deployer = new Create3Deployer();

            // predetermined Nayms Diamond address
            address naymsDiamondAddress = c3Deployer.getDeployed(_salt);

            // deploy Nayms Diamond
            console2.log("Deterministic contract address for Nayms", naymsDiamondAddress);

            nayms = INayms(c3Deployer.deployContract(_salt, abi.encodePacked(type(Nayms).creationCode, abi.encode(address(msg.sender))), 0));

            require(naymsDiamondAddress == address(nayms), "deterministic address and actual deployed address don't match");
        } else {
            nayms = INayms(address(new Nayms(address(msg.sender))));
        }

        // write the Nayms Diamond address to an output to be consumed by the backend
        string memory path = "deployedAddresses.json";
        string memory write = LibWriteJson.createObject(
            LibWriteJson.keyObject("NaymsDiamond", LibWriteJson.keyObject(vm.toString(block.chainid), LibWriteJson.keyValue("address", vm.toString(address(nayms)))))
        );
        vm.writeFile(path, write);

        // todo verify the Nayms Diamond that was created by Create3Deployer

        vm.stopBroadcast();
    }
}
