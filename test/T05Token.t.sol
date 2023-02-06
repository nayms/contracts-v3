// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";

import { MockAccounts } from "./utils/users/MockAccounts.sol";
import { UniswapV3Fixture } from "./fixtures/UniswapV3Fixture.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { IERC20 } from "src/erc20/IERC20.sol";

import { INonfungiblePositionManager } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { INonfungibleTokenPositionDescriptor } from "@uniswap/v3-periphery/contracts/interfaces/INonfungibleTokenPositionDescriptor.sol";

/// @notice Tests for token related functionality
/// @dev These tests fork the mainnet at block 16116906

contract T05TokenTest is D03ProtocolDefaults, MockAccounts, UniswapV3Fixture {
    function setUp() public virtual override {
        string memory mainnetUrl = vm.rpcUrl("mainnet");
        // uint256 mainnetFork = vm.createSelectFork(mainnetUrl, 16116906);
        uint256 mainnetFork = vm.createSelectFork(mainnetUrl);
        super.setUp();

        // Create NAYMS ERC20 token
        // nayms.wrapToken(LibConstants.NAYM_TOKEN_IDENTIFIER);

        // Setup token defaults
        // Equilibrium Level is in basis points
        // nayms.setEquilibriumLevel(2000); // 20% of value in NAYMS token
        // nayms.setMaxDiscount(1000); // 10% discount
    }

    function testToken() public {
        // transfer 15m Nayms to NDF
        // create a pool
        // createPool();
    }

    function testCreatePool() public {
        address _factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        factory = IUniswapV3Factory(_factory);
        nftDescriptor = INonfungibleTokenPositionDescriptor(0x91ae842A5Ffd8d12023116943e72A606179294f3);

        nft = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

        address newPoolAddress = deployTokensAndCreateLP();

        vm.label(newPoolAddress, "new test LP");
        nayms.setLiquidityPool(newPoolAddress);

        int24 baseThreshold = 2400;
        int24 limitThreshold = 1200;
        int24 maxTwapDeviation = 500;
        uint32 twapDuration = 600;
        // Initialize a new Uniswap v3 liquidity pool.
        nayms.initNdf(baseThreshold, limitThreshold, maxTwapDeviation, twapDuration);

        uint32 twapInterval = 0; // The interval of time to fetch the price from.
        nayms.getSqrtTwapX96(newPoolAddress, twapInterval);
        // nayms.getTwap();

        vm.roll(block.timestamp + 501);
        vm.roll(block.timestamp + 1001);
        // nayms.getSqrtTwapX96(newPoolAddress, 100);
        // nayms.getTwap();
    }
}
