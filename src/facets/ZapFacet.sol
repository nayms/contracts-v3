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
import { LibMarket } from "../libs/LibMarket.sol";

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

    function zapOrder(
        address _externalTokenAddress,
        uint256 _amount,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    )
        external
        notLocked
        nonReentrant
        assertPrivilege(LibObject._getParentFromAddress(msg.sender), LC.GROUP_EXECUTE_LIMIT_OFFER)
        returns (uint256 offerId_, uint256 buyTokenCommissionsPaid_, uint256 sellTokenCommissionsPaid_)
    {
        // Check if it's a supported ERC20 token
        require(LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress), "zapOrder: invalid ERC20 token");

        // Get the user's entity
        bytes32 entityId = LibObject._getParentFromAddress(msg.sender);
        require(LibEntity._isEntity(entityId), "zapOrder: invalid entity");

        // Approve the token transfer to the ZapFacet contract
        IERC20 token = IERC20(_externalTokenAddress);
        require(token.approve(address(this), _amount), "zapOrder: approval failed");

        // Perform the external deposit
        LibTokenizedVaultIO._externalDeposit(entityId, _externalTokenAddress, _amount);

        // Execute the limit order
        // Assumption: executeLimitOrder is a function that takes entityId, token address, amount, and order parameters
        return LibMarket._executeLimitOffer(entityId, _sellToken, _sellAmount, _buyToken, _buyAmount, LC.FEE_TYPE_TRADING);
    }
}
