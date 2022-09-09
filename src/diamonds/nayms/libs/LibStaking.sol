// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, LibAdmin, LibConstants, LibHelpers, LockedBalance, StakingCheckpoint } from "../AppStorage.sol";
import { LibMeta } from "src/diamonds/shared/libs/LibMeta.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibTokenizedVaultIO } from "./LibTokenizedVaultIO.sol";

import { console2 } from "forge-std/console2.sol";

// Relies on this port of veCRV from Vyper to Solidity as reference:
// https://github.com/MochiFi/veCRV-vMOCHI/blob/main/contracts/vMochi.sol
// Original veCRV Vyper code:
// https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
library LibStaking {
    // NOTE: If rewards are withdrawable, staking cannot be compound, must be linear

    // EVENTS
    event Deposit(address indexed provider, uint256 value, uint256 indexed locktime, int128 depositType, uint256 ts);
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);

    // todo this does.. what? nothing it seems?
    function checkpoint() internal {
        _checkpoint(address(0), LockedBalance({ amount: 0, endTime: 0 }), LockedBalance({ amount: 0, endTime: 0 }));
    }

    function withdraw() internal {
        _withdraw(msg.sender);
    }

    function increaseAmount(uint256 _value) internal {
        depositFor(msg.sender, _value);
    }

    function increaseUnlockTime(uint256 _secondsIncrease) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(msg.sender);
        // kp TODO TODO - don't use s.userLockedBalances
        LockedBalance memory _lockedData = LockedBalance({
            amount: LibTokenizedVault._internalBalanceOf(_userID, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER)),
            endTime: s.userLockedEndTime[_userID]
        });
        uint256 unlockTime = ((_lockedData.endTime + _secondsIncrease) / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK;
        // uint256 unlockTime = (_unlockTime / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK; // old version
        require(_lockedData.amount > 0, "STAKING: NO EXISTING LOCK");
        require(_lockedData.endTime > block.timestamp, "STAKING: LOCK EXPIRED");
        require(unlockTime > _lockedData.endTime, "STAKING: ONLY INCREASE DURATION");
        require(unlockTime <= block.timestamp + LibConstants.STAKING_MAXTIME, "STAKING: OVER MAX LOCK TIME");
        _depositFor(msg.sender, 1, unlockTime, _lockedData, LibConstants.STAKING_INCREASE_UNLOCK_TIME);
    }

    function createLock(
        address _for,
        uint256 _value,
        uint256 _lockDuration
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // TODO enable rounding down to nearest week? messes with set lengths e.g. 60 days
        uint256 unlockTime = ((_lockDuration + block.timestamp) / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK;
        // uint256 unlockTime = (_unlockAt / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK; // old version
        bytes32 _userID = LibHelpers._getIdForAddress(msg.sender);

        require(_value > 0, "STAKING: ZERO VALUE");
        // TODO: Fix. 60 day min will cause issues with week rounding down
        // require(unlockTime >= block.timestamp + MINTIME, "STAKING: LESS THAN MIN TIME");
        require(unlockTime <= block.timestamp + LibConstants.STAKING_MAXTIME, "STAKING: MORE THAN MAX TIME");
        LockedBalance memory _lockedData = LockedBalance({
            amount: LibTokenizedVault._internalBalanceOf(_userID, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER)),
            endTime: s.userLockedEndTime[_userID]
        });
        require(_lockedData.amount == 0, "STAKING: WITHDRAW EXISTING FIRST");

        _depositFor(_for, _value, unlockTime, _lockedData, LibConstants.STAKING_CREATE_LOCK_TYPE);
    }

    // todo make sure we are getting correct user IDs here.
    function depositFor(address _user, uint256 _value) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        // LockedBalance memory _lockedData = s.userLockedBalances[_userID];
        LockedBalance memory _lockedData = LockedBalance({
            amount: LibTokenizedVault._internalBalanceOf(_userID, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER)),
            endTime: s.userLockedEndTime[_userID]
        });
        require(_value > 0, "STAKING: ZERO VALUE");
        require(_lockedData.amount > 0, "STAKING: LOCK DOES NOT EXIST");
        require(_lockedData.endTime > block.timestamp, "STAKING: LOCKED EXPIRED");
        _depositFor(_user, _value, 0, _lockedData, LibConstants.STAKING_DEPOSIT_FOR_TYPE);
    }

    // _user is recipient of veNAYMS position
    function _depositFor(
        address _user,
        uint256 _value,
        uint256 _unlockTime,
        LockedBalance memory _lockedData,
        int128 _type
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // save supply before increases
        // uint256 supplyBefore = s.stakedSupply;
        uint256 supplyBefore = LibTokenizedVault._internalTokenSupply(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER));
        bytes32 receiverId = LibHelpers._getIdForAddress(_user); // separate ID for recipient of veNAYMS
        bytes32 depositorId = LibHelpers._getIdForAddress(msg.sender); // separate ID for depositor, these might not be the same address

        console2.log("msg.sender in staking", msg.sender);
        // calculate amount to be minted PRIOR to updating staking supply (aka supply of veNAYM)
        uint256 mintAmount = ((_value * LibConstants.SCALE) / exchangeRate());
        // s.stakedSupply += ((_value * LibConstants.SCALE) / exchangeRate());

        if (_value != 0) {
            LibTokenizedVaultIO._externalDeposit(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), address(this), _value);

            // Internal transfer of NAYMS from depositor to staking contract for _value
            // TODO check STAKING_ID is in line with account transferred from in _withdraw
            // LibTokenizedVault._internalTransfer(
            //     depositorId,
            //     LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER),
            //     s.naymsTokenId,
            //     // LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER),
            //     _value
            // );
        }

        LibTokenizedVault._internalMint(receiverId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), mintAmount);

        // Load prev version of LockedBalance for checkpoint function
        // LockedBalance memory oldLocked = s.userLockedBalances[receiverId];
        LockedBalance memory oldLocked = LockedBalance({
            amount: LibTokenizedVault._internalBalanceOf(receiverId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER)),
            endTime: s.userLockedEndTime[receiverId]
        });

        // Increase amount locked by NAYMS value / veNAYMS exchange rate
        _lockedData.amount += ((_value * LibConstants.SCALE) / exchangeRate());

        if (_unlockTime != 0) {
            _lockedData.endTime = _unlockTime;
            s.userLockedEndTime[receiverId] = _unlockTime;
        }

        // Persist modified LockedBalance to storage
        // todo check if I modified this correctly
        // s.userLockedBalances[receiverId] = _lockedData;

        _checkpoint(_user, oldLocked, _lockedData);

        emit Deposit(_user, _value, _unlockTime, _type, block.timestamp);
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    function _withdraw(address _user) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        bytes32 _stmID = LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER);
        // todo double check if this update is good
        // LockedBalance memory _lockedData = s.userLockedBalances[_userID];
        LockedBalance memory oldLocked = LockedBalance({ amount: LibTokenizedVault._internalBalanceOf(_userID, _stmID), endTime: s.userLockedEndTime[_userID] });

        require(block.timestamp >= oldLocked.endTime, "STAKING: UNLOCK TIME NOT REACHED");
        // todo simplify types
        uint256 value = uint256(int256(oldLocked.amount));

        // Setting user's LockedBalance endTime and amount to 0
        // LockedBalance memory oldLocked = s.userLockedBalances[_userID];
        // _lockedData.endTime = 0;
        // _lockedData.amount = 0;
        // s.userLockedBalances[_userID] = _lockedData;

        // value in terms of veNAYMS, withdrawAmount in terms of NAYMS
        uint256 withdrawAmount = (value * exchangeRate()) / LibConstants.SCALE;

        uint256 supplyBefore = LibTokenizedVault._internalTokenSupply(_stmID);

        LibTokenizedVault._internalBurn(_userID, _stmID, withdrawAmount);

        // Internal transfer of NAYMS to _user for withdrawAmount
        // TODO check this account is in line with account transferred to (STAKING_ID) in _depositFor
        // TODO Ted added staking id - please double check
        // NOTE: everything regarding transfers is handled (or should be) in the internal burn method above
        // LibTokenizedVault._internalTransfer(
        //     _userID,
        //     LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER),
        //     s.naymsTokenId,
        //     // LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER),
        //     withdrawAmount
        // );

        // uint256 supplyBefore = s.stakedSupply;
        // s.stakedSupply -= value;

        // todo fetch actual values? or is this mock okay
        LockedBalance memory _lockedData = LockedBalance({ endTime: 0, amount: 0 });
        _checkpoint(_user, oldLocked, _lockedData);
        emit Withdraw(_user, withdrawAmount, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    function _checkpoint(
        address _user,
        LockedBalance memory _oldLocked,
        LockedBalance memory _newLocked
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        StakingCheckpoint memory uOldCheckpoint;
        StakingCheckpoint memory uNewCheckpoint;
        int128 oldSlope = 0;
        int128 newSlope = 0;
        uint256 epoch = s.stakingEpoch;
        bytes32 userID = LibHelpers._getIdForAddress(_user);

        if (_user != address(0)) {
            // Setting old checkpoint values
            if (_oldLocked.endTime > block.timestamp && _oldLocked.amount > 0) {
                uOldCheckpoint.slope = int128(int256(_oldLocked.amount)) / int128(int256(LibConstants.STAKING_MAXTIME));
                uOldCheckpoint.bias = uOldCheckpoint.slope * int128(int256(_oldLocked.endTime - block.timestamp));
            }
            // Setting new checkpoint values
            if (_newLocked.endTime > block.timestamp && _newLocked.amount > 0) {
                uNewCheckpoint.slope = int128(int256(_newLocked.amount)) / int128(int256(LibConstants.STAKING_MAXTIME));
                uNewCheckpoint.bias = uNewCheckpoint.slope * int128(int256(_newLocked.endTime - block.timestamp));
            }

            oldSlope = s.stakingSlopeChanges[_oldLocked.endTime];
            if (_newLocked.endTime != 0) {
                if (_newLocked.endTime == _oldLocked.endTime) {
                    newSlope = oldSlope;
                } else {
                    newSlope = s.stakingSlopeChanges[_newLocked.endTime];
                }
            }
        }

        // Fresh checkpoint object for global last checkpoint
        StakingCheckpoint memory lastCheckpoint = StakingCheckpoint({ bias: 0, slope: 0, ts: block.timestamp, blk: block.number });

        // save last global checkpoint if in a non-zero epoch
        if (epoch > 0) {
            lastCheckpoint = s.globalStakingCheckpointHistory[epoch];
        }

        uint256 lastCheckpointTimestamp = lastCheckpoint.ts;

        {
            // Storing another copy of lastCheckpoint in memory
            StakingCheckpoint memory initialLastCheckpoint = StakingCheckpoint({
                bias: lastCheckpoint.bias,
                slope: lastCheckpoint.slope,
                ts: lastCheckpoint.ts,
                blk: lastCheckpoint.blk
            });

            uint256 blockSlope = 0;

            // Calculating slope as change in block num over change in time
            // if epoch > 0, this will be true (see above in function)
            if (block.timestamp > lastCheckpoint.ts) {
                blockSlope = (LibConstants.SCALE * (block.number - lastCheckpoint.blk)) / (block.timestamp - lastCheckpoint.ts);
            }

            // Rounding last checkpoint timestamp down to nearest week
            uint256 t_i = (lastCheckpointTimestamp / LibConstants.STAKING_WEEK) * LibConstants.STAKING_WEEK;

            for (uint256 i = 0; i < 255; i++) {
                // increment by week in timestamp
                t_i += LibConstants.STAKING_WEEK;
                int128 dSlope = 0;

                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    dSlope = s.stakingSlopeChanges[t_i];
                }

                lastCheckpoint.bias -= lastCheckpoint.slope * int128(int256(t_i - lastCheckpointTimestamp));
                lastCheckpoint.slope += dSlope;

                if (lastCheckpoint.bias < 0) {
                    lastCheckpoint.bias = 0;
                }
                if (lastCheckpoint.slope < 0) {
                    lastCheckpoint.slope = 0;
                }

                lastCheckpointTimestamp = t_i;
                lastCheckpoint.ts = t_i;
                lastCheckpoint.blk == initialLastCheckpoint.blk + (blockSlope * (t_i - initialLastCheckpoint.ts)) / LibConstants.SCALE;
                epoch += 1;

                // if caught up to current time, save block num and break out loop
                if (t_i == block.timestamp) {
                    lastCheckpoint.blk = block.number;
                    break;
                } else {
                    // else store latest checkpoint in historic checkpoint mapping and loop again
                    s.globalStakingCheckpointHistory[epoch] = lastCheckpoint;
                }
            }

            // epoch up to date, persist to storage
            s.stakingEpoch = epoch;

            // update last checkpoint slope and bias,
            // calced from diff in user checkpoint slope and bias
            if (_user != address(0)) {
                lastCheckpoint.slope += uNewCheckpoint.slope - uOldCheckpoint.slope;
                lastCheckpoint.bias += uNewCheckpoint.bias - uOldCheckpoint.bias;
                if (lastCheckpoint.slope < 0) {
                    lastCheckpoint.slope = 0;
                }
                if (lastCheckpoint.bias < 0) {
                    lastCheckpoint.bias = 0;
                }
            }
        }

        // finally, store updated global checkpoint for latest epoch
        s.globalStakingCheckpointHistory[epoch] = lastCheckpoint;

        // Update old and new slopes, save in stakingSlopeChanges storage mapping
        if (_user != address(0)) {
            if (_oldLocked.endTime > block.timestamp) {
                oldSlope += uOldCheckpoint.slope;
                if (_newLocked.endTime == _oldLocked.endTime) {
                    oldSlope -= uNewCheckpoint.slope;
                }
                s.stakingSlopeChanges[_oldLocked.endTime] = oldSlope;
            }
            if (_newLocked.endTime > block.timestamp) {
                if (_newLocked.endTime > _oldLocked.endTime) {
                    newSlope -= uNewCheckpoint.slope;
                    s.stakingSlopeChanges[_newLocked.endTime] = newSlope;
                }
            }

            // Update user epoch checkpoint and save to storage
            uint256 userEpoch = ++s.userStakingCheckpointEpoch[userID];
            uNewCheckpoint.ts = block.timestamp;
            uNewCheckpoint.blk = block.number;
            s.userStakingCheckpointHistory[userID][userEpoch] = uNewCheckpoint;
        }
    }

    // VIEW FUNCTIONS

    function getLastUserSlope(address _user) internal view returns (int128) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        uint256 userEpoch = s.userStakingCheckpointEpoch[_userID];
        return s.userStakingCheckpointHistory[_userID][userEpoch].slope;
    }

    function getUserPointHistoryTimestamp(address _user, uint256 _userEpoch) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        return s.userStakingCheckpointHistory[_userID][_userEpoch].ts;
    }

    // function getUserLockedBalance(address _user) public view returns (LockedBalance memory) {
    //     bytes32 _userID = LibHelpers._getIdForAddress(_user);
    //     return s.userLockedBalances[_userID];
    // }

    function getUserLockedBalanceEndTime(address _user) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        // return s.userLockedBalances[_userID].endTime;
        return s.userLockedEndTime[_userID];
    }

    function exchangeRate() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 stakedSupply = LibTokenizedVault._internalTokenSupply(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER));
        // if (s.stakedSupply == 0) {
        if (stakedSupply == 0) {
            // if supply = 0, return 1 with 18 decimals
            return 1e18;
        }

        // TODO check this is pulling balance for correct account
        uint256 naymBalanceInStaking = LibTokenizedVault._internalBalanceOf(
            LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER),
            // LibHelpers._stringToBytes32(LibConstants.NAYM_TOKEN_IDENTIFIER)
            s.naymsTokenId
        );

        // return (LibConstants.SCALE * naymBalanceInStaking) / s.stakedSupply;
        return (LibConstants.SCALE * naymBalanceInStaking) / stakedSupply;
    }

    function _getVENAYMForNAYM(uint256 _value) internal view returns (uint256) {
        return ((_value * LibConstants.SCALE) / exchangeRate());
    }

    function _getNAYMForVENAYM(uint256 _value) internal view returns (uint256) {
        return (_value * exchangeRate()) / LibConstants.SCALE;
    }

    // standard ERC20 balanceOf function which reports a user's veNAYMS amount
    function balanceOf(address _user) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _userID = LibHelpers._getIdForAddress(_user);
        return s.userLockedBalances[_userID].amount;
    }

    function name() internal pure returns (string memory) {
        return LibConstants.VE_NAYM_NAME;
    }

    function symbol() internal pure returns (string memory) {
        return LibConstants.VE_NAYM_SYMBOL;
    }

    function decimals() internal pure returns (uint8) {
        return LibConstants.VE_NAYM_DECIMALS;
    }
}
