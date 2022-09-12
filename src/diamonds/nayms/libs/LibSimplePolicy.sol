// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, SimplePolicyStates, Entity, LibAppStorage, SimplePolicy } from "../AppStorage.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibFeeRouter } from "../libs/LibFeeRouter.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";

library LibSimplePolicy {
    event SimplePolicyStateUpdated(bytes32 id, SimplePolicyStates indexed state, address indexed caller);
    event SimplePolicyPremiumPaid(bytes32 indexed _id, uint256 _amount);
    event SimplePolicyClaimPaid(bytes32 indexed _policyId, bytes32 indexed _insuredId, uint256 _amount);

    function _getSimplePolicyInfo(bytes32 _policyId) internal view returns (SimplePolicy memory simplePolicyInfo) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        simplePolicyInfo = s.simplePolicies[_policyId];
    }

    function _checkAndUpdateState(bytes32 _id) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_id];

        if (block.timestamp >= simplePolicy.maturationDate && simplePolicy.state < SimplePolicyStates.Matured) {
            // move to matured state
            simplePolicy.state = SimplePolicyStates.Matured;

            // When the policy matures, the entity regains their capacity that was being utilized for that policy.
            Entity storage entity = s.entities[LibObject._getParent(_id)];
            entity.utilizedCapacity -= simplePolicy.limit;

            // emit event
            emit SimplePolicyStateUpdated(_id, SimplePolicyStates.Matured, msg.sender);
        } else if (block.timestamp >= simplePolicy.startDate && simplePolicy.state < SimplePolicyStates.Active) {
            // move state to active
            simplePolicy.state = SimplePolicyStates.Active;

            // emit event
            emit SimplePolicyStateUpdated(_id, SimplePolicyStates.Active, msg.sender);
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
        LibFeeRouter._payPremiumComissions(_policyId, _amount);

        simplePolicy.premiumsPaid += _amount;

        emit SimplePolicyPremiumPaid(_policyId, _amount);
    }

    function _payClaim(
        bytes32 _policyId,
        bytes32 _insuredEntityId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "invalid claim amount");
        require(LibACL._isInGroup(_insuredEntityId, _policyId, LibHelpers._stringToBytes32(LibConstants.GROUP_INSURED_PARTIES)), "not an insured party");

        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];

        uint256 claimsPaid = simplePolicy.claimsPaid;
        require(simplePolicy.limit >= _amount + claimsPaid, "exceeds policy limit");
        simplePolicy.claimsPaid += _amount;

        LibTokenizedVault._internalTransfer(LibObject._getParent(_policyId), _insuredEntityId, simplePolicy.asset, _amount);

        emit SimplePolicyClaimPaid(_policyId, _insuredEntityId, _amount);
    }
}
