// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { D03ProtocolDefaults, LibHelpers, LibObject, LC, c } from "./defaults/D03ProtocolDefaults.sol";
import { Vm } from "forge-std/Vm.sol";
import { StdStyle } from "forge-std/Test.sol";
import { MockAccounts } from "./utils/users/MockAccounts.sol";

import { IERC20 } from "src/interfaces/IERC20.sol";

contract UniswapV3FlashSwapTest is D03ProtocolDefaults, MockAccounts {
    using StdStyle for *;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    IERC20 private realWeth = IERC20(WETH);

    function setUp() public {}

    function testFlashSwap() public {
        c.log("FLASH".green());
        // USDC / WETH pool
        address pool0 = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
        uint24 fee0 = 3000;
        address pool1 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
        uint24 fee1 = 500;

        // Approve WETH fee
        uint wethMaxFee = 1e18;
        c.log("writing balance to: account0".cyan());
        deal(WETH, account0, wethMaxFee);
        // vm.startPrank(account0);
        // writeTokenBalance(account0, naymsAddress, WETH, wethMaxFee);
        // vm.stopPrank();

        c.log("doing external deposit".cyan());
        vm.startPrank(account0);
        nayms.externalDeposit(wethAddress, wethMaxFee);
        vm.stopPrank();

        // realWeth.deposit{ value: wethMaxFee }();
        realWeth.approve(address(nayms), wethMaxFee);
        c.log("WETH approved");

        uint balBefore = realWeth.balanceOf(address(this));
        c.log("BEFORE flash swap", balBefore);
        // nayms.flashSwap(pool0, fee1, WETH, USDC, 10 ether);
        // c.log("AFTER flash swap");
        // uint balAfter = realWeth.balanceOf(address(this));

        // if (balAfter >= balBefore) {
        //     c.log("WETH profit", balAfter - balBefore);
        // } else {
        //     c.log("WETH loss", balBefore - balAfter);
        // }
    }
}
