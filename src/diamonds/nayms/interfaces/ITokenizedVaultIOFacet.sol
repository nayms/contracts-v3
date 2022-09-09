// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/**
 * @title Token Vault IO
 * @notice External interface to the Token Vault
 * @dev Used for external transfers
 */
interface ITokenizedVaultIOFacet {
    /**
     * @notice Deposit funds into Nayms platform entity
     * @dev Deposit from an external account
     * @param _receiverId Internal ID of the account receiving the deposited funds
     * @param _externalTokenAddress Token address
     * @param _amount deposit amount
     */
    function externalDepositToEntity(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;

    /**
     * @notice Deposit funds into Nayms platform
     * @dev Deposit from an external account
     * @param _receiverId Internal ID of the account receiving the deposited funds
     * @param _externalTokenAddress Token address
     * @param _amount deposit amount
     */
    function externalDeposit(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;

    /**
     * @notice Withdraw funds out of Nayms platform
     * @dev Withdraw from entity to an external account
     * @param _entityId Internal ID of the entity the user is withdrawing from
     * @param _receiverId Internal ID of the account receiving the funds
     * @param _externalTokenAddress Token address
     * @param _amount amount to withdraw
     */
    function externalWithdrawFromEntity(
        bytes32 _entityId,
        address _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;
}
