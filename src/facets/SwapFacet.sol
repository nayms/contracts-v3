// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { LibAdmin } from "src/libs/LibAdmin.sol";
import { LibConstants as LC } from "src/libs/LibConstants.sol";
import { LibTokenizedVault } from "src/libs/LibTokenizedVault.sol";
import { Modifiers } from "src/shared/Modifiers.sol";
import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";

import { IPoolManager } from "v4-core/interfaces/IPoolManager.sol";
import { PoolKey } from "v4-core/types/PoolKey.sol";
import { BalanceDelta } from "v4-core/types/BalanceDelta.sol";
import { Currency } from "v4-core/types/Currency.sol";
import { CurrencySettler } from "lib/v4-core/test/utils/CurrencySettler.sol";
import { SwapParams, CallbackData } from "../shared/FreeStructs.sol";
import { StateLibrary } from "v4-core/libraries/StateLibrary.sol";
import { TransientStateLibrary } from "v4-core/libraries/TransientStateLibrary.sol";

/**
 * @title Swap
 * @notice Facet for working with Swaps
 * @dev Swap facet
 */
contract SwapFacet is Modifiers {
    using CurrencySettler for Currency;
    // using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;

    function swap(
        IPoolManager _manager,
        SwapParams memory swapParams,
        bytes32 _fromTokenId,
        bytes32 _toTokenId
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_ADMINS) returns (BalanceDelta delta) {
        // NLFID: makeId(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256(bytes(name))))
        bytes32 nlfId = 0x454e5449545900000000000079356590a83c6af5a59580e3ec1b0924626bbfdf;

        // swapParams.amountSpecified
        // LibTokenizedVault._internalBurn(nlfId, _fromTokenId, uint256(swapParams.params.amountSpecified));

        // Swap tokens
        delta = abi.decode(
            _manager.unlock(abi.encode(CallbackData(msg.sender, swapParams.key, swapParams.params, swapParams.takeClaims, swapParams.settleUsingBurn, swapParams.hookData))),
            (BalanceDelta)
        );

        LibTokenizedVault._internalMint(nlfId, _toTokenId, uint256(uint128(delta.amount0())));
    }

    function unlockCallback(bytes calldata rawData) external returns (bytes memory) {
        IPoolManager _manager = IPoolManager(msg.sender);

        // Decode the callback data
        CallbackData memory data = abi.decode(rawData, (CallbackData));

        // Initial balance checks (optional, but recommended for debugging and validation)
        (, , int256 deltaBefore0) = _fetchBalances(_manager, data.key.currency0, data.sender, address(this));
        (, , int256 deltaBefore1) = _fetchBalances(_manager, data.key.currency1, data.sender, address(this));

        require(deltaBefore0 == 0, "deltaBefore0 is not equal to 0");
        require(deltaBefore1 == 0, "deltaBefore1 is not equal to 0");

        // Execute the swap on Uniswap V4 pool
        BalanceDelta delta = _manager.swap(data.key, data.params, data.hookData);

        // Post-swap balance checks
        (, , int256 deltaAfter0) = _fetchBalances(_manager, data.key.currency0, data.sender, address(this));
        (, , int256 deltaAfter1) = _fetchBalances(_manager, data.key.currency1, data.sender, address(this));

        if (data.params.zeroForOne) {
            if (data.params.amountSpecified < 0) {
                // exact input, 0 for 1
                require(deltaAfter0 >= data.params.amountSpecified, "deltaAfter0 is not greater than or equal to data.params.amountSpecified");
                require(delta.amount0() == deltaAfter0, "delta.amount0() is not equal to deltaAfter0");
                require(deltaAfter1 >= 0, "deltaAfter1 is not greater than or equal to 0");
            } else {
                // exact output, 0 for 1
                require(deltaAfter0 <= 0, "deltaAfter0 is not less than or equal to zero");
                require(delta.amount1() == deltaAfter1, "delta.amount1() is not equal to deltaAfter1");
                require(deltaAfter1 <= data.params.amountSpecified, "deltaAfter1 is not less than or equal to data.params.amountSpecified");
            }
        } else {
            if (data.params.amountSpecified < 0) {
                // exact input, 1 for 0
                require(deltaAfter1 >= data.params.amountSpecified, "deltaAfter1 is not greater than or equal to data.params.amountSpecified");
                require(delta.amount1() == deltaAfter1, "delta.amount1() is not equal to deltaAfter1");
                require(deltaAfter0 >= 0, "deltaAfter0 is not greater than or equal to 0");
            } else {
                // exact output, 1 for 0
                require(deltaAfter1 <= 0, "deltaAfter1 is not less than or equal to 0");
                require(delta.amount0() == deltaAfter0, "delta.amount0() is not equal to deltaAfter0");
                require(deltaAfter0 <= data.params.amountSpecified, "deltaAfter0 is not less than or equal to data.params.amountSpecified");
            }
        }

        // Post-swap balance handling
        if (deltaAfter0 < 0) {
            data.key.currency0.settle(_manager, data.sender, uint256(-deltaAfter0), data.settleUsingBurn);
        }
        if (deltaAfter1 < 0) {
            data.key.currency1.settle(_manager, data.sender, uint256(-deltaAfter1), data.settleUsingBurn);
        }
        if (deltaAfter0 > 0) {
            data.key.currency0.take(_manager, data.sender, uint256(deltaAfter0), data.takeClaims);
        }
        if (deltaAfter1 > 0) {
            data.key.currency1.take(_manager, data.sender, uint256(deltaAfter1), data.takeClaims);
        }

        // Return the encoded delta
        return abi.encode(delta);
    }

    function _fetchBalances(
        IPoolManager _manager,
        Currency currency,
        address user,
        address deltaHolder
    ) internal view returns (uint256 userBalance, uint256 poolBalance, int256 delta) {
        userBalance = currency.balanceOf(user);
        poolBalance = currency.balanceOf(address(_manager));
        delta = _manager.currencyDelta(deltaHolder, currency);
    }
}
