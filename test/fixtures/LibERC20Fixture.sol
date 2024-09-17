// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { LibERC20 } from "src/libs/LibERC20.sol";

/// Create a fixture to test the library LibERC20

contract LibERC20Fixture {
    function decimals(address _token) external view returns (uint8) {
        return LibERC20.decimals(_token);
    }

    function symbol(address _token) external view returns (string memory) {
        return LibERC20.symbol(_token);
    }

    function balanceOf(address _token, address _who) external view returns (uint256) {
        return LibERC20.balanceOf(_token, _who);
    }

    function transferFrom(address _token, address _from, address _to, uint256 _value) external {
        LibERC20.transferFrom(_token, _from, _to, _value);
    }

    function transfer(address _token, address _to, uint256 _value) external {
        LibERC20.transfer(_token, _to, _value);
    }
}
