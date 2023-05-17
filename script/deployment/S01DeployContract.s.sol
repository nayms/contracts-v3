// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import "script/utils/DeploymentHelpers.sol";

/// @dev Deploy a single contract and calculate the upgradeHash to replace methods in the diamond.
///      Returns an upgradeHash to replace methods in the diamond. These method(s) are from a single facet.
/// note The upgradeHash returned here is only correct for upgrading a single facet, and assuming all methods are `replaced`. If we were to add and/or remove methods, we would need to add them to the `cut` array.

contract S01DeployContract is DeploymentHelpers {
    function run(string calldata contractName) external returns (IDiamondCut.FacetCut[] memory cut, bytes32 upgradeHash, bytes32 upgradeHashOld) {
        address deployer = msg.sender;
        vm.startBroadcast(deployer);
        // Deploy contract based on the contract name from its artifact file.
        address contractAddress = deployContract(contractName);
        vm.stopBroadcast();

        console2.log(StdStyle.green("Deployed contract"), StdStyle.yellow(contractName), StdStyle.green("at address"), StdStyle.yellow(vm.toString(contractAddress)));

        // Get upgradeHash if we were to upgrade and replace matching functions.

        cut = new IDiamondCut.FacetCut[](1);

        // Get all function selectors from the forge artifacts for this contract.
        bytes4[] memory functionSelectors = generateSelectors(contractName);

        cut[0] = IDiamondCut.FacetCut({ facetAddress: contractAddress, action: IDiamondCut.FacetCutAction.Replace, functionSelectors: functionSelectors });

        upgradeHashOld = keccak256(abi.encode(cut)); // note old method of calculating upgrade hash by hashing only the cut struct
        upgradeHash = keccak256(abi.encode(cut, address(0), ""));
        console2.log(StdStyle.blue("Calculated upgradeHashOld (hashing `cut` struct ONLY): "), StdStyle.yellow(vm.toString(upgradeHashOld)));
        console2.log(StdStyle.blue("Calculated upgradeHash (hashing all three parameters of `diamondCut()`): "), StdStyle.yellow(vm.toString(upgradeHash)));
    }
}
