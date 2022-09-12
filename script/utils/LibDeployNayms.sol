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

import { NaymsFacetAddressIndex } from "./LibNaymsFacetHelpers.sol";

library LibDeployNayms {
    /// @notice deploy all Nayms facets
    function deployNaymsFacets() internal returns (address[] memory naymsFacetAddresses) {
        naymsFacetAddresses = new address[](13);
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.ACL)] = address(new ACLFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.NAYMS_ERC20)] = address(new NaymsERC20Facet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.ADMIN)] = address(new AdminFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.USER)] = address(new UserFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.SYSTEM)] = address(new SystemFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.TOKENIZED_VAULT)] = address(new TokenizedVaultFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.TOKENIZED_VAULT_IO)] = address(new TokenizedVaultIOFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.MARKET)] = address(new MarketFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.ENTITY)] = address(new EntityFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.SIMPLE_POLICY)] = address(new SimplePolicyFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.NDF)] = address(new NDFFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.SSF)] = address(new SSFFacet());
        naymsFacetAddresses[uint(NaymsFacetAddressIndex.STAKING)] = address(new StakingFacet());
    }

    // function deployNaymsAndInit() internal returns (address naymsAddress) {
    //     // deploy the init contract
    //     initDiamond = new InitDiamond();
    //     deploymentInfo.initDiamond = address(initDiamond);
    // }
}
