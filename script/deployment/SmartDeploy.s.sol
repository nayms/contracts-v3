// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "script/utils/DeploymentHelpers.sol";

contract SmartDeploy is DeploymentHelpers {
    function smartDeploy(
        bool deployNewDiamond,
        bool initNewDiamond,
        FacetDeploymentAction facetDeploymentAction,
        string[] memory facetsToCutIn,
        bytes32 salt
    )
        external
        returns (
            // string[] memory facetsToCutIn
            address diamondAddress,
            address initDiamondAddress,
            bytes32 upgradeHash
        )
    {
        vm.startBroadcast(msg.sender);

        (diamondAddress, initDiamondAddress, upgradeHash) = smartDeployment(deployNewDiamond, initNewDiamond, facetDeploymentAction, facetsToCutIn, salt);

        vm.stopBroadcast();
    }
}
