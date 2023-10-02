// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";

import { OneOff360InitDiamond } from "src/utils/OneOff360InitDiamond.sol";
import { console2 as c } from "forge-std/console2.sol";

/// @dev Deploy a single contract and calculate the upgradeHash to replace methods in the diamond.
///      Returns an upgradeHash to replace methods in the diamond. These method(s) are from a single facet.
/// note The upgradeHash returned here is only correct for upgrading a single facet, and assuming all methods are `replaced`. If we were to add and/or remove methods, we would need to add them to the `cut` array.

contract DeployOneoff is Script {
    function run() external {
        vm.startBroadcast(0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f);
        address addr = address(new OneOff360InitDiamond());
        vm.stopBroadcast();
    }
}
