// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable no-console
// solhint-disable no-global-import
import { StdStorage, stdStorage, console2, Test } from "forge-std/Test.sol";
import { IERC20 } from "src/erc20/IERC20.sol";

/// @notice Default test setup part 00
///         Global level defaults for any and all solidity projects using solc >=0.7.6
///         Setup accounts, signers, labels

// deployer, owner, system admin
// For local tests, account0 will be the owner and the deployer. This will be the test contract address.
// systemAdmin will be another account. owner and system admins must be mutually exclusive.

contract D00GlobalDefaults is Test {
    using stdStorage for StdStorage;
    address public account0 = address(this);

    uint256 public MAINNET_FORK_BLOCK_NUMBER = 15615850;
    uint256 public GOERLI_FORK_BLOCK_NUMBER = 7661570;

    function setUp() public virtual {
        console2.log("\n -- D00 Global Defaults\n");

        console2.log("Test contract address, aka account0, deployer, owner", address(this));
        console2.log("msg.sender during setup", msg.sender);
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

    function enforceHasContractCode(address _contract, string memory _errorMessage) public view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
