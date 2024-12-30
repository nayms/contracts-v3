// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { PermitSignature, OnboardingApproval } from "../shared/FreeStructs.sol";
import { InvalidERC20Token } from "../shared/CustomErrors.sol";
import { Modifiers } from "../shared/Modifiers.sol";
import { LibTokenizedVaultIO } from "../libs/LibTokenizedVaultIO.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
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
     * @param _stakingEntityId Staking entity ID
     * @param _amountToDeposit Deposit amount
     * @param _amountToStake Stake amount
     * @param _permitSignature The permit signature parameters
     * @param _onboardingApproval The onboarding approval parameters
     */
    function zapStake(
        address _externalTokenAddress,
        bytes32 _stakingEntityId,
        uint256 _amountToDeposit,
        uint256 _amountToStake,
        PermitSignature calldata _permitSignature,
        OnboardingApproval calldata _onboardingApproval
    ) external notLocked nonReentrant {
        if (!LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress)) {
            revert InvalidERC20Token(_externalTokenAddress, "zapStake");
        }

        bytes32 parentId = LibObject._getParentFromAddress(msg.sender);

        if (_onboardingApproval.entityId != 0 && parentId != _onboardingApproval.entityId) {
            LibAdmin._onboardUserViaSignature(_onboardingApproval);
        }

        // Use permit to set allowance
        IERC20(_externalTokenAddress).permit(msg.sender, address(this), _amountToDeposit, _permitSignature.deadline, _permitSignature.v, _permitSignature.r, _permitSignature.s);

        // Perform the deposit
        LibTokenizedVaultIO._externalDeposit(parentId, _externalTokenAddress, _amountToDeposit);

        // Stake the deposited amount
        LibTokenizedVaultStaking._stake(parentId, _stakingEntityId, _amountToStake);
    }

    /**
     * @notice Deposit tokens and execute a limit order in one transaction using permit
     * @dev Uses permit to approve token transfer and performs external deposit and limit order execution
     * @param _externalTokenAddress Token address
     * @param _depositAmount Amount to deposit
     * @param _sellToken Sell token ID
     * @param _sellAmount Sell amount
     * @param _buyToken Buy token ID
     * @param _buyAmount Buy amount
     * @param _permitSignature The permit signature parameters
     * @param _onboardingApproval The onboarding approval parameters
     */
    function zapOrder(
        address _externalTokenAddress,
        uint256 _depositAmount,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        PermitSignature calldata _permitSignature,
        OnboardingApproval calldata _onboardingApproval
    ) external notLocked nonReentrant {
        if (!LibAdmin._isSupportedExternalTokenAddress(_externalTokenAddress)) {
            revert InvalidERC20Token(_externalTokenAddress, "zapOrder");
        }

        bytes32 parentId = _onboardingApproval.entityId;

        bool isOnboardingCP = _onboardingApproval.roleId == LibHelpers._stringToBytes32(LC.ROLE_ENTITY_CP);
        bool isCurrentlyCP = LibACL._isInGroup(parentId, LibHelpers._stringToBytes32(LC.SYSTEM_IDENTIFIER), LibHelpers._stringToBytes32(LC.GROUP_CAPITAL_PROVIDERS));

        if (!isCurrentlyCP && isOnboardingCP) {
            LibAdmin._onboardUserViaSignature(_onboardingApproval);
        }

        LibACL._assertPriviledge(parentId, LC.GROUP_EXECUTE_LIMIT_OFFER);

        // Use permit to set allowance
        IERC20(_externalTokenAddress).permit(msg.sender, address(this), _depositAmount, _permitSignature.deadline, _permitSignature.v, _permitSignature.r, _permitSignature.s);

        // Perform the external deposit
        LibTokenizedVaultIO._externalDeposit(parentId, _externalTokenAddress, _depositAmount);

        // Execute the limit order
        LibMarket._executeLimitOffer(parentId, _sellToken, _sellAmount, _buyToken, _buyAmount, LC.FEE_TYPE_TRADING);
    }
}
