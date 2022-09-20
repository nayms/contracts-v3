// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibStaking } from "../libs/LibStaking.sol";

contract StakingFacet {
    // PUBLIC FUNCTIONS
    function checkpoint() public {
        LibStaking.checkpoint();
    }

    function withdraw() public {
        LibStaking.withdraw();
    }

    function increaseAmount(uint256 _value) public {
        LibStaking.increaseAmount(_value);
    }

    function increaseUnlockTime(uint256 _secondsIncrease) public {
        LibStaking.increaseUnlockTime(_secondsIncrease);
    }

    function createLock(
        address _for,
        uint256 _value,
        uint256 _lockDuration
    ) public {
        LibStaking.createLock(_for, _value, _lockDuration);
    }

    function depositFor(address _user, uint256 _value) public {
        LibStaking.depositFor(_user, _value);
    }

    // VIEW FUNCTIONS

    function getLastUserSlope(address _user) public view returns (int128) {
        return LibStaking.getLastUserSlope(_user);
    }

    function getUserPointHistoryTimestamp(address _user, uint256 _userEpoch) public view returns (uint256) {
        return LibStaking.getUserPointHistoryTimestamp(_user, _userEpoch);
    }

    // function getUserLockedBalance(address _user) public view returns (LockedBalance memory) {
    //     bytes32 _userID = LibHelpers._getIdForAddress(_user);
    //     return s.userLockedBalances[_userID];
    // }

    function getUserLockedBalanceEndTime(address _user) public view returns (uint256) {
        return LibStaking.getUserLockedBalanceEndTime(_user);
    }

    function exchangeRate() public view returns (uint256) {
        return LibStaking.exchangeRate();
    }

    function getVENAYMForNAYM(uint256 _value) external view returns (uint256) {
        return LibStaking._getVENAYMForNAYM(_value);
    }

    function getNAYMForVENAYM(uint256 _value) external view returns (uint256) {
        return LibStaking._getNAYMForVENAYM(_value);
    }

    // standard ERC20 balanceOf function which reports a user's veNAYMS amount
    // function balanceOf(address _user) public view returns (uint256) {
    //     return LibStaking.balanceOf(_user);
    // }

    // function name() public pure returns (string memory) {
    //     return LibStaking.name();
    // }

    // function symbol() public pure returns (string memory) {
    //     return LibStaking.symbol();
    // }

    // function decimals() public pure returns (uint8) {
    //     return LibStaking.decimals();
    // }
}
