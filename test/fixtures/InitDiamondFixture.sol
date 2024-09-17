// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { InitDiamond } from "src/init/InitDiamond.sol";
import { AdminFacet } from "src/facets/AdminFacet.sol";
import { SystemFacet } from "src/facets/SystemFacet.sol";

// solhint-disable no-empty-blocks

/// Create a fixture to test the InitDiamond contract
contract InitDiamondFixture is InitDiamond, SystemFacet, AdminFacet {}
