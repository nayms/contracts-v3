// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";
import { NaymsTokenFacet } from "src/diamonds/nayms/facets/NaymsTokenFacet.sol";
import { ACLFacet } from "src/diamonds/nayms/facets/ACLFacet.sol";

/// Create a fixture to test the InitDiamond contract

contract InitDiamondFixture is InitDiamond, NaymsTokenFacet, ACLFacet {

}
