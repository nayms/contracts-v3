// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { PermitSignature } from "../shared/FreeStructs.sol";
import { Modifiers } from "../shared/Modifiers.sol";
import { LibTokenizedVaultIO } from "../libs/LibTokenizedVaultIO.sol";
import { LibEntity } from "../libs/LibEntity.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";
import { LibTokenizedVaultStaking } from "../libs/LibTokenizedVaultStaking.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { LibMarket } from "../libs/LibMarket.sol";

contract ZapFacet is Modifiers, ReentrancyGuard {
    /**
     * @notice Deposit and stake funds into msg.sender's Nayms platform entity in one transaction using permit
     * @dev Uses permit to approve token transfer, deposits from msg.sender to their associated entity, and stakes the amount
     * @param _externalTokenAddress Token address
     * @param _entityId Staking entity ID
     * @param _amountToDeposit Deposit amount
     * @param _amountToStake Stake amount
     * @param _permitSignature The permit signature parameters
     */
    function zapStake(
        address _externalTokenAddress,
        bytes32 _entityId,
        uint256 _amountToDeposit,
        uint256 _amountToStake,
        PermitSignature calldata _permitSignature
    ) external notLocked nonReentrant {
        // Check if it's a supported ERC20 token
        require(LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress), "zapStake: invalid ERC20 token");

        // Get the user's entity
        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);
        require(LibEntity._isEntity(parentId), "zapStake: invalid receiver");

        // Use permit to set allowance
        IERC20(_externalTokenAddress).permit(msg.sender, address(this), _amountToDeposit, _permitSignature.deadline, _permitSignature.v, _permitSignature.r, _permitSignature.s);

        // Perform the deposit
        LibTokenizedVaultIO._externalDeposit(parentId, _externalTokenAddress, _amountToDeposit);

        // Stake the deposited amount
        LibTokenizedVaultStaking._stake(parentId, _entityId, _amountToStake);
    }

    /**
     * @notice Deposit tokens and execute a limit order in one transaction using permit
     * @dev Uses permit to approve token transfer and performs external deposit and limit order execution
     * @param _externalTokenAddress Token address
     * @param _amount Amount to deposit
     * @param _sellToken Sell token ID
     * @param _sellAmount Sell amount
     * @param _buyToken Buy token ID
     * @param _buyAmount Buy amount
     * @param _permitSignature The permit signature parameters
     * @return offerId_ The ID of the created offer
     * @return buyTokenCommissionsPaid_ Commissions paid in buy token
     * @return sellTokenCommissionsPaid_ Commissions paid in sell token
     */
    function zapOrder(
        address _externalTokenAddress,
        uint256 _amount,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        PermitSignature calldata _permitSignature
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
        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);
        require(LibEntity._isEntity(parentId), "zapOrder: invalid entity");

        // Use permit to set allowance
        IERC20(_externalTokenAddress).permit(msg.sender, address(this), _amount, _permitSignature.deadline, _permitSignature.v, _permitSignature.r, _permitSignature.s);

        // Perform the external deposit
        LibTokenizedVaultIO._externalDeposit(parentId, _externalTokenAddress, _amount);

        // Execute the limit order
        return LibMarket._executeLimitOffer(parentId, _sellToken, _sellAmount, _buyToken, _buyAmount, LC.FEE_TYPE_TRADING);
    }
}
