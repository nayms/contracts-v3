// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Modifiers } from "../shared/Modifiers.sol";
import { LibTokenizedVaultIO } from "../libs/LibTokenizedVaultIO.sol";
import { LibEntity } from "../libs/LibEntity.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { ExternalWithdrawInvalidReceiver } from "../shared/CustomErrors.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";

/**
 * @title Token Vault IO
 * @notice External interface to the Token Vault
 * @dev Used for external transfers. Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
contract TokenizedVaultIOFacet is Modifiers, ReentrancyGuard {
    /**
     * @notice Deposit funds into msg.sender's Nayms platform entity
     * @dev Deposit from msg.sender to their associated entity
     * @param _externalTokenAddress Token address
     * @param _amount deposit amount
     */
    function externalDeposit(
        address _externalTokenAddress,
        uint256 _amount
    ) external notLocked(msg.sig) nonReentrant assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_EXTERNAL_DEPOSIT) {
        // a user can only deposit an approved external ERC20 token
        require(LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress), "extDeposit: invalid ERC20 token");
        // a user can only deposit to their valid entity
        bytes32 entityId = LibObject._getParentFromAddress(msg.sender);
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
    ) external notLocked(msg.sig) nonReentrant assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY) {
        if (!LibACL._hasGroupPrivilege(LibHelpers._getIdForAddress(_receiver), _entityId, LibHelpers._stringToBytes32(LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY)))
            revert ExternalWithdrawInvalidReceiver(_receiver);
        LibTokenizedVaultIO._externalWithdraw(_entityId, _receiver, _externalTokenAddress, _amount);
    }
}
