// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { LibHelpers } from "../src/diamonds/nayms/libs/LibHelpers.sol";

contract T01LibHelpers is Test {
    function testGetIdForObjectAtIndexFuzz(uint256 i) public {
        assertEq(LibHelpers._getIdForObjectAtIndex(i), keccak256(abi.encodePacked(i)));
    }

    function testGetIdForAddressFuzz(address a) public {
        assertEq(LibHelpers._getIdForAddress(a), bytes32(bytes20(a)));
    }

    function testGetSenderId() public {
        assertEq(LibHelpers._getSenderId(), LibHelpers._getIdForAddress(msg.sender));
    }

    function testGetAddressFromIdFuzz(bytes32 id) public {
        bytes32 mask = 0x0000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
        bytes32 bottom12Bytes = id & mask;

        if (bottom12Bytes != 0) {
            vm.expectRevert("Invalid external token address");
            assertEq(LibHelpers._getAddressFromId(id), address(bytes20(id)));
        } else {
            assertEq(LibHelpers._getAddressFromId(id), address(bytes20(id)));
        }
    }

    function testStringToBytes32Fuzz(string memory s) public {
        assertEq(LibHelpers._stringToBytes32(s), LibHelpers._bytesToBytes32(bytes(s)));
    }

    function testBytesToBytes32Fuzz(bytes memory b) public {
        if (b.length == 0) {
            assertEq(LibHelpers._bytesToBytes32(b), 0x0);
        } else {
            bytes32 result;
            assembly {
                result := mload(add(b, 32))
            }
            assertEq(LibHelpers._bytesToBytes32(b), result);
        }
    }

    function testBytes32ToBytesFuzz(bytes32 b32) public {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), b32)
        }
        assertEq(LibHelpers._bytes32ToBytes(b32), b);
    }

    function testIdAddressConversionStabilityFuzz(address input) public {
        bytes32 id = LibHelpers._getIdForAddress(input);
        address addr = LibHelpers._getAddressFromId(id);
        assertEq(input, addr);
        assertEq(id, LibHelpers._getIdForAddress(addr));
    }
}
