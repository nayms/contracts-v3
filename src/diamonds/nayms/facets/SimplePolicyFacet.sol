// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, Entity, Modifiers, SimplePolicy } from "../AppStorage.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibSimplePolicy } from "../libs/LibSimplePolicy.sol";

contract SimplePolicyFacet is Modifiers {
    function paySimplePremium(bytes32 _policyId, uint256 _amount) external {
        bytes32 senderId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 payerEntityId = LibObject._getParent(senderId);

        LibSimplePolicy._payPremium(payerEntityId, _policyId, _amount);
    }

    function paySimpleClaim(
        bytes32 _policyId,
        bytes32 _insuredId,
        uint256 _amount
    ) external assertSysMgr {
        LibSimplePolicy._payClaim(_policyId, _insuredId, _amount);
    }

    function getSimplePolicyInfo(bytes32 _policyId) external view returns (SimplePolicy memory) {
        return LibSimplePolicy._getSimplePolicyInfo(_policyId);
    }

    function checkAndUpdateSimplePolicyState(bytes32 _policyId) external {
        LibSimplePolicy._checkAndUpdateState(_policyId);
    }
}
