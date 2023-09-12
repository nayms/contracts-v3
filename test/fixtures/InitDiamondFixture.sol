// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { InitDiamond } from "src/init/InitDiamond.sol";
import { NaymsTokenFacet } from "src/facets/NaymsTokenFacet.sol";
import { ACLFacet } from "src/facets/ACLFacet.sol";
import { AdminFacet } from "src/facets/AdminFacet.sol";
import { SystemFacet } from "src/facets/SystemFacet.sol";

// solhint-disable no-empty-blocks

/// Create a fixture to test the InitDiamond contract
contract InitDiamondFixture is InitDiamond, SystemFacet, NaymsTokenFacet, ACLFacet, AdminFacet {

}
