// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Entity, FeeSchedule } from "../shared/AppStorage.sol";
import { Modifiers } from "../shared/Modifiers.sol";
import { LibEntity } from "../libs/LibEntity.sol";
import { LibObject } from "../libs/LibObject.sol";

import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibConstants as LC } from "../libs/LibConstants.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";
import { LibEIP712 } from "src/libs/LibEIP712.sol";
import { LibFeeRouter } from "src/libs/LibFeeRouter.sol";

/**
 * @title Entities
 * @notice Used to handle policies and token sales
 * @dev Mainly used for token sale and policies
 */
contract EntityFacet is Modifiers, ReentrancyGuard {
    /**
     * @dev Returns the domain separator for the current chain.
     */
    function domainSeparatorV4() external view returns (bytes32) {
        return LibEIP712._domainSeparatorV4();
    }

    function hashTypedDataV4(bytes32 structHash) external view returns (bytes32) {
        return LibEIP712._hashTypedDataV4(structHash);
    }

    /**
     * @notice Enable an entity to be tokenized
     * @param _objectId ID of the entity
     * @param _symbol The symbol assigned to the entity token
     * @param _name The name assigned to the entity token
     */
    function enableEntityTokenization(
        bytes32 _objectId,
        string memory _symbol,
        string memory _name,
        uint256 _minimumSell
    ) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS) {
        LibObject._enableObjectTokenization(_objectId, _symbol, _name, _minimumSell);
    }

    /**
     * @notice Update entity token name and symbol
     * @param _entityId ID of the entity
     * @param _symbol New entity token symbol
     * @param _name New entity token name
     */
    function updateEntityTokenInfo(bytes32 _entityId, string memory _symbol, string memory _name) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS) {
        LibObject._updateTokenInfo(_entityId, _symbol, _name);
    }

    /**
     * @notice Start token sale of `_amount` tokens for total price of `_totalPrice`
     * @dev Entity tokens are minted when the sale is started
     * @param _entityId ID of the entity
     * @param _amount amount of entity tokens to put on sale
     * @param _totalPrice total price of the tokens
     */
    function startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) external notLocked(msg.sig) nonReentrant assertPrivilege(_entityId, LC.GROUP_START_TOKEN_SALE) {
        LibEntity._startTokenSale(_entityId, _amount, _totalPrice);
    }

    /**
     * @notice Check if an entity token is wrapped as ERC20
     * @param _entityId ID of the entity
     * @return true if it is, false otherwise
     */
    function isTokenWrapped(bytes32 _entityId) external view returns (bool) {
        return LibObject._isObjectTokenWrapped(_entityId);
    }

    /**
     * @notice Update entity metadata
     * @param _entityId ID of the entity
     * @param _updateEntity metadata of the entity that can be updated
     */
    function updateEntity(bytes32 _entityId, Entity calldata _updateEntity) external assertPrivilege(LibAdmin._getSystemId(), LC.GROUP_SYSTEM_MANAGERS) {
        LibEntity._updateEntity(_entityId, _updateEntity);
    }

    /**
     * @notice Get the data for entity with ID: `_entityId`
     * @dev Get the Entity data for a given entityId
     * @param _entityId ID of the entity
     */
    function getEntityInfo(bytes32 _entityId) external view returns (Entity memory) {
        return LibEntity._getEntityInfo(_entityId);
    }

    /**
     * @notice Get the fee schedule
     * @param _entityId ID of the entity
     * @param _feeScheduleType fee schedule type
     * @return receiver_ and basisPoints_ arrays
     */
    function getFeeSchedule(bytes32 _entityId, uint256 _feeScheduleType) external view returns (bytes32[] memory receiver_, uint16[] memory basisPoints_) {
        FeeSchedule memory feeSchedule = LibFeeRouter._getFeeSchedule(_entityId, _feeScheduleType);
        receiver_ = feeSchedule.receiver;
        basisPoints_ = feeSchedule.basisPoints;
    }

    /**
     * @notice Get the object's token symbol
     * @param _objectId ID of the object
     */
    function getObjectTokenSymbol(bytes32 _objectId) external view returns (string memory) {
        return LibObject._objectTokenSymbol(_objectId);
    }
}
