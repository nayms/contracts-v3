// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibTokenizedVaultIO } from "src/libs/LibTokenizedVaultIO.sol";
import { LibAdmin } from "src/libs/LibAdmin.sol";
import { InvalidERC20Token } from "src/shared/CustomErrors.sol";

contract TokenizedVaultFixture {
    function externalDepositDirect(bytes32 _to, address _externalTokenAddress, uint256 _amount) public {
        if (!LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress)) {
            revert InvalidERC20Token(_externalTokenAddress, "extDeposit");
        }
        LibTokenizedVaultIO._externalDeposit(_to, _externalTokenAddress, _amount);
    }
}
