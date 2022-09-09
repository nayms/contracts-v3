// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

library LibMath {
    // These are from https://github.com/nayms/maker-otc/blob/master/contracts/math.sol
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x * 10**18) + (y / 2)) / y;
    }
}
