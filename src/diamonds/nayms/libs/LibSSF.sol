// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibConstants } from "./LibConstants.sol";
import "../libs/Tick.sol";
import { LibOracle } from "../libs/LibOracle.sol";

library LibSSF {
    event TransferToken(bytes32 _to, bytes32 _from, uint256 _amount);

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
    _estimateAmountOut uses the uniswap V3 library to recieve a conversion between two tokens
    @param _tokenIn is the address of the token we are qouting from
    @param _quoteToken is the address of the token we want the quote of
    @param _amountIn is the amount of the tokenIn that was paid
    @param _sqrtPriceX96 is the sqrt price needed
    @return amountOut is the amount of the quote token that equals the inputted token
     */
    function _estimateAmountOut(
        address _tokenIn,
        address _quoteToken,
        uint256 _amountIn,
        uint160 _sqrtPriceX96
    ) internal pure returns (uint256 amountOut) {
        amountOut = LibOracle.getQuoteAtTick(getMaxTick(60), uint128(_amountIn), _tokenIn, _quoteToken);
    }

    /**
     * @notice Pay `_amountIn` tokens of reward to `_to`
     * @dev Uses the _estimateAmountOut function to calculate the given reward for the user and perform the transfer
     * @param _tokenIn is the token the user paid the premium in
     * @param _amountIn is the amount the user paid
     * @param _to is the address of the user recieving the reward
     */
    function _payRewardsToUser(
        address _tokenIn,
        uint256 _amountIn,
        address _to
    ) internal returns (uint256) {
        //Establishing a connection to the internal storage
        AppStorage storage s = LibAppStorage.diamondStorage();

        //Declaring local variables
        uint256 rewardAmount;

        //Checking the amount coming in is valid and the token they paid in is valid
        require(_amountIn > 0, "Amount must be larger than zero");
        require(_tokenIn != address(0), "Token cannot be zero address");

        //Check whether they paid in DAI or something else
        if (_tokenIn == WETH) {
            //If paid in WETH, we use the parameters to get the quote amount of NAYM
            uint256 amountOut = _estimateAmountOut(WETH, LibHelpers._getAddressFromId(s.naymsTokenId), _amountIn, 0);

            rewardAmount = _payReward(amountOut, _to);
        } else {
            //If paid in another token, we use the parameters to get the quote amount of WETH first
            uint256 firstAmountOut = _estimateAmountOut(_tokenIn, WETH, _amountIn, 0);

            //We use this quote amount of WETH to then get the quote amount of NAYM
            uint256 amountOut = _estimateAmountOut(WETH, LibHelpers._getAddressFromId(s.naymsTokenId), firstAmountOut, 0);

            rewardAmount = _payReward(amountOut, _to);
        }

        //Emit event
        emit TransferToken(LibHelpers._getIdForAddress(_to), LibHelpers._getIdForAddress(address(this)), rewardAmount);

        return rewardAmount;
    }

    /**
    @notice uses the _estimateAmountOut return value to calculate the given reward for the user and perform the transfer
    @param _amountIn is the amount the user paid
    @param _to is the user recieving the reward
    @return returning the value of the end reward paid out
     */
    function _payReward(uint256 _amountIn, address _to) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        //Get the final reward amount based on the current rewards coefficient
        uint256 rewardAmount = (s.rewardsCoefficient * _amountIn) / 1000;

        //Transfer the correct amount from the SSF to the user
        LibTokenizedVault._internalTransfer(LibHelpers._stringToBytes32(LibConstants.SSF_IDENTIFIER), LibHelpers._getIdForAddress(_to), s.naymsTokenId, rewardAmount);

        //Increment our internal storage data holding how much a user has been paid in rewards
        s.userRewards[LibHelpers._getIdForAddress(_to)] += rewardAmount;

        return rewardAmount;
    }
}
