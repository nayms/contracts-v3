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
// import { TickMath } from "lib/v4-core/contracts/libraries/TickMath.sol";

import "lib/v4-core/test/utils/Deployers.sol";

contract T07UniswapV4 is D03ProtocolDefaults, Deployers {
    using LibHelpers for address;
    using stdStorage for StdStorage;
    using StdStyle for *;
    using Hooks for IHooks;

    address naymsTokenAddress;

    address currency1Address;

    NaymsAccount bob;
    NaymsAccount nlf;

    function setUp() public {
        bob = makeNaymsAcc("Bob");
        nlf = makeNaymsAcc(LC.NLF_IDENTIFIER);

        vm.startPrank(sm.addr);
        hCreateEntity(bob.entityId, bob, entity, "Bob data");
        hCreateEntity(nlf.entityId, nlf, entity, "NLF");
        hCreateEntity(sa.entityId, sa, entity, "System Admin");

        vm.startPrank(address(this));
        initializeManagerRoutersAndPoolsWithLiq(IHooks(address(0)));

        // For these tests, we will use currency0 as the NAYM Token
        naymsTokenAddress = Currency.unwrap(currency0);
        currency1Address = Currency.unwrap(currency1);

        changePrank(sa.addr);
        nayms.addSupportedExternalToken(naymsTokenAddress, 1);
    }

    function testSwap() public {
        // Test the swap function
        deal(naymsTokenAddress, address(bob.addr), 100 ether, true);

        deal(currency1Address, address(sa.addr), 100 ether, true);

        vm.startPrank(bob.addr);
        IERC20(naymsTokenAddress).approve(address(nayms), 100 ether);
        nayms.externalDeposit(naymsTokenAddress, 1 ether);

        nayms.internalTransferFromEntity(sa.entityId, naymsTokenAddress._getIdForAddress(), 1 ether);

        SwapParams memory swapParams = SwapParams({
            key: PoolKey({ currency0: currency0, currency1: currency1, fee: 3000, tickSpacing: 60, hooks: IHooks(address(0)) }),
            params: IPoolManager.SwapParams({ zeroForOne: false, amountSpecified: 1e15, sqrtPriceLimitX96: SQRT_PRICE_2_1 }),
            takeClaims: false,
            settleUsingBurn: false,
            hookData: ""
        });

        address toTokenAddress = Currency.unwrap(currency1);
        bytes32 tokenId = LibHelpers._getIdForAddress(toTokenAddress);

        vm.startPrank(sa.addr);
        IERC20(naymsTokenAddress).approve(address(manager), 100 ether);
        IERC20(currency1Address).approve(address(nayms), 100 ether);

        nayms.swap(manager, swapParams, naymsTokenAddress._getIdForAddress(), tokenId);
    }
}
