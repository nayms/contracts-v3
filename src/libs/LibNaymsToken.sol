// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";

/// @notice Contains internal methods for Nayms token functionality
library LibNaymsToken {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function _name() internal pure returns (string memory) {
        return "Nayms Token";
    }

    function _symbol() internal pure returns (string memory) {
        return "NAYM";
    }

    function _decimals() internal pure returns (uint8) {
        return 18;
    }

    function _totalSupply() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.totalSupply;
    }

    function _balanceOf(address addr) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.balances[addr];
    }

    function _increaseAllowance(address _spender, uint256 _value) external returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 l_allowance = s.allowance[msg.sender][_spender];
        uint256 newAllowance = l_allowance + _value;

        require(newAllowance >= l_allowance, "NAYMFacet: Allowance increase overflowed");

        s.allowance[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        success = true;
    }

    function _decreaseAllowance(address _spender, uint256 _value) external returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 l_allowance = s.allowance[msg.sender][_spender];

        require(l_allowance >= _value, "NAYMFacet: Allowance decreased below 0");

        l_allowance -= _value;
        s.allowance[msg.sender][_spender] = l_allowance;
        emit Approval(msg.sender, _spender, l_allowance);
        success = true;
    }

    function _allowance(address _owner, address _spender) external view returns (uint256 remaining_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        remaining_ = s.allowance[_owner][_spender];
    }
}
