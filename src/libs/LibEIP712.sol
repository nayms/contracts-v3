// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

library LibEIP712 {
    function _domainSeparatorV4() internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return block.chainid == s.initialChainId ? s.initialDomainSeparator : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(s.name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}
