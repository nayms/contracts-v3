// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { StdStorage, stdStorage, StdStyle, StdAssertions } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults, c, LC, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { StakingConfig, StakingState, SwapParams, CallbackData } from "src/shared/FreeStructs.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { StakingFixture } from "test/fixtures/StakingFixture.sol";
import { DummyToken } from "./utils/DummyToken.sol";
import { LibTokenizedVaultStaking } from "src/libs/LibTokenizedVaultStaking.sol";
import { IERC20 } from "src/interfaces/IERC20.sol";

import "lib/v4-core/test/utils/Deployers.sol";

contract T07UniswapV4 is D03ProtocolDefaults, Deployers {
    using LibHelpers for address;
    using stdStorage for StdStorage;
    using StdStyle for *;
    using Hooks for IHooks;

    address naymsTokenAddress;

    function setUp() public {
        vm.startPrank(address(this));
        initializeManagerRoutersAndPoolsWithLiq(IHooks(address(0)));

        // For these tests, we will use currency0 as the NAYM Token
        naymsTokenAddress = Currency.unwrap(currency0);

        changePrank(systemAdmin);
        nayms.addSupportedExternalToken(naymsTokenAddress, 1);
    }

    function testSwap() public {
        // Test the swap function

        deal(naymsTokenAddress, address(systemAdmin), 1 ether, true);

        // nayms.externalDeposit(naymsTokenAddress, 1 ether);

        SwapParams memory swapParams = SwapParams({
            key: PoolKey({ currency0: currency0, currency1: currency1, fee: 3000, tickSpacing: 60, hooks: IHooks(address(0)) }),
            params: IPoolManager.SwapParams({ zeroForOne: true, amountSpecified: 1 ether, sqrtPriceLimitX96: 0 }),
            takeClaims: false,
            settleUsingBurn: false,
            hookData: ""
        });

        address toTokenAddress = Currency.unwrap(currency1);
        bytes32 tokenId = LibHelpers._getIdForAddress(toTokenAddress);

        nayms.swap(manager, swapParams, naymsTokenId, tokenId);
    }
}
