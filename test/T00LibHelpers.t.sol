// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable-next-line no-global-import
import "./defaults/D00GlobalDefaults.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";

contract T00LibHelpers is D00GlobalDefaults {
    function testGetIdForObjectAtIndexFuzz(uint256 i) public skipWhenForking {
        assertEq(LibHelpers._getIdForObjectAtIndex(i), keccak256(abi.encodePacked(i)));
    }

    function testGetIdForAddressFuzz(address a) public skipWhenForking {
        assertEq(LibHelpers._getIdForAddress(a), bytes32(bytes20(a)));
    }

    function testGetSenderId() public skipWhenForking {
        assertEq(LibHelpers._getSenderId(), LibHelpers._getIdForAddress(msg.sender));
    }

    function testGetAddressFromIdFuzz(bytes32 id) public skipWhenForking {
        assertEq(LibHelpers._getAddressFromId(id), address(bytes20(id)));
    }

    function testAddressToBytes32Fuzz(address a) public skipWhenForking {
        assertEq(LibHelpers._addressToBytes32(a), LibHelpers._bytesToBytes32(abi.encode(a)));
    }

    function testStringToBytes32Fuzz(string memory s) public skipWhenForking {
        assertEq(LibHelpers._stringToBytes32(s), LibHelpers._bytesToBytes32(bytes(s)));
    }

    function testBytes32ToStringFuzz(bytes32 b32) public skipWhenForking {
        assertEq(LibHelpers._bytes32ToString(b32), string(LibHelpers._bytes32ToBytes(b32)));
    }

    function testBytesToBytes32Fuzz(bytes memory b) public skipWhenForking {
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

    function testBytes32ToBytesFuzz(bytes32 b32) public skipWhenForking {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), b32)
        }
        assertEq(LibHelpers._bytes32ToBytes(b32), b);
    }

    function testIdAddressConversionStabilityFuzz(address input) public skipWhenForking {
        bytes32 id = LibHelpers._getIdForAddress(input);
        address addr = LibHelpers._getAddressFromId(id);
        assertEq(input, addr);
        assertEq(id, LibHelpers._getIdForAddress(addr));
    }
}
