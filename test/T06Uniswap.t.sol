// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { D03ProtocolDefaults, LibHelpers, LibObject, LC, c } from "./defaults/D03ProtocolDefaults.sol";
import { Vm } from "forge-std/Vm.sol";
import { StdStyle } from "forge-std/Test.sol";
import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { Entity } from "src/shared/FreeStructs.sol";
import { LibUniswap } from "src/libs/LibUniswap.sol";

// import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import { TransferHelper } from "src/utils/TransferHelper.sol";

import { ERC20 } from "@openzeppelin5/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin5/contracts/token/ERC20/IERC20.sol";
import { ERC20Permit } from "@openzeppelin5/contracts/token/ERC20/extensions/ERC20Permit.sol";

import "test/utils/uniswap/Tick.sol";
import "test/utils/uniswap/Math.sol";

// import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Factory } from "test/contracts/uniswap-interfaces/IUniswapV3Factory.sol";
// import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { ISwapRouter } from "test/contracts/uniswap-interfaces/ISwapRouter.sol";
// import { INonfungibleTokenPositionDescriptor } from "@uniswap/v3-periphery/contracts/interfaces/INonfungibleTokenPositionDescriptor.sol";
import { INonfungibleTokenPositionDescriptor } from "test/contracts/uniswap-interfaces/INonfungibleTokenPositionDescriptor.sol";
// import { INonfungiblePositionManager } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import { INonfungiblePositionManager } from "test/contracts/uniswap-interfaces/INonfungiblePositionManager.sol";

string constant weth9Artifact = "test/contracts/WETH9.json";
// string constant v3FactoryArtifact = "test/contracts/uniswap-v3/UniswapV3Factory.sol/UniswapV3Factory.json";
string constant v3FactoryArtifact = "lib/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json";
// string constant swapRouterArtifact = "test/contracts/uniswap-v3/SwapRouter.sol/SwapRouter.json";
string constant swapRouterArtifact = "lib/v3-periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json";
// string constant nftPositionDescriptorArtifact = "test/contracts/uniswap-v3/NonfungibleTokenPositionDescriptor.sol/NonfungibleTokenPositionDescriptor.json";
string constant nftPositionDescriptorArtifact = "lib/v3-periphery/artifacts/contracts/NonfungibleTokenPositionDescriptor.sol/NonfungibleTokenPositionDescriptor.json";
// string constant nftPositionManagerArtifact = "test/contracts/uniswap-v3/NonfungiblePositionManager.sol/NonfungiblePositionManager.json";
string constant nftPositionManagerArtifact = "lib/v3-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json";

interface WETH9 is IERC20 {
    function deposit() external payable;
}

contract TestERC20 is ERC20Permit {
    constructor(string memory name, string memory symbol, uint256 amountToMint) ERC20(name, symbol) ERC20Permit(name) {
        _mint(msg.sender, amountToMint);
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

contract UniswapFixture is D03ProtocolDefaults {
    IUniswapV3Factory public factory;
    ISwapRouter public router;
    WETH9 public weth9;

    TestERC20[] tokens;
    INonfungibleTokenPositionDescriptor nftDescriptor;
    INonfungiblePositionManager nft;

    address wallet = vm.addr(1);
    address trader = vm.addr(2);

    struct Balances {
        uint256 weth9;
        uint256 token0;
        uint256 token1;
        uint256 token2;
    }

    function setUp() public virtual {
        // Deploy WETH9
        address _weth9 = deployCode(weth9Artifact);
        weth9 = WETH9(_weth9);

        // deploy V3 Core's Factory contract
        address _factory = deployCode(v3FactoryArtifact);
        // factory = IUniswapV3Factory(_factory);
        factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

        // Hook them to the router
        // router = new SwapRouter(_factory, _weth9);
        address _router = deployCode(swapRouterArtifact, abi.encode(_factory, _weth9));
        router = ISwapRouter(_router);

        // deploy the 3 tokens
        address token0 = address(new TestERC20("Token0", "TK0", type(uint256).max / 2));
        address token1 = address(new TestERC20("Token1", "TK1", type(uint256).max / 2));
        address token2 = address(new TestERC20("Token2", "TK2", type(uint256).max / 2));
        require(token0 < token1, "unexpected token ordering 1");
        require(token1 < token2, "unexpected token ordering 2");
        tokens.push(TestERC20(token2));
        tokens.push(TestERC20(token1));
        tokens.push(TestERC20(token0));

        console.log("setting up NFT Descriptor");
        // nftDescriptor = new NonfungibleTokenPositionDescriptor(address(tokens[0]), bytes32("ETH"));
        // address _nftDescriptor = deployCode(nftPositionDescriptorArtifact, abi.encode(address(tokens[0]), bytes32("ETH")));
        // nftDescriptor = INonfungibleTokenPositionDescriptor(_nftDescriptor);
        nftDescriptor = INonfungibleTokenPositionDescriptor(0x91ae842A5Ffd8d12023116943e72A606179294f3);

        console.log("setting up NFT");
        // nft = new NonfungiblePositionManager(address(factory), address(weth9), address(nftDescriptor));
        // address _nft = deployCode(nftPositionManagerArtifact, abi.encode(address(factory), address(weth9), address(nftDescriptor)));
        // nft = INonfungiblePositionManager(_nft);
        nft = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }
}

contract T06Uniswap is MockAccounts, UniswapFixture {
    using StdStyle for *;

    address internal constant DAI_CONSTANT = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function createPool(address token0, address token1, uint256 amount0, uint256 amount1) public {
        if (token0 > token1) {
            address tmp = token0;
            token0 = token1;
            token1 = tmp;
        }
        nft.createAndInitializePoolIfNecessary(token0, token1, FEE_MEDIUM, encodePriceSqrt(1, 1));

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: FEE_MEDIUM,
            tickLower: getMinTick(TICK_MEDIUM),
            tickUpper: getMaxTick(TICK_MEDIUM),
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(account0),
            deadline: block.timestamp + 10
        });

        TransferHelper.safeApprove(token0, 0x91ae842A5Ffd8d12023116943e72A606179294f3, amount0);
        TransferHelper.safeApprove(token1, 0x91ae842A5Ffd8d12023116943e72A606179294f3, amount1);

        // Note Call this when the pool does exist and is initialized.
        // Note that if the pool is created but not initialized a method does not exist, i.e. the pool is assumed to be initialized.
        // Note that the pool defined by token_A/token_B and fee tier 0.3% must already be created and initialized in order to mint
        nft.mint(params);
    }

    //Checks the swap will fail if the amountIn is 0 or less
    function testFailLibSwap() public {
        vm.startPrank(account0);
        LibUniswap._swapTokensExactInput(DAI_CONSTANT, address(weth), 0, 3000);
        vm.expectRevert("Amount must be larger than zero");
        vm.stopPrank();
    }

    function testLibSwap() public {
        vm.startPrank(account0);

        createLiquidityPool();

        // Expecting 98 when sending 100, because of the fee
        uint256 amountOut = LibUniswap._swapTokensExactInput(address(tokens[0]), address(tokens[1]), 100, 3000);
        assertEq(amountOut, 90);
        vm.stopPrank();
    }

    function createLiquidityPool() public {
        tokens[0].mint(account0, 100000 ether);
        tokens[0].approve(address(nft), 10000 ether);
        tokens[1].mint(account0, 100000 ether);
        tokens[1].approve(address(nft), 10000 ether);
        // nayms.approve(address(nft), 10000 ether);

        createPool(address(tokens[0]), address(tokens[1]), 1000, 1000);
    }
}
