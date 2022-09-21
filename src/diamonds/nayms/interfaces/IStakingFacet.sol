// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LockedBalance } from "./FreeStructs.sol";

interface IStakingFacet {
    function checkpoint() external;

    function withdraw() external;

    function increaseAmount(uint256 _value) external;

    function increaseUnlockTime(uint256 _secondsIncrease) external;

    function createLock(
        address _for,
        uint256 _value,
        uint256 _lockDuration
    ) external;

    function depositFor(address _user, uint256 _value) external;

    function getLastUserSlope(address _user) external view returns (int128);

    function getUserPointHistoryTimestamp(address _user, uint256 _userEpoch) external view returns (uint256);

    function getUserLockedBalance(address _user) external view returns (LockedBalance memory);

    function getUserLockedBalanceEndTime(address _user) external view returns (uint256);

    function exchangeRate() external view returns (int128);

    function getVENAYMForNAYM(uint256 _value) external view returns (uint256);

    function getNAYMForVENAYM(uint256 _value) external view returns (uint256);

    // function balanceOf(address _user) external view returns (uint256);

    // function name() external view returns (string memory);

    // function symbol() external view returns (string memory);

    // function decimals() external view returns (uint8);
}
