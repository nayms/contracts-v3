// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Default test setup part 00
///         Global level defaults for any and all solidity projects using solc >=0.7.6
///         Setup accounts, signers, labels

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { IERC20 } from "src/erc20/IERC20.sol";

contract D00GlobalDefaults is Test {
    using stdStorage for StdStorage;

    address public account0;
    address public deployer; // deployer and owner of the diamond

    //// test tokens ////
    MockERC20 public weth;
    address public wethAddress;

    MockERC20 public wbtc;
    address public wbtcAddress;

    function setUp() public virtual {
        weth = new MockERC20("Wrapped ETH", "WETH", 18);
        wethAddress = address(weth);

        wbtc = new MockERC20("Wrapped BTC", "WBTC", 18);
        wbtcAddress = address(wbtc);

        vm.label(wethAddress, "WETH");
        vm.label(wbtcAddress, "WBTC");

        console2.log("\n -- D00 Global Defaults\n");

        if (block.chainid == 1) {
            account0 = 0x2dF0a6dB2F0eF1269bE777C856A7665eeC00649f;
            deployer = 0xd5c10a9a09B072506C7f062E4f313Af29AdD9904; // original deployer of Nayms diamond
        }

        if (block.chainid == 31337) {
            account0 = address(this);
            deployer = address(this);
            console2.log("Test contract address, aka account0", address(this));
        }
        console2.log("msg.sender during setup", msg.sender);

        vm.label(account0, "Account 0");
        vm.label(deployer, "Owner of Nayms Diamond");
    }

    function writeTokenBalance(
        address to,
        address from,
        address token,
        uint256 amount
    ) public {
        IERC20 tkn = IERC20(token);
        tkn.approve(address(from), amount);

        stdstore.target(token).sig(IERC20(token).balanceOf.selector).with_key(to).checked_write(amount);

        assertEq(tkn.balanceOf(to), amount, "balance should INCREASE (after mint)");
    }
}
