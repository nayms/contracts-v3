// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice The SINGLE source where we setup the deployment of our Nayms platform.
///         Any other place we need this deployment (in a v0.8 solc file) should inherit this contract.
// todo wip

// import { InitDiamond } from "src/diamonds/nayms/InitDiamond.sol";

import { ACLFacet } from "src/diamonds/nayms/facets/ACLFacet.sol";
import { AdminFacet } from "src/diamonds/nayms/facets/AdminFacet.sol";
import { UserFacet } from "src/diamonds/nayms/facets/UserFacet.sol";
import { NaymsERC20Facet } from "src/diamonds/nayms/facets/NaymsERC20Facet.sol";
import { SystemFacet } from "src/diamonds/nayms/facets/SystemFacet.sol";
import { EntityFacet } from "src/diamonds/nayms/facets/EntityFacet.sol";
import { TokenizedVaultFacet } from "src/diamonds/nayms/facets/TokenizedVaultFacet.sol";
import { TokenizedVaultIOFacet } from "src/diamonds/nayms/facets/TokenizedVaultIOFacet.sol";
import { MarketFacet } from "src/diamonds/nayms/facets/MarketFacet.sol";
import { SimplePolicyFacet } from "src/diamonds/nayms/facets/SimplePolicyFacet.sol";
import { NDFFacet } from "src/diamonds/nayms/facets/NDFFacet.sol";
import { SSFFacet } from "src/diamonds/nayms/facets/SSFFacet.sol";
import { StakingFacet } from "src/diamonds/nayms/facets/StakingFacet.sol";

// import { Nayms } from "src/diamonds/nayms/Nayms.sol";

import { NaymsFacetAddresses } from "./LibNaymsFacetHelpers.sol";

library LibDeployNayms {
    /// @notice deploy all Nayms facets
    function deployNaymsFacets() internal returns (NaymsFacetAddresses memory naymsFacetAddresses) {
        naymsFacetAddresses.aclFacet = address(new ACLFacet());
        naymsFacetAddresses.naymsERC20Facet = address(new NaymsERC20Facet());
        naymsFacetAddresses.adminFacet = address(new AdminFacet());
        naymsFacetAddresses.userFacet = address(new UserFacet());
        naymsFacetAddresses.systemFacet = address(new SystemFacet());
        naymsFacetAddresses.tokenizedVaultFacet = address(new TokenizedVaultFacet());
        naymsFacetAddresses.tokenizedVaultIOFacet = address(new TokenizedVaultIOFacet());
        naymsFacetAddresses.marketFacet = address(new MarketFacet());
        naymsFacetAddresses.entityFacet = address(new EntityFacet());
        naymsFacetAddresses.simplePolicyFacet = address(new SimplePolicyFacet());
        naymsFacetAddresses.ndfFacet = address(new NDFFacet());
        naymsFacetAddresses.ssfFacet = address(new SSFFacet());
        naymsFacetAddresses.stakingFacet = address(new StakingFacet());
    }

    // function deployNaymsAndInit() internal returns (address naymsAddress) {
    //     // deploy the init contract
    //     initDiamond = new InitDiamond();
    //     deploymentInfo.initDiamond = address(initDiamond);
    // }
}
