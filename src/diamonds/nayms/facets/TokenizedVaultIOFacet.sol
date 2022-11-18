// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { Modifiers } from "../Modifiers.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibTokenizedVaultIO } from "../libs/LibTokenizedVaultIO.sol";
import { LibEntity } from "../libs/LibEntity.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";

/**
 * @title Token Vault IO
 * @notice External interface to the Token Vault
 * @dev Used for external transfers. Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
contract TokenizedVaultIOFacet is Modifiers {
    /**
     * @notice Deposit funds into msg.sender's Nayms platform entity
     * @dev Deposit from msg.sender to their associated entity
     * @param _externalTokenAddress Token address
     * @param _amount deposit amount
     */
    function externalDeposit(address _externalTokenAddress, uint256 _amount) external {
        // a user can only deposit an approved external ERC20 token
        require(LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress), "extDeposit: invalid ERC20 token");
        // a user can only deposit to their valid entity
        bytes32 userId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 entityId = LibObject._getParent(userId);
        require(LibEntity._isEntity(entityId), "extDeposit: invalid receiver");

        LibTokenizedVaultIO._externalDeposit(entityId, _externalTokenAddress, _amount);
    }

    /**
     * @notice Withdraw funds out of Nayms platform
     * @dev Withdraw from entity to an external account
     * @param _entityId Internal ID of the entity the user is withdrawing from
     * @param _receiver Internal ID of the account receiving the funds
     * @param _externalTokenAddress Token address
     * @param _amount amount to withdraw
     */
    function externalWithdrawFromEntity(
        bytes32 _entityId,
        address _receiver,
        address _externalTokenAddress,
        uint256 _amount
    ) external assertEntityAdmin(_entityId) {
        LibTokenizedVaultIO._externalWithdraw(_entityId, _receiver, _externalTokenAddress, _amount);
    }
}
