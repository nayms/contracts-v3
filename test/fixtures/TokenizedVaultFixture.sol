// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { LibTokenizedVaultIO } from "src/libs/LibTokenizedVaultIO.sol";
import { LibAdmin } from "src/libs/LibAdmin.sol";

contract TokenizedVaultFixture {
    function externalDepositDirect(
        bytes32 _to,
        address _externalTokenAddress,
        uint256 _amount
    ) public {
        // a user can only deposit an approved external ERC20 token
        require(LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress), "extDeposit: invalid ERC20 token");
        LibTokenizedVaultIO._externalDeposit(_to, _externalTokenAddress, _amount);
    }
}
