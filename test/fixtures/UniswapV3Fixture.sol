// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { INonfungiblePositionManager } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { INonfungibleTokenPositionDescriptor } from "@uniswap/v3-periphery/contracts/interfaces/INonfungibleTokenPositionDescriptor.sol";
import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

// reference: https://github.com/gakonst/v3-periphery-foundry/blob/main/contracts/foundry-tests/SwapRouter.t.sol
uint256 constant PRECISION = 2**96;

// Computes the sqrt of the u64x96 fixed point price given the AMM reserves
function encodePriceSqrt(uint256 reserve1, uint256 reserve0) pure returns (uint160) {
    return uint160(sqrt((reserve1 * PRECISION * PRECISION) / reserve0));
}

// Fast sqrt, taken from Solmate.
function sqrt(uint256 x) pure returns (uint256 z) {
    assembly {
        // Start off with z at 1.
        z := 1

        // Used below to help find a nearby power of 2.
        let y := x

        // Find the lowest power of 2 that is at least sqrt(x).
        if iszero(lt(y, 0x100000000000000000000000000000000)) {
            y := shr(128, y) // Like dividing by 2 ** 128.
            z := shl(64, z) // Like multiplying by 2 ** 64.
        }
        if iszero(lt(y, 0x10000000000000000)) {
            y := shr(64, y) // Like dividing by 2 ** 64.
            z := shl(32, z) // Like multiplying by 2 ** 32.
        }
        if iszero(lt(y, 0x100000000)) {
            y := shr(32, y) // Like dividing by 2 ** 32.
            z := shl(16, z) // Like multiplying by 2 ** 16.
        }
        if iszero(lt(y, 0x10000)) {
            y := shr(16, y) // Like dividing by 2 ** 16.
            z := shl(8, z) // Like multiplying by 2 ** 8.
        }
        if iszero(lt(y, 0x100)) {
            y := shr(8, y) // Like dividing by 2 ** 8.
            z := shl(4, z) // Like multiplying by 2 ** 4.
        }
        if iszero(lt(y, 0x10)) {
            y := shr(4, y) // Like dividing by 2 ** 4.
            z := shl(2, z) // Like multiplying by 2 ** 2.
        }
        if iszero(lt(y, 0x8)) {
            // Equivalent to 2 ** z.
            z := shl(1, z)
        }

        // Shifting right by 1 is like dividing by 2.
        z := shr(1, add(z, div(x, z)))
        z := shr(1, add(z, div(x, z)))
        z := shr(1, add(z, div(x, z)))
        z := shr(1, add(z, div(x, z)))
        z := shr(1, add(z, div(x, z)))
        z := shr(1, add(z, div(x, z)))
        z := shr(1, add(z, div(x, z)))

        // Compute a rounded down version of z.
        let zRoundDown := div(x, z)

        // If zRoundDown is smaller, use it.
        if lt(zRoundDown, z) {
            z := zRoundDown
        }
    }
}

uint24 constant FEE_LOW = 500;
uint24 constant FEE_MEDIUM = 3000;
uint24 constant FEE_HIGH = 10000;

int24 constant TICK_LOW = 10;
int24 constant TICK_MEDIUM = 60;
int24 constant TICK_HIGH = 200;

function getMinTick(int24 tickSpacing) pure returns (int24) {
    return (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
}

function getMaxTick(int24 tickSpacing) pure returns (int24) {
    return (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
}

contract UniswapV3Fixture {
    IUniswapV3Factory public factory;
    INonfungiblePositionManager public nft;
    INonfungibleTokenPositionDescriptor public nftDescriptor;

    function createPool(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) public returns (address newPoolAddress) {
        if (token0 > token1) {
            address tmp = token0;
            token0 = token1;
            token1 = tmp;
        }
        newPoolAddress = nft.createAndInitializePoolIfNecessary(token0, token1, FEE_MEDIUM, encodePriceSqrt(1, 1));

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: FEE_MEDIUM,
            tickLower: getMinTick(TICK_MEDIUM),
            tickUpper: getMaxTick(TICK_MEDIUM),
            amount0Desired: 1000000,
            amount1Desired: 100000,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 10
        });

        // todo update 'to' address
        TransferHelper.safeApprove(token0, 0x91ae842A5Ffd8d12023116943e72A606179294f3, 100000);
        TransferHelper.safeApprove(token1, 0x91ae842A5Ffd8d12023116943e72A606179294f3, 100000);

        // Note Call this when the pool does exist and is initialized.
        // Note that if the pool is created but not initialized a method does not exist, i.e. the pool is assumed to be initialized.
        // Note that the pool defined by token_A/token_B and fee tier 0.3% must already be created and initialized in order to mint
        nft.mint(params);
    }

    function deployTokensAndCreateLP() public returns (address newPoolAddress) {
        MockERC20 token0 = new MockERC20("Test1", "TEST1", 18);

        token0.mint(address(msg.sender), 100000 ether);

        token0.approve(address(nft), 10000 ether);

        MockERC20 token1 = new MockERC20("Test2", "TEST2", 18);

        token1.mint(address(msg.sender), 100000 ether);

        token1.approve(address(nft), 10000 ether);

        // vm.label(address(token0), "dummy token 0");
        // vm.label(address(token1), "dummy token 1");
        // nayms.approve(address(nft), 10000 ether);

        newPoolAddress = createPool(address(token0), address(token1), 1000, 1000);
    }
}
