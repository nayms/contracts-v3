// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { Entity, SimplePolicy } from "../AppStorage.sol";
import { LibACL } from "./LibACL.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";
import { LibHelpers } from "./LibHelpers.sol";

library LibSimplePolicy {
    event SimplePolicyStateUpdated(bytes32 id, address indexed caller);
    event SimplePolicyPremiumPaid(bytes32 indexed id, uint256 amount);
    event SimplePolicyClaimPaid(bytes32 indexed _claimId, bytes32 indexed policyId, bytes32 indexed insuredId, uint256 amount);

    function _getSimplePolicyInfo(bytes32 _policyId) internal view returns (SimplePolicy memory simplePolicyInfo) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        simplePolicyInfo = s.simplePolicies[_policyId];
    }

    function _checkAndUpdateState(bytes32 _id) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_id];

        if (block.timestamp >= simplePolicy.maturationDate && simplePolicy.fundsLocked) {
            // When the policy matures, the entity regains their capacity that was being utilized for that policy.
            Entity storage entity = s.entities[LibObject._getParent(_id)];
            entity.utilizedCapacity -= simplePolicy.limit;
            simplePolicy.fundsLocked = false;

            // emit event
            emit SimplePolicyStateUpdated(_id, msg.sender);
        }
    }

    function _payPremium(
        bytes32 _payerEntityId,
        bytes32 _policyId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "invalid premium amount");

        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 policyEntityId = LibObject._getParent(_policyId);
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];

        LibTokenizedVault._internalTransfer(_payerEntityId, policyEntityId, simplePolicy.asset, _amount);
        LibFeeRouter._payPremiumCommissions(_policyId, _amount);

        simplePolicy.premiumsPaid += _amount;

        emit SimplePolicyPremiumPaid(_policyId, _amount);
    }

    function _payClaim(
        bytes32 _claimId,
        bytes32 _policyId,
        bytes32 _insuredEntityId,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_amount > 0, "invalid claim amount");
        require(LibACL._isInGroup(_insuredEntityId, _policyId, LibHelpers._stringToBytes32(LibConstants.GROUP_INSURED_PARTIES)), "not an insured party");

        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];

        uint256 claimsPaid = simplePolicy.claimsPaid;
        require(simplePolicy.limit >= _amount + claimsPaid, "exceeds policy limit");
        simplePolicy.claimsPaid += _amount;

        LibObject._createObject(_claimId);

        LibTokenizedVault._internalTransfer(LibObject._getParent(_policyId), _insuredEntityId, simplePolicy.asset, _amount);

        emit SimplePolicyClaimPaid(_claimId, _policyId, _insuredEntityId, _amount);
    }
}
