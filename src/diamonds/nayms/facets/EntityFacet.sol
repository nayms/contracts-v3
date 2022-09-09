// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { Entity, Modifiers, SimplePolicy, Stakeholders, LibObject } from "../AppStorage.sol";
import { LibEntity } from "../libs/LibEntity.sol";
import { ReentrancyGuard } from "../../../utils/ReentrancyGuard.sol";

contract EntityFacet is Modifiers, ReentrancyGuard {
    modifier assertSimplePolicyEnabled(bytes32 _entityId) {
        require(s.entities[_entityId].simplePolicyEnabled, "simple policy creation disabled");
        _;
    }

    function createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata stakeholders,
        SimplePolicy calldata simplePolicy
    ) external assertSimplePolicyEnabled(_entityId) assertSysMgr {
        LibEntity._createSimplePolicy(_policyId, _entityId, stakeholders, simplePolicy);
    }

    function updateAllowSimplePolicy(bytes32 _entityId, bool _allow) external assertSysMgr {
        LibEntity._updateAllowSimplePolicy(_entityId, _allow);
    }

    function enableEntityTokenization(bytes32 _objectId, string memory _symbol) external assertSysAdmin {
        LibObject._enableObjectTokenization(_objectId, _symbol);
    }

    /// @param _amount the amount of entity token that is minted and put on sale
    /// @param _totalPrice the buy amount
    function startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) external nonReentrant assertSysMgr {
        LibEntity._startTokenSale(_entityId, _amount, _totalPrice);
    }

    function updateEntity(bytes32 _entityId, Entity memory _entity) external assertSysMgr {
        LibEntity._updateEntity(_entityId, _entity);
    }

    function getEntityInfo(bytes32 _entityId) external view returns (Entity memory) {
        return LibEntity._getEntityInfo(_entityId);
    }

    //Todo: Add payDividend() function
}
