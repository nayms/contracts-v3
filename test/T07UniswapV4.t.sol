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

        vm.label(naymsTokenAddress, "NAYM TOKEN");
        changePrank(sa.addr);
        nayms.addSupportedExternalToken(naymsTokenAddress, 1);
    }

    function testSwap() public {
        // NLFID: makeId(LC.OBJECT_TYPE_ENTITY, bytes20(keccak256(bytes(name))))
        bytes32 nlfId = 0x454e5449545900000000000079356590a83c6af5a59580e3ec1b0924626bbfdf;

        // Test the swap function
        deal(naymsTokenAddress, address(bob.addr), 100 ether, true);
        deal(currency1Address, address(sa.addr), 100 ether, true);

        // Record initial balances
        uint256 bobInitialExternalBalance = IERC20(naymsTokenAddress).balanceOf(bob.addr);
        uint256 bobInitialInternalBalance = nayms.internalBalanceOf(bob.id, naymsTokenAddress._getIdForAddress());
        uint256 saInitialCurrency1Balance = IERC20(currency1Address).balanceOf(sa.addr);
        uint256 nlfInitialCurrency1Balance = nayms.internalBalanceOf(nlfId, currency1Address._getIdForAddress());

        // Bob approves and deposits 1 ether of naymsToken
        vm.startPrank(bob.addr);
        IERC20(naymsTokenAddress).approve(address(nayms), 1 ether);
        nayms.externalDeposit(naymsTokenAddress, 1 ether);

        // Verify Bob's balances after deposit
        uint256 bobFinalExternalBalance = IERC20(naymsTokenAddress).balanceOf(bob.addr);
        uint256 bobFinalInternalBalance = nayms.internalBalanceOf(bob.entityId, naymsTokenAddress._getIdForAddress());
        assertEq(bobFinalExternalBalance, bobInitialExternalBalance - 1 ether, "Bob's external balance should decrease by 1 ether");
        assertEq(bobFinalInternalBalance, bobInitialInternalBalance + 1 ether, "Bob's internal balance should increase by 1 ether");

        // Transfer 1 ether of naymsToken from sa.entityId to nlfId
        nayms.internalTransferFromEntity(sa.entityId, naymsTokenAddress._getIdForAddress(), 1 ether);

        // Record the user's parent internal balance of naymsToken before swap
        uint256 userInitialNaymsBalance = nayms.internalBalanceOf(sa.entityId, naymsTokenAddress._getIdForAddress());

        SwapParams memory swapParams = SwapParams({
            key: PoolKey({ currency0: currency0, currency1: currency1, fee: 3000, tickSpacing: 60, hooks: IHooks(address(0)) }),
            params: IPoolManager.SwapParams({ zeroForOne: false, amountSpecified: 1e15, sqrtPriceLimitX96: SQRT_PRICE_2_1 }),
            takeClaims: false,
            settleUsingBurn: false,
            hookData: ""
        });

        address toTokenAddress = Currency.unwrap(currency1);
        bytes32 tokenId = LibHelpers._getIdForAddress(toTokenAddress);

        // SA approves tokens for the swap
        vm.startPrank(sa.addr);
        IERC20(naymsTokenAddress).approve(address(manager), 100 ether);
        IERC20(currency1Address).approve(address(nayms), 100 ether);

        // Record user's currency1 balance before swap
        uint256 userCurrency1BalanceBeforeSwap = nayms.internalBalanceOf(sa.entityId, currency1Address._getIdForAddress());

        // Perform the swap
        nayms.swap(manager, swapParams, naymsTokenAddress._getIdForAddress(), tokenId, sa.entityId);

        // Record user's balances after swap
        uint256 userCurrency1BalanceAfterSwap = nayms.internalBalanceOf(sa.entityId, currency1Address._getIdForAddress());
        uint256 userFinalNaymsBalance = nayms.internalBalanceOf(sa.entityId, naymsTokenAddress._getIdForAddress());

        // Assertions
        // Check that user's currency1 internal balance increased
        assertGt(userCurrency1BalanceAfterSwap, userCurrency1BalanceBeforeSwap, "user's currency1 balance should increase after swap");

        // Check that user's naymsToken internal balance decreased
        assertEq(userFinalNaymsBalance, userInitialNaymsBalance - uint256(swapParams.params.amountSpecified), "user's naymsToken balance should decrease by swap amount");

        // Check that SA's currency1 balance decreased due to the swap fees or amounts
        uint256 saFinalCurrency1Balance = IERC20(currency1Address).balanceOf(sa.addr);
        assertLt(saFinalCurrency1Balance, saInitialCurrency1Balance, "SA's currency1 external balance should decrease after swap");
    }
}
