// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { D03ProtocolDefaults, LibHelpers, LibObject, LC, c } from "./defaults/D03ProtocolDefaults.sol";
import { Vm } from "forge-std/Vm.sol";
import { StdStyle } from "forge-std/Test.sol";
import { MockAccounts } from "./utils/users/MockAccounts.sol";
import { LibUniswap } from "src/libs/LibUniswap.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "@uniswap/v3-periphery/contracts/SwapRouter.sol";

string constant v3FactoryArtifact = "node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json";
string constant weth9Artifact = "test/contracts/WETH9.json";

interface WETH9 is IERC20Minimal {
    function deposit() external payable;
}

contract UniswapFixture {
    IUniswapV3Factory public factory;
    WETH9 public weth9;
    SwapRouter public router;

    TestERC20[] tokens;
    NonfungibleTokenPositionDescriptor nftDescriptor;
    NonfungiblePositionManager nft;

    address wallet = vm.addr(1);
    address trader = vm.addr(2);

    struct Balances {
        uint256 weth9;
        uint256 token0;
        uint256 token1;
        uint256 token2;
    }

    function setUp() public virtual {
        // Deploys WETH9
        address _weth9 = deployCode(weth9Artifact);
        weth9 = WETH9(_weth9);

        // deploy V3 Core's Factory contract
        address _factory = deployCode(v3FactoryArtifact);
        factory = IUniswapV3Factory(_factory);

        // Hook them on the router
        router = new SwapRouter(_factory, _weth9);

        // ---
        // deploy the 3 tokens
        address token0 = address(new TestERC20(type(uint256).max / 2));
        address token1 = address(new TestERC20(type(uint256).max / 2));
        address token2 = address(new TestERC20(type(uint256).max / 2));
        require(token0 < token1, "unexpected token ordering 1");
        require(token2 < token1, "unexpected token ordering 2");
        // pre-sorted manually, TODO do this properly
        tokens.push(TestERC20(token1));
        tokens.push(TestERC20(token2));
        tokens.push(TestERC20(token0));

        // we don't need to do the lib linking, forge deploys
        // all libraries and does it for us
        nftDescriptor = new NonfungibleTokenPositionDescriptor(address(tokens[0]), bytes32("ETH"));

        nft = new NonfungiblePositionManager(address(factory), address(weth9), address(nftDescriptor));

        vm.deal(trader, 100 ether);
        vm.deal(wallet, 100 ether);

        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].approve(address(router), type(uint256).max);
            tokens[i].approve(address(nft), type(uint256).max);
            vm.prank(trader);
            tokens[i].approve(address(router), type(uint256).max);
            tokens[i].transfer(trader, 1_000_000 * 1 ether);
        }
    }
}

contract UniswapV3FlashSwapTest is D03ProtocolDefaults, MockAccounts, SwapRouterFixture {
    using StdStyle for *;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IERC20 private realWeth = IERC20(WETH);
    IERC20 private realDai = IERC20(DAI);
    IERC20 private realUsdc = IERC20(USDC);

    function setUp() public {}

    function testSingleHop() public {
        weth.deposit{ value: 1e18 }();
        weth.approve(address(this), 1e18);

        uint amountOut = LibUniswap.swapExactInputSingleHop(WETH, DAI, 3000, 1e18);

        c.log("DAI", amountOut);
    }

    function testFlashSwap() public {
        c.log("FLASH".green());
        // USDC / WETH pool
        address pool0 = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
        uint24 fee0 = 3000;
        address pool1 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
        uint24 fee1 = 500;
    }
}
