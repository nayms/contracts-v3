// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { Modifiers } from "../Modifiers.sol";

import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibUniswapV3Twap } from "../libs/LibUniswapV3Twap.sol";

error PriceOracleNotFound(address tokenAddress);
error IncorrectPriceCalculation();

contract NDFFacet is Modifiers {
    // todo just use sqrtPriceX96 ratio
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
        uint256 totalAssetsValue; // balance * price of other assets in the NDF (not including NAYMS token)
        uint160 sqrtPriceX96;
        uint256 priceX96;
        for (uint256 i; i < numSupportedTokens; ++i) {
            address supportedTokenAddress = LibAdmin._getSupportedExternalTokens()[i];
            address priceOracle = s.uniswapPools[supportedTokenAddress];

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

                totalAssetsValue += balanceOfTokenInNDF * priceX96;
            }
        }

        uint256 naymsValueRatio = (naymsValue * LibConstants.BP_FACTOR) / totalAssetsValue;
        return naymsValueRatio;
    }
}
