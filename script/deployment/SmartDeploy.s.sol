// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13 <0.9;

import "script/utils/DeploymentHelpers.sol";

contract SmartDeploy is DeploymentHelpers {
    // function smartDeploy(
    //     bool deployNewDiamond,
    //     bool initNewDiamond,
    //     FacetDeploymentAction facetDeploymentAction,
    //     string[] memory facetsToCutIn
    // ) external returns (address diamondAddress, address initDiamond) {
    //     smartDeployment(deployNewDiamond, initNewDiamond, facetDeploymentAction, facetsToCutIn);
    // }

    function smartDeploy(bool deployNewDiamond, bool initNewDiamond)
        external
        returns (
            // FacetDeploymentAction facetDeploymentAction,
            // string[] memory facetsToCutIn
            address diamondAddress,
            address initDiamond
        )
    {
        FacetDeploymentAction facetDeploymentAction;
        string[] memory facetsToCutIn;

        facetDeploymentAction = FacetDeploymentAction.UpgradeFacetsWithChangesOnly;
        vm.startBroadcast();
        smartDeployment(deployNewDiamond, initNewDiamond, facetDeploymentAction, facetsToCutIn);

        vm.stopBroadcast();
    }
}
