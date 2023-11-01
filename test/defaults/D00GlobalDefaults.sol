// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// solhint-disable no-console
// solhint-disable no-global-import

import { console2 as c } from "forge-std/Test.sol";
import { CommonBase } from "forge-std/Base.sol";
import { StdStorage, stdStorage } from "forge-std/StdStorage.sol";
import { StdAssertions } from "forge-std/StdAssertions.sol";
import { IERC20 } from "src/interfaces/IERC20.sol";

/// @notice Default test setup part 00
///         Global level defaults for any and all solidity projects using solc >=0.7.6
///         Setup accounts, signers, labels

// deployer, owner, system admin
// For local tests, account0 will be the owner and the deployer. This will be the test contract address.
// systemAdmin will be another account. owner and system admins must be mutually exclusive.

abstract contract D00GlobalDefaults is CommonBase, StdAssertions {
    using stdStorage for StdStorage;

    address public immutable account0 = address(this);

    // address public account1;
    // address public account2;

    constructor() payable {
        c.log("\n Test SETUP:");
        c.log("\n -- D00 Global Defaults\n");

        c.log("Test contract address, aka account0, deployer, owner", address(this));
        c.log("msg.sender during setup", msg.sender);
    }

    function writeTokenBalance(address to, address from, address token, uint256 amount) public {
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
