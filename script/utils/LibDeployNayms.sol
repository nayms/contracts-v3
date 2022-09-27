// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice The SINGLE source where we setup the deployment of our Nayms platform.
///         Any other place we need this deployment (in a v0.8 solc file) should inherit this contract.

import { Nayms } from "src/diamonds/nayms/Nayms.sol";

import { ACLFacet } from "src/diamonds/nayms/facets/ACLFacet.sol";
import { AdminFacet } from "src/diamonds/nayms/facets/AdminFacet.sol";
import { UserFacet } from "src/diamonds/nayms/facets/UserFacet.sol";
import { SystemFacet } from "src/diamonds/nayms/facets/SystemFacet.sol";
import { EntityFacet } from "src/diamonds/nayms/facets/EntityFacet.sol";
import { TokenizedVaultFacet } from "src/diamonds/nayms/facets/TokenizedVaultFacet.sol";
import { TokenizedVaultIOFacet } from "src/diamonds/nayms/facets/TokenizedVaultIOFacet.sol";
import { MarketFacet } from "src/diamonds/nayms/facets/MarketFacet.sol";
import { SimplePolicyFacet } from "src/diamonds/nayms/facets/SimplePolicyFacet.sol";

// import { NaymsFacetAddresses } from "./LibNaymsFacetHelpers.sol";

// Index into naymsFacetAddresses array
enum NaymsFacetAddressIndex {
    ACL,
    NAYMS_ERC20,
    ADMIN,
    USER,
    SYSTEM,
    TOKENIZED_VAULT,
    TOKENIZED_VAULT_IO,
    MARKET,
    ENTITY,
    SIMPLE_POLICY,
    NDF,
    SSF,
    STAKING
}

library LibDeployNayms {
    /// @notice deploy all Nayms facets
    function deployNaymsFacets(NaymsFacetAddressIndex naymsFacetAddressIndex) internal returns (address naymsFacetAddresses) {
        if (naymsFacetAddressIndex == NaymsFacetAddressIndex.ACL) {
            naymsFacetAddresses = address(new ACLFacet());
        } else if (naymsFacetAddressIndex == NaymsFacetAddressIndex.ADMIN) {
            naymsFacetAddresses = address(new AdminFacet());
        } else if (naymsFacetAddressIndex == NaymsFacetAddressIndex.USER) {
            naymsFacetAddresses = address(new UserFacet());
        } else if (naymsFacetAddressIndex == NaymsFacetAddressIndex.SYSTEM) {
            naymsFacetAddresses = address(new SystemFacet());
        } else if (naymsFacetAddressIndex == NaymsFacetAddressIndex.TOKENIZED_VAULT) {
            naymsFacetAddresses = address(new TokenizedVaultFacet());
        } else if (naymsFacetAddressIndex == NaymsFacetAddressIndex.TOKENIZED_VAULT_IO) {
            naymsFacetAddresses = address(new TokenizedVaultIOFacet());
        } else if (naymsFacetAddressIndex == NaymsFacetAddressIndex.MARKET) {
            naymsFacetAddresses = address(new MarketFacet());
        } else if (naymsFacetAddressIndex == NaymsFacetAddressIndex.ENTITY) {
            naymsFacetAddresses = address(new EntityFacet());
        } else if (naymsFacetAddressIndex == NaymsFacetAddressIndex.SIMPLE_POLICY) {
            naymsFacetAddresses = address(new SimplePolicyFacet());
        }
    }

    function deployNaymsFacetsByName(string memory facetName) internal returns (address facetAddress) {
        if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("Nayms"))) {
            facetAddress = address(new Nayms(msg.sender));
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("ACL"))) {
            facetAddress = address(new ACLFacet());
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("Admin"))) {
            facetAddress = address(new AdminFacet());
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("User"))) {
            facetAddress = address(new UserFacet());
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("System"))) {
            facetAddress = address(new SystemFacet());
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("TokenizedVault"))) {
            facetAddress = address(new TokenizedVaultFacet());
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("TokenizedVaultIO"))) {
            facetAddress = address(new TokenizedVaultIOFacet());
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("Market"))) {
            facetAddress = address(new MarketFacet());
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("Entity"))) {
            facetAddress = address(new EntityFacet());
        } else if (keccak256(abi.encodePacked(facetName)) == keccak256(abi.encodePacked("SimplePolicy"))) {
            facetAddress = address(new SimplePolicyFacet());
        }
    }
}
