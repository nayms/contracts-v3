// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";

import { INayms, IDiamondLoupe } from "src/diamonds/nayms/INayms.sol";

import { CREATE3 } from "solmate/utils/CREATE3.sol";

contract T01DeploymentTest is D03ProtocolDefaults {
    function setUp() public virtual override {
        super.setUp();
    }

    function testOwnerOfDiamond() public {
        assertEq(nayms.owner(), account0);
    }

    // todo test against artifact data generated for deployment
    function testDiamondLoupeFunctionality() public view {
        IDiamondLoupe.Facet[] memory facets = nayms.facets();

        for (uint256 i = 0; i < facets.length; i++) {
            nayms.facetFunctionSelectors(facets[i].facetAddress);
        }

        nayms.facetAddresses();
    }

    function testFork() public {
        string memory mainnetUrl = vm.rpcUrl("mainnet");
        string memory goerliUrl = vm.rpcUrl("goerli");
        uint256 mainnetFork = vm.createSelectFork(mainnetUrl, MAINNET_FORK_BLOCK_NUMBER);
        uint256 goerliFork = vm.createSelectFork(goerliUrl, GOERLI_FORK_BLOCK_NUMBER);
    }
}
