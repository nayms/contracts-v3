// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IUserFacet {
    function getUserIdFromAddress(address addr) external pure returns (bytes32 userId);

    function getAddressFromExternalTokenId(bytes32 _externalTokenId) external pure returns (address tokenAddress);

    function setEntity(bytes32 _userId, bytes32 _entityId) external;

    function getEntity(bytes32 _userId) external view returns (bytes32 entityId);

    function getBalanceOfTokensForSale(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 amount);
}
