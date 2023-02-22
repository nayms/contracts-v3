// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { Modifiers } from "../Modifiers.sol";

import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibTokenizedVaultIO } from "../libs/LibTokenizedVaultIO.sol";
import { LibUniswapV3Twap } from "../libs/LibUniswapV3Twap.sol";

error PriceOracleNotFound(address tokenAddress);
error IncorrectPriceCalculation();

contract NDFFacet is Modifiers {
    // todo just use sqrtPriceX96 ratio
    // todo adjust calculations for token decimal places

    function getNaymsValueRatio() external returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 ndfId = LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER);
        uint256 naymsBalanceInNDF = LibTokenizedVault._internalBalanceOf(ndfId, s.naymsTokenId);

        address naymsPriceOracle = s.uniswapPools[address(this)]; // nayms token

        // uint160 naymsSqrtPriceX96 = LibUniswapV3Twap.getSqrtTwapX96(naymsPriceOracle, s.twapIntervals[naymsPriceOracle]);

        uint256 naymsPriceX96 = LibUniswapV3Twap.getPriceX96FromSqrtPriceX96(LibUniswapV3Twap.getSqrtTwapX96(naymsPriceOracle, s.twapIntervals[naymsPriceOracle]));

        uint256 naymsValue = naymsBalanceInNDF * naymsPriceX96;

        // value of all other supported tokens in NDF
        uint256 numSupportedTokens = LibAdmin._getSupportedExternalTokens().length;

        uint256 balanceOfTokenInNDF;
        uint256 valueOfAssets; // balance * price of other assets in the NDF (not including NAYMS token)
        uint160 sqrtPriceX96;
        uint256 priceX96;
        address supportedTokenAddress;
        address priceOracle;
        for (uint256 i; i < numSupportedTokens; ++i) {
            supportedTokenAddress = LibAdmin._getSupportedExternalTokens()[i];
            priceOracle = s.uniswapPools[supportedTokenAddress];

            if (priceOracle == address(0)) {
                revert PriceOracleNotFound(supportedTokenAddress);
            }

            balanceOfTokenInNDF = LibTokenizedVault._internalBalanceOf(ndfId, LibHelpers._getIdForAddress(supportedTokenAddress));
            if (balanceOfTokenInNDF > 0) {
                sqrtPriceX96 = LibUniswapV3Twap.getSqrtTwapX96(priceOracle, s.twapIntervals[priceOracle]);

                priceX96 = LibUniswapV3Twap.getPriceX96FromSqrtPriceX96(sqrtPriceX96);

                // todo more robust checking here, such as % change in price since last check
                if (priceX96 == 0) {
                    revert IncorrectPriceCalculation();
                }

                valueOfAssets += balanceOfTokenInNDF * priceX96;
            }
        }

        uint256 naymsValueRatio = (naymsValue * LibConstants.BP_FACTOR) / valueOfAssets;
        return naymsValueRatio;
    }

    /// @return naymsValueRatio the ratio of NAYMS value to total assets (not including NAYMS) in the NDF
    /// @return naymsValuePurchased the amount of NAYMS purchased calculated based on the discounted price for NAYMS
    function _getAdjustedNaymsValueRatio(address tokenAddress, uint256 amount) internal returns (uint256 naymsValueRatio, uint256 naymsValuePurchased) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 ndfId = LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER);

        (uint256 naymsPriceX96, uint256 naymsValue) = _getValueOfAsset(address(this), LibTokenizedVault._internalBalanceOf(ndfId, s.naymsTokenId));

        // value of all other supported tokens in NDF
        uint256 numSupportedTokens = LibAdmin._getSupportedExternalTokens().length;

        uint256 balanceOfTokenInNDF;
        uint256 valueOfAssets; // balance * price of other assets in the NDF (not including NAYMS token)
        uint256 priceX96;
        address supportedTokenAddress;
        uint256 valueOfAsset;
        for (uint256 i; i < numSupportedTokens; ++i) {
            supportedTokenAddress = LibAdmin._getSupportedExternalTokens()[i];

            balanceOfTokenInNDF = LibTokenizedVault._internalBalanceOf(ndfId, LibHelpers._getIdForAddress(supportedTokenAddress));
            if (balanceOfTokenInNDF > 0) {
                // include the value of the token being added to the NDF
                if (tokenAddress == supportedTokenAddress) {
                    balanceOfTokenInNDF += amount;
                }

                (priceX96, valueOfAsset) = _getValueOfAsset(supportedTokenAddress, balanceOfTokenInNDF);

                // todo more robust checking here, such as % change in price since last check
                if (priceX96 == 0) {
                    revert IncorrectPriceCalculation();
                }

                valueOfAssets += valueOfAsset;

                // subtract the value of the NAYMS token being removed from the NDF
                naymsValue -= amount * priceX96; // todo fix this math

                naymsValuePurchased = (amount * priceX96) / ((naymsPriceX96 * 9000) / LibConstants.BP_FACTOR); // 10% discount on nayms token
            }
        }

        // ratio is calculated with the value of the NON DISCOUNTED NAYMS token
        naymsValueRatio = (naymsValue * LibConstants.BP_FACTOR) / valueOfAssets;
    }

    function _getValueOfAsset(address tokenAddress, uint256 amount) internal view returns (uint256 priceX96, uint256 value) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        address priceOracle = s.uniswapPools[tokenAddress];
        if (priceOracle == address(0)) {
            revert PriceOracleNotFound(tokenAddress);
        }
        uint160 sqrtPriceX96 = LibUniswapV3Twap.getSqrtTwapX96(priceOracle, s.twapIntervals[priceOracle]);
        uint256 priceX96 = LibUniswapV3Twap.getPriceX96FromSqrtPriceX96(sqrtPriceX96);

        value = amount * priceX96;
    }

    error TokenNotSupported(address tokenAddress);
    error NaymsValueRatioTooLow(uint256 valueRatio);

    /// @param tokenAddress ERC20 token address - selling this token for discounted NAYMS
    /// @param amount amount of NAYMS to buy at discounted price
    function buyDiscountedNayms(address tokenAddress, uint256 amount) external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // is the token supported (by the NDF)?
        if (!s.externalTokenSupported[tokenAddress]) {
            revert TokenNotSupported(tokenAddress);
        }

        (uint256 naymsValueRatio, uint256 naymsValuePurchased) = _getAdjustedNaymsValueRatio(tokenAddress, amount);
        if (naymsValueRatio < s.equilibriumLevel) {
            revert NaymsValueRatioTooLow(naymsValueRatio);
        }

        // Any individual can purchase discounted NAYMS, individuals do not need to be an onboarded user with existing entities.
        // An individual who is not a current user will have an internal account (an object) created with their address

        // todo should an individual first have to onboard to buy discounted NAYMS?
        bytes32 individualId = LibHelpers._getIdForAddress(msg.sender);
        if (!LibObject._isObject(individualId)) {
            LibObject._createObject(individualId);
            // todo assign a role to this individual?
        }

        bytes32 ndfId = LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER);

        // individual does an external deposit of tokenAddress into the NDF
        LibTokenizedVaultIO._externalDeposit(ndfId, tokenAddress, amount);

        LibTokenizedVault._internalTransfer(ndfId, individualId, s.naymsTokenId, naymsValuePurchased);
    }
}
