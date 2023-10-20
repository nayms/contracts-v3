// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { Vm } from "forge-std/Vm.sol";

/// @dev DSILib DiamondStateInspector
/// Helper library for tests
library DSILib {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    bytes32 internal constant APPSTORAGE_SYSADMINS = 0x1ab5ce5b595c6e94c5fba2e588bf4eafa8b384a4fb6e188b892768e695c1bff1;

    function sysAdmins(address proxyAddress) internal view returns (uint256) {
        bytes32 sysAdminsBytes32 = vm.load(proxyAddress, APPSTORAGE_SYSADMINS);

        return abi.decode(abi.encodePacked(sysAdminsBytes32), (uint256));
    }

    function write_sysAdmins(address proxyAddress, uint256 _sysAdmins) internal {
        vm.store(proxyAddress, APPSTORAGE_SYSADMINS, bytes32(_sysAdmins));
    }
}
