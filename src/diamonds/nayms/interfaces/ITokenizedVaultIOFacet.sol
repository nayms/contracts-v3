// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface ITokenizedVaultIOFacet {
    function externalDepositToEntity(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;

    function externalDeposit(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;

    function externalWithdrawFromEntity(
        bytes32 _entityId,
        address _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;
}
