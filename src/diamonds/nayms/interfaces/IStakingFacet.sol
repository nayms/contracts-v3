// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LockedBalance } from "./FreeStructs.sol";

/**
 * @title Staking Mechanism
 * @notice Stake NAYM tokens
 * @dev Use this fcet to intreract with the Nayms' staking mechanism
 */
interface IStakingFacet {
    /**
     * @notice Checkpoint trigger
     * @dev trigger checkpoint init
     */
    function checkpoint() external;

    /**
     * @notice Withdraw staked funds
     * @dev Withdraw staked funds to the sender address
     */
    function withdraw() external;

    /**
     * @notice Increase staked amount by `_value`
     * @dev Increase staked funds for a given amount
     * @param _value amount to add to the staking pool
     */
    function increaseAmount(uint256 _value) external;

    /**
     * @notice Extend staking period for `_value` seconds
     * @dev Extend staking period for given number of seconds
     * @param _secondsIncrease seconds to increase staking period for
     */
    function increaseUnlockTime(uint256 _secondsIncrease) external;

    /**
     * @notice Lock `_value` on behalf of `_for` for `_lockDuration`
     * @dev Lock funds belonging to an account for specific amount of time
     * @param _for account that is locking the funds
     * @param _value amount being locked
     * @param _lockDuration period for which to lock funds
     */
    function createLock(
        address _for,
        uint256 _value,
        uint256 _lockDuration
    ) external;

    /**
     * @notice Deposit `_value` into staking pool for `_user`
     * @dev Deposit funds into the staking pool
     * @param _user account that is depositing the funds
     * @param _value amount being locked
     */
    function depositFor(address _user, uint256 _value) external;

    /**
     * @notice Get last slope for `_user`
     * @dev Gets the last used slope for an account
     * @param _user account that has staked funds
     * @return slope last used
     */
    function getLastUserSlope(address _user) external view returns (int128);

    /**
     * @notice Get timestamp for checkpoint
     * @dev Gets timestamp for a checkpoint corresponding to given epoch
     * @param _user account address
     * @param _userEpoch epoch of the checkopint
     * @return checkpoint timestamp
     */
    function getUserPointHistoryTimestamp(address _user, uint256 _userEpoch) external view returns (uint256);

    /**
     * @notice Get staked balance for account `_user`
     * @dev Gets the balance of staked funds
     * @param _user account that has staked funds
     * @return amount of staked funds
     */
    function getUserLockedBalance(address _user) external view returns (LockedBalance memory);

    /**
     * @notice Get the stake expiration period
     * @dev Gets time when the staking lock expires
     * @param _user account that has staked funds
     * @return lock expiration time
     */
    function getUserLockedBalanceEndTime(address _user) external view returns (uint256);

    /**
     * @notice Get the exchange rate for staking
     * @dev Gets the exchange rate used for staking tokens
     * @return exchange rate
     */
    function exchangeRate() external view returns (int128);

    /**
     * @notice Get the amount of veNAYM received for `_value` NAYM tokens
     * @dev Converts the amount to staked amount
     * @param _value amount of NAYM given
     * @return amount of veNAYM received
     */
    function getVENAYMForNAYM(uint256 _value) external view returns (uint256);

    /**
     * @notice Get the amount of NAYM received for `_value` veNAYM tokens
     * @dev Converts the staked amount to amount
     * @param _value amount of veNAYM given
     * @return amount of NAYM received
     */
    function getNAYMForVENAYM(uint256 _value) external view returns (uint256);

    // function balanceOf(address _user) external view returns (uint256);

    // function name() external view returns (string memory);

    // function symbol() external view returns (string memory);

    // function decimals() external view returns (uint8);
}
