// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibAppStorage, AppStorage } from "../AppStorage.sol";
import { INaymsTokenFacet } from "../interfaces/INaymsTokenFacet.sol";

contract NaymsTokenFacet is INaymsTokenFacet {
    /**
     * @dev Get total supply of token.
     * @return total supply.
     */
    function totalSupply() external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.totalSupply;
    }

    /**
     * @dev Get token balance of given wallet.
     * @param addr wallet whose balance to get.
     * @return balance of wallet.
     */
    function balances(address addr) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.balances[addr];
    }
}
