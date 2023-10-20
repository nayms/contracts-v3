// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AppStorage, LibAppStorage } from "src/shared/AppStorage.sol";
import { LibSimplePolicy } from "src/libs/LibSimplePolicy.sol";

import { SimplePolicy } from "src/shared/FreeStructs.sol";

contract SimplePolicyFixture {
    function getFullInfo(bytes32 _policyId) public view returns (SimplePolicy memory) {
        return LibSimplePolicy._getSimplePolicyInfo(_policyId);
    }

    function update(bytes32 _policyId, SimplePolicy memory simplePolicy) public {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.simplePolicies[_policyId] = simplePolicy;
    }
}
