// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, Modifiers, LibHelpers, LibObject } from "../AppStorage.sol";

contract UserFacet is Modifiers {
    function getUserIdFromAddress(address addr) external pure returns (bytes32 userId) {
        return LibHelpers._getIdForAddress(addr);
    }

    function getAddressFromExternalTokenId(bytes32 _externalTokenId) external pure returns (address tokenAddress) {
        tokenAddress = LibHelpers._getAddressFromId(_externalTokenId);
    }

    function setEntity(bytes32 _userId, bytes32 _entityId) external assertSysAdmin {
        LibObject._setParent(_userId, _entityId);
    }

    function getEntity(bytes32 _userId) external view returns (bytes32 entityId) {
        entityId = LibObject._getParent(_userId);
    }

    function getBalanceOfTokensForSale(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 amount) {
        amount = s.marketLockedBalances[_entityId][_tokenId];
    }
}
