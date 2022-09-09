// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibSwap } from "./LibSwap.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibTokenizedVaultIO } from "../libs/LibTokenizedVaultIO.sol";
import { LibStaking } from "../libs/LibStaking.sol";
import "../libs/Tick.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import { IQuoter } from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import { LibOracle } from "../libs/LibOracle.sol";
import "../libs/Tick.sol";
import "forge-std/console2.sol";

/**
 * @title Nayms Discretionary Fund Library
 * @notice Contains all internal methods for the Nayms Discretionary Fund
 * @dev NDF library
 */
library LibNDF {
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ExcessReached(uint256 excess);
    event SurplusFundPaid(uint256 amount);
    event NaymsBought(bytes32 userID, uint256 amount);
    event TokensSwapped(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the ratio of the value of Nayms to the value of all assets in the NDF
    /// @dev Uses Uniswap LibOracle.getQuoteAtTick() function to get the value of Nayms and each of the external tokens in the NDF. Works out ratio of Nayms value to total value
    function _getNaymsValueRatio() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 digitalAssetValue = 0;

        address naymsAddress = LibHelpers._getAddressFromId(s.naymsTokenId);

        uint256 naymsBalance = LibTokenizedVault._internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), s.naymsTokenId);

        uint256 naymsValue = LibOracle.getQuoteAtTick(getMaxTick(60), uint128(naymsBalance), naymsAddress, WETH);

        uint256 balanceOfAsset;
        for (uint256 i = 0; i < LibAdmin._getSupportedExternalTokens().length; i++) {
            balanceOfAsset = LibTokenizedVault._internalBalanceOf(
                LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER),
                LibHelpers._getIdForAddress(s.supportedExternalTokens[i])
            );
            digitalAssetValue += LibOracle.getQuoteAtTick(getMaxTick(60), uint128(balanceOfAsset), s.supportedExternalTokens[i], WETH);
        }

        uint256 num = naymsValue * 100e18;
        return (num / (naymsValue + digitalAssetValue)) / 1e18;
    }

    /// @notice Get the Nayms discount (As a percentage)
    /// @dev Returns the discount amount when buying _amountNayms worth of Nayms (To no decimal places)
    /// @param _amountNayms The amount of Nayms being bought at discount
    function _getDiscount(uint256 _amountNayms) internal returns (uint256) {
        unchecked {
            AppStorage storage s = LibAppStorage.diamondStorage();

            s.actualNaymsAllocation = _getNaymsValueRatio();

            uint256 np = _amountNayms / 2;

            uint256 numerator = ((s.actualNaymsAllocation * 10 - np - s.targetNaymsAllocation * 10)**3) * s.maxDiscount;

            // If Numerator is bigger than uint256 it got overflow because its <0, return 0;
            if (numerator / 1e18 > 0) {
                return 0;
            }

            numerator = numerator * 1e18;
            uint256 denominator = ((1000 - s.targetNaymsAllocation * 10)**3) * 1000;

            // Dividing with 1e17 get 0 decimal places, 1e16 returns 1 & 1e15 returns 2 decimal places
            s.actualDiscount = ((numerator / denominator) * 1000) / 1e17;

            return s.actualDiscount;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            GENERAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Pay the Sub Surplus Fund
    /// @dev Transfer Nayms to the Sub Surplus Fund
    /// @param _amount the amount of Nayms to transfer
    /// Note: External tokens must be swaped to Nayms before calling this function using the SwapTokens() function
    function _paySubSurplusFund(uint256 _amount) internal {
        require(_amount > 0, "amount must be > 0");

        AppStorage storage s = LibAppStorage.diamondStorage();

        // Transfer nayms to the SSF internally
        LibTokenizedVault._internalTransfer(
            LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER),
            LibHelpers._stringToBytes32(LibConstants.SSF_IDENTIFIER),
            s.naymsTokenId,
            _amount
        );

        emit SurplusFundPaid(_amount);
    }

    /// @notice Buy discounted Nayms
    /// @dev Any user can buy NAYMS at a discount using the diacount token (set in LibAdmin) This function takes in the max they are willing to spend & calculates the amount of discounted NAYMS they can get for that amount. It then performs a Uniswap swap to NAYMS and Stakes that in LibStaking using "createLock"
    /// @param _maxWilling the amount of the discount token a user is willing to spend on Nayms
    function _buyNayms(uint256 _maxWilling) internal {
        require(_maxWilling > 0, "Amount must be > 0");

        AppStorage storage s = LibAppStorage.diamondStorage();

        // Work out NAYMS amount from discount
        uint256 discount = LibNDF._getDiscount(_maxWilling);
        discount = discount * 1000;
        uint256 coeff = 100000 - discount;
        uint256 naymsAmount = ((coeff * _maxWilling) / 100000) + _maxWilling;

        // Transfer discountToken from user to NDF
        LibTokenizedVault._internalTransfer(
            LibHelpers._getIdForAddress(msg.sender),
            LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER),
            LibHelpers._getIdForAddress(s.discountToken),
            _maxWilling
        );

        // Swap discount tokens for NAYMS using Uniswap
        uint256 amountAfterSwap = LibSwap._swapTokensExactInput(s.discountToken, LibHelpers._getAddressFromId(s.naymsTokenId), naymsAmount, 3000);

        // Transfer NAYMS to to Staking Mechanism
        LibTokenizedVault._internalTransfer(
            LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER),
            LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER),
            s.naymsTokenId,
            amountAfterSwap
        );

        // Stake on behalf of user
        LibStaking.createLock(msg.sender, amountAfterSwap, LibConstants.STAKING_MINTIME);
    }

    /// @notice Allows a SysAdmin to swap tokens using UniSwap through LibSwap
    /// @param _tokenIn the token to be exchanged
    /// @param _tokenOut the token to be received from the swap
    /// @param _amountIn the amount of _tokenIn to be swapped
    /// @param _poolFee the fee of the LP
    function _swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint24 _poolFee
    ) internal returns (uint256 amountOut) {
        amountOut = LibSwap._swapTokensExactInput(_tokenIn, _tokenOut, _amountIn, _poolFee);
        emit TokensSwapped(_tokenIn, _tokenOut, _amountIn, amountOut);
    }
}
