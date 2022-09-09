// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibAppStorage, AppStorage, LibConstants, LibHelpers, Entity, SimplePolicy, Stakeholders } from "../AppStorage.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { LibMarket } from "../libs/LibMarket.sol";

import "../../../utils/ECDSA.sol";

library LibEntity {
    using ECDSA for bytes32;

    event EntityUpdated(bytes32 entityId);
    event SimplePolicyCreated(bytes32 indexed id, bytes32 entityId);
    event TokenSaleStarted(bytes32 indexed entityId, uint256 offerId);

    function _validateSimplePolicyCreation(bytes32 _entityId, SimplePolicy calldata simplePolicy) internal view {
        require(simplePolicy.limit > 0, "limit not > 0");

        bool isEntityAdmin = LibACL._isInGroup(LibHelpers._getSenderId(), _entityId, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS));
        require(isEntityAdmin, "must be entity admin");

        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        uint256 collateralRatio = entity.collateralRatio;
        uint256 maxCapital = entity.maxCapital;
        require(collateralRatio > 0 && maxCapital > 0, "currency disabled");

        uint256 newTotalLimit = entity.totalLimit + simplePolicy.limit;
        require(maxCapital >= newTotalLimit, "max capital exceeded");

        uint256 balance = LibTokenizedVault._internalBalanceOf(_entityId, simplePolicy.asset);
        require(balance >= (newTotalLimit * collateralRatio) / 1000, "collateral ratio not met");
    }

    function _createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata stakeholders,
        SimplePolicy calldata simplePolicy
    ) internal {
        _validateSimplePolicyCreation(_entityId, simplePolicy);

        AppStorage storage s = LibAppStorage.diamondStorage();

        // kp todo: what is trying to be done here? totalLimit is not being updated in AppStorage - is this desired?
        Entity memory entity = s.entities[_entityId];
        entity.totalLimit += simplePolicy.limit;

        LibObject._createObject(_policyId, _entityId, "");
        s.simplePolicies[_policyId] = simplePolicy;

        require(stakeholders.entityIds.length == stakeholders.signatures.length, "incorrect number of signatures");
        uint256 rolesCount = stakeholders.roles.length;

        for (uint256 i = 0; i < rolesCount; i++) {
            address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(_policyId), stakeholders.signatures[i]);
            bytes32 signerId = LibHelpers._getIdForAddress(signer);

            require(LibACL._isInGroup(signerId, stakeholders.entityIds[i], LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)), "invalid stakeholder");
            LibACL._assignRole(stakeholders.entityIds[i], _policyId, stakeholders.roles[i]);
        }

        emit SimplePolicyCreated(_policyId, _entityId);
    }

    function _updateAllowSimplePolicy(bytes32 _entityId, bool _allow) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.entities[_entityId].simplePolicyEnabled = _allow;
    }

    /// @param _amount the amount of entity token that is minted and put on sale
    /// @param _totalPrice the buy amount
    function _startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) internal {
        require(_amount > 0, "mint amount must be > 0");
        require(_totalPrice > 0, "total price must be > 0");

        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        LibTokenizedVault._internalMint(_entityId, _entityId, _amount);

        (uint256 offerId, , ) = LibMarket._executeLimitOffer(_entityId, _entityId, _amount, entity.assetId, _totalPrice, LibConstants.FEE_SCHEDULE_STANDARD);

        emit TokenSaleStarted(_entityId, offerId);
    }

    function _updateEntity(bytes32 _entityId, Entity memory _entity) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.entities[_entityId] = _entity;
        emit EntityUpdated(_entityId);
    }

    function _getEntityInfo(bytes32 _entityId) internal view returns (Entity memory entity) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        entity = s.entities[_entityId];
    }
}
