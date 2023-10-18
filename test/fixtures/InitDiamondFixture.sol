// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";
import { NaymsTokenFacet } from "src/diamonds/nayms/facets/NaymsTokenFacet.sol";
import { AdminFacet } from "src/diamonds/nayms/facets/AdminFacet.sol";
import { SystemFacet } from "src/diamonds/nayms/facets/SystemFacet.sol";

// solhint-disable no-empty-blocks

/// Create a fixture to test the InitDiamond contract
contract InitDiamondFixture is InitDiamond, SystemFacet, NaymsTokenFacet, AdminFacet {

}
