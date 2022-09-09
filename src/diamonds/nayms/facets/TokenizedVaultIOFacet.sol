// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, Modifiers, LibHelpers } from "../AppStorage.sol";

import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibTokenizedVaultIO } from "../libs/LibTokenizedVaultIO.sol";

/**
 * @dev Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
contract TokenizedVaultIOFacet is Modifiers {
    function externalDepositToEntity(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external {
        // a user can only deposit to a valid entity
        require(s.existingEntities[_receiverId], "extDeposit: invalid receiver");

        LibTokenizedVaultIO._externalDeposit(_receiverId, _externalTokenAddress, _amount);
    }

    function externalDeposit(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external {
        LibTokenizedVaultIO._externalDeposit(_receiverId, _externalTokenAddress, _amount);
    }

    function externalWithdrawFromEntity(
        bytes32 _entityId,
        address _receiver,
        address _externalTokenAddress,
        uint256 _amount
    ) external assertEntityAdmin(_entityId) {
        LibTokenizedVaultIO._externalWithdraw(_entityId, _receiver, _externalTokenAddress, _amount);
    }
}
