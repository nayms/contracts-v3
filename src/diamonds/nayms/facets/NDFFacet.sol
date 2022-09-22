// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { ReentrancyGuard } from "src/utils/ReentrancyGuard.sol";
import { Modifiers } from "../AppStorage.sol";
import { LibNDF } from "../libs/LibNDF.sol";

/**
 * @title Nayms Discretionary Fund
 * @notice Facet for the Nayms Discretionary Fund
 * @dev NDF facet
 */
contract NDFFacet is Modifiers, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                            GENERAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getDiscount(uint256 _amountNayms) external returns (uint256) {
        return LibNDF._getDiscount(_amountNayms);
    }

    function getNaymsValueRatio() external returns (uint256) {
        return LibNDF._getNaymsValueRatio();
    }

    /**
     * @notice Pay `_amount` to the SubSurplus Fund
     * @dev Pay the amount to the SSF
     * @param _amount Amount to pay to the SSF
     */
    function paySubSurplusFund(uint256 _amount) external assertSysAdmin nonReentrant {
        LibNDF._paySubSurplusFund(_amount);
    }

    /**
     * @notice Buy `_maxWilling` from NDF
     * @dev Buy discounted tokens from NDF
     * @param _maxWilling Max amount of tokens willing to spend
     */
    function buyNayms(uint256 _maxWilling) external nonReentrant {
        LibNDF._buyNayms(_maxWilling);
    }

    /**
     * @notice Swap `_amountIn` of `_tokenIn` for `_tokenOut` tokens with fee of `_poolFee`
     * @dev Swap tokens on Uniswap
     * @param _tokenIn Token to swap
     * @param _tokenOut Token to get
     * @param _amountIn Amount to swap
     * @param _poolFee Fee payed to the pool
     * @return amountOut Tokens received
     */
    function swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint24 _poolFee
    ) external assertSysAdmin returns (uint256 amountOut) {
        amountOut = LibNDF._swapTokens(_tokenIn, _tokenOut, _amountIn, _poolFee);
    }

    /*//////////////////////////////////////////////////////////////
                         RECEIVER FUNCTION
    //////////////////////////////////////////////////////////////*/

    // function _receive(bytes32 _tokenId, uint256 _amount) internal {
    //     LibTokenizedVault._internalTransfer(LibHelpers._getIdForAddress(msg.sender), LibHelpers._getIdForAddress(address(this)), _tokenId, _amount);
    //     s.digitalAssetIDs.push(_tokenId);
    //     s.actualNaymsAllocation += _amount;
    //     emit LibNDF.BalanceUpdated(s.actualNaymsAllocation - _amount, s.actualNaymsAllocation);
    //     if (s.actualNaymsAllocation >= s.equilibriumLevel) {

    //         LibTokenizedVault._internalTransfer(LibHelpers._getIdForAddress(address(this)), LibConstants.SSF_IDENTIFIER, _tokenId, _amount);

    //         emit LibNDF.ExcessReached(s.actualNaymsAllocation - s.equilibriumLevel);
    //     }
    // }
}
