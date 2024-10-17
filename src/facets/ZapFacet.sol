// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
import { LibTokenizedVaultStaking } from "../libs/LibTokenizedVaultStaking.sol";
import { IERC20 } from "../interfaces/IERC20.sol";

contract ZapFacet is Modifiers, ReentrancyGuard {
    /**
     * @notice Approve, deposit, and stake funds into msg.sender's Nayms platform entity in one transaction
     * @dev Approves token transfer, deposits from msg.sender to their associated entity, and stakes the amount
     * @param _externalTokenAddress Token address
     * @param _amount deposit and stake amount
     */
    function zapStake(
        address _externalTokenAddress,
        uint256 _amount
    ) external notLocked nonReentrant assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_EXTERNAL_DEPOSIT) {
        // Check if it's a supported ERC20 token
        require(LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress), "zapStake: invalid ERC20 token");

        // Get the user's entity
        bytes32 entityId = LibObject._getParentFromAddress(msg.sender);
        require(LibEntity._isEntity(entityId), "zapStake: invalid receiver");

        // Approve the token transfer
        IERC20 token = IERC20(_externalTokenAddress);
        require(token.approve(address(this), _amount), "zapStake: approval failed");

        // Perform the deposit
        LibTokenizedVaultIO._externalDeposit(entityId, _externalTokenAddress, _amount);

        // Stake the deposited amount
        LibTokenizedVaultStaking._stake(entityId, entityId, _amount);
    }

    /**
     * @notice Unstake and withdraw funds out of Nayms platform
     * @dev Unstakes, withdraws from entity to an external account
     * @param _entityId Internal ID of the entity the user is withdrawing from
     * @param _receiver External address receiving the funds
     * @param _externalTokenAddress Token address
     * @param _amount amount to unstake and withdraw
     */
    function zapUnstake(
        bytes32 _entityId,
        address _receiver,
        address _externalTokenAddress,
        uint256 _amount
    ) external notLocked nonReentrant assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY) {
        if (!LibACL._hasGroupPrivilege(LibHelpers._getIdForAddress(_receiver), _entityId, LibHelpers._stringToBytes32(LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY)))
            revert ExternalWithdrawInvalidReceiver(_receiver);

        // Unstake the amount
        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);
        LibTokenizedVaultStaking._unstake(parentId, _entityId);

        // Perform the withdrawal directly to the receiver
        LibTokenizedVaultIO._externalWithdraw(_entityId, _receiver, _externalTokenAddress, _amount);
    }
}
