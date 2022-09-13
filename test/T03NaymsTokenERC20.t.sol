// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { Vm } from "forge-std/Vm.sol";

contract T03NaymsTokenERC20 is D03ProtocolDefaults {
    uint internal constant INITIAL_SUPPLY = 1_000_000_000e18;

    function setUp() public virtual override {
        super.setUp();
    }

    function testNaymsErc20InvariantMetadata() public {
        assertEq(nayms.name(), "Nayms Token");
        assertEq(nayms.symbol(), "NAYM");
        assertEq(nayms.decimals(), 18);
        assertEq(nayms.totalSupply(), INITIAL_SUPPLY);
    }

    function testInitialBalances() public {
        assertEq(nayms.balanceOf(account0), INITIAL_SUPPLY);
    }

    function testTransferFailedDueToInsufficientBalance() public {
        vm.expectRevert("NAYM: Not enough NAYM to transfer");
        nayms.transfer(signer1, 1_000_000_001e18);
    }

    function testTransferSucceedsWithEnoughBalance() public {
        assertTrue(nayms.transfer(signer1, 100));
        assertEq(nayms.balanceOf(account0), INITIAL_SUPPLY - 100);
        assertEq(nayms.balanceOf(signer1), 100);
    }

    function testTransferSuccessEmitsEvent() public {
        vm.recordLogs();

        nayms.transfer(signer1, 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 3);
        assertEq(entries[0].topics[0], keccak256("Transfer(address,address,uint256)"));
        assertEq(entries[0].topics[1], LibHelpers._addressToBytes32(account0));
        assertEq(entries[0].topics[2], LibHelpers._addressToBytes32(signer1));
        (uint amnt) = abi.decode(entries[0].data, (uint));
        assertEq(amnt, 100);
    }
}
