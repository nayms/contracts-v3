// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/
import { LibDiamond } from "./libraries/LibDiamond.sol";
import { DiamondCutFacet } from "./facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "./facets/DiamondLoupeFacet.sol";
import { OwnershipFacet } from "./facets/OwnershipFacet.sol";
import { ACLFacet } from "src/facets/ACLFacet.sol";
import { GovernanceFacet } from "src/facets/GovernanceFacet.sol";

contract Diamond {
    constructor(address _contractOwner, address _systemAdmin) payable {
        LibDiamond.setContractOwner(_contractOwner);
        LibDiamond.setRoleGroupsAndAssigners();
        LibDiamond.setSystemAdmin(_systemAdmin); // note: This method checks to make sure system admin is not the same address as the contract owner.
        LibDiamond.setUpgradeExpiration();

        // TODO KP help!
        // LibDiamond.addDiamondFunctions(
        //     address(new DiamondCutFacet()),
        //     address(new DiamondLoupeFacet()),
        //     address(new OwnershipFacet()),
        //     address(new ACLFacet()),
        //     address(new GovernanceFacet())
        // );
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // solhint-disable no-complex-fallback
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        // require(facet != address(0), "Diamond: Function does not exist"); - don't need to do this since we check for code below
        LibDiamond.enforceHasContractCode(facet, "Diamond: Facet has no code");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}
}
