// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";

/// @notice Contains internal methods for Nayms token functionality
library LibNaymsToken {
    function _totalSupply() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.totalSupply;
    }

    function _balanceOf(address addr) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.balances[addr];
    }
}
