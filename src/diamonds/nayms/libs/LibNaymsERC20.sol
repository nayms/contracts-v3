// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";

library LibNaymsERC20 {
    function _balanceOf(address _owner) external view returns (uint256 balance) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        balance = s.balances[_owner];
    }

    function _totalSupply() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.totalSupply;
    }
}
