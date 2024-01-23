// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibConstants as LC } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "../libs/LibTokenizedVault.sol";
import { StakeConfig } from "../shared/FreeStructs.sol";

library LibTokenizedVaultStaking {
    // When staking, the stake always gets set on the next interval.
    // When paying out distributions, they are always paid on the previous interval.
    //   This way, if distributions are paid and collected as dividends, there is never a conflict. When the distribution is paid on the
    //   previous interval, everyone has already owned the interval vTokens
    // Only one distribution is allowed per interval

    /// Staking Data
    // mapping(bytes32 => mapping(bytes32 => mapping (uint128 => uint256))) stakeBoost; // [tokenId][ownerId][interval] Boost per interval
    // mapping(bytes32 => mapping (bytes32 => uint128)) stakePaid // [tokenid][ownerId] Index of the last paid interval for each staker
    // mapping(bytes32 => StakeConfig) stakeConfigs // [tokenid] StakeConfig for staking of a token token
    //
    // struct StakeConfig {
    //     uint256 initDate;
    //     uint64 a;
    //     uint64  r;
    //     uint64  divider;
    //     uint64  interval;
    // }

    event StakingParamsUpdated(bytes32 indexed tokenId, uint64 a, uint64 r, uint64 divider, uint64 interval);

    event StakingStarted(bytes32 indexed tokenId, uint256 initDate);
    /**
     * @dev Emitted when a user stakes tokens.
     * @param ownerId Id of owner
     * @param tokenId ID of token
     * @param amountStaked amount staked
     * @param totalAmountStaked total amount staked
     */
    event InternalTokensStaked(bytes32 indexed ownerId, bytes32 tokenId, uint256 amountStaked, uint256 totalAmountStaked);

    /**
     * @dev Emitted when a user unstakes tokens.
     * @param ownerId Id of owner
     * @param tokenId ID of token
     * @param totalAmountUnstaked total amount staked
     */
    event InternalTokensUnstaked(bytes32 indexed ownerId, bytes32 tokenId, uint256 totalAmountUnstaked);

    /**
     * @dev First 4 bytes: "VTOK", next 8 bytes: interval, next 20 bytes: right 20 bytes of tokenId
     * @param _tokenId The internal ID of the token.
     * @param _interval The interval of staking.
     */
    function _vTokenId(bytes32 _tokenId, uint64 _interval) internal pure returns (bytes32 vTokenId_) {
        vTokenId_ = bytes32(abi.encodePacked(bytes4(LC.OBJECT_TYPE_STAKED), _interval, _tokenId << 96));
    }

    /**
     * @dev Initialize AppStorage.stakeConfigs for a token. These are the staking configurations for a token.
     * @param _tokenId The internal ID of the token
     */
    function _updateStakingParams(bytes32 _tokenId) internal {
        _updateStakingParams(_tokenId, 150000000, 850000000, 1000000000, 30 days);
    }

    /// @notice The staking configuration for a token is already initialized.
    error StakingAlreadyInitialized(bytes32 tokenId);

    error StakingAlreadyStarted(bytes32 tokenId);
    /**
     * @dev Initialize AppStorage.stakeConfigs for a token. These are the staking configurations for a token.
     * @param _tokenId The internal ID of the token
     * @param a The initial boost factor
     * @param r The boost reduction per interval
     * @param divider The divider for the boost
     * @param intervalSeconds The interval in seconds
     */
    function _updateStakingParams(bytes32 _tokenId, uint64 a, uint64 r, uint64 divider, uint64 intervalSeconds) internal {
        // Staking for an ID can only be initialized once
        // Stake.lastStakePaid on bucket 0, for the tokenid, is set to the init timestamp.
        // It is possible for stakers to exist before staking is initialized, but they will only start earming rewards after initialization
        AppStorage storage s = LibAppStorage.diamondStorage();

        _validateStakingParams(a, r, divider, intervalSeconds);
        s.stakeConfigs[_tokenId] = StakeConfig({ initDate: 0, a: a, r: r, divider: divider, interval: intervalSeconds });

        emit StakingParamsUpdated(_tokenId, a, r, divider, intervalSeconds);
    }

    function _startStaking(bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // todo validate args

        if (s.stakeConfigs[_tokenId].initDate == 0) {
            s.stakeConfigs[_tokenId].initDate = block.timestamp;
        } else {
            revert StakingAlreadyStarted(_tokenId);
        }

        emit StakingStarted(_tokenId, block.timestamp);
    }
    function _stakeConfigs(bytes32 _tokenId) internal view returns (StakeConfig memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeConfigs[_tokenId];
    }

    function _currentInterval(bytes32 _tokenId) internal view returns (uint64 currentInterval_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.stakeConfigs[_tokenId].initDate == 0) {
            currentInterval_ = 0;
        } else {
            currentInterval_ = uint64((block.timestamp - s.stakeConfigs[_tokenId].initDate) / s.stakeConfigs[_tokenId].interval);
        }
    }

    /**
     * @dev Get the starting time of a given interval
     * @param _tokenId The internal ID of the token
     * @param _interval The interval to get the time for
     */
    function _calculateStartTimeOfInterval(bytes32 _tokenId, uint64 _interval) internal view returns (uint64 intervalTime_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        intervalTime_ = uint64(s.stakeConfigs[_tokenId].initDate + (_interval * s.stakeConfigs[_tokenId].interval));
    }

    function _calculateStartTimeOfCurrentInterval(bytes32 _tokenId) internal view returns (uint64 intervalTime_) {
        intervalTime_ = _calculateStartTimeOfInterval(_tokenId, _currentInterval(_tokenId));
    }

    event DebugBoost2(uint256 boostTotal, uint256 blockTimestamp, uint64 startTimeOfCurrentInterval, uint64 interval);

    /// @dev Users should be able to stake prior to the stake/boost starting.
    function _stake(bytes32 _ownerId, bytes32 _tokenId, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // uint256 boost1;
        // uint256 boost2;
        uint256 boostTotal;

        uint64 interval1;
        uint64 interval2;
        // The balance at bucket 0 is used to store the original balance that was staked.  If this is zero, the user has never staked.
        // vtokenId00 also owns the original capital of the staker
        bytes32 vTokenId0 = _vTokenId(_tokenId, 0); // Staking bank ID

        uint64 currentInterval = _currentInterval(_tokenId);
        bytes32 vTokenId = _vTokenId(_tokenId, currentInterval);

        interval1 = currentInterval + 1;
        interval2 = interval1 + 1;

        bytes32 parentId = LibObject._getParent(_ownerId);
        // 0. Withdraw all current distributions first
        // _withdrawDistributions(_ownerId, _tokenId, _dividendTokenId);
        LibTokenizedVault._withdrawAllDividends(parentId, _tokenId);

        // 1. Transfer tokens to vTokenId and mint new vTokens for the staker
        LibTokenizedVault._internalTransfer(parentId, vTokenId0, _tokenId, _amount);
        // Mint tokens at the current interval to the staker
        LibTokenizedVault._internalMint(parentId, vTokenId, _amount);

        // 2. Set next two boosts
        // Get the portion that corresponds to the next two intervals and add the boost to each
        // Also bump up the boost for the tokenId which tracks the total
        boostTotal = _amount * s.stakeConfigs[_tokenId].a;

        {
            emit DebugBoost2(boostTotal, block.timestamp, _calculateStartTimeOfCurrentInterval(_tokenId), s.stakeConfigs[_tokenId].interval);
        }
        uint256 boost2 = (boostTotal * (block.timestamp - _calculateStartTimeOfCurrentInterval(_tokenId))) / s.stakeConfigs[_tokenId].interval;
        uint256 boost1 = boostTotal - boost2;

        s.stakeBoost[_tokenId][_ownerId][interval1] += boost1;
        s.stakeBoost[_tokenId][_ownerId][interval2] += boost2;

        // Keep track of the totals! These will be used to calculate the boost for the next pool!
        s.stakeBoost[_tokenId][_tokenId][interval1] += boost1;
        s.stakeBoost[_tokenId][_tokenId][interval2] += boost2;

        // todo total amount staked needs revision
        // emit InternalTokensStaked(_ownerId, _tokenId, _amount, LibTokenizedVault._internalBalanceOf(_ownerId, vTokenId));
    }

    // Unstakes the full amount for a staker
    function _unstakeAll(bytes32 _ownerId, bytes32 _tokenId) internal {
        bytes32 vTokenId0 = _vTokenId(_tokenId, 0); // Staking bank ID

        // withdraw all dividends
        _withdrawAllDistributions(_ownerId, _tokenId);

        // Burn the users tokens
        uint256 vTokenBalance = LibTokenizedVault._internalBalanceOf(_ownerId, _vTokenId(_tokenId, 0));
        LibTokenizedVault._internalBurn(_ownerId, vTokenId0, vTokenBalance);
        // No need to clean up the rest, as the dividend mechanism takes care of all that
    }

    function _rewardsBalance(bytes32 _ownerId, bytes32 _tokenId, bytes32 _dividendTokenId) internal view returns (uint256 owedRewards_) {
        // Todo: not yet implemented
    }

    function _payDistribution(bytes32 _guid, bytes32 _from, bytes32 _ownerId, bytes32 _tokenId, bytes32 _rewardTokenId, uint256 _amount) internal {
        // function payDistribution(bytes32 _guid, bytes32 _from, bytes32 _tokenId, bytes32 _rewardTokenId, uint256 _amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Todo: vTokens should NOT be able to collect their own dividends.
        // We should add a method to transfer tokens WITH their dividend

        // At least one interval must be paid before distribution is paid
        require(_currentInterval(_tokenId) > 0, "cannot pay before first interval");
        require(s.stakePaid[_tokenId][_tokenId] == 0, "cannot pay two distributions per interval");

        // s.stakePaid[_tokenId][_tokenId] = _amount;
        bytes32 vTokenId0 = _vTokenId(_tokenId, 0);

        uint64 currentInterval = _currentInterval(_tokenId);
        bytes32 vTokenId = _vTokenId(_tokenId, currentInterval);

        (uint256 owedBoost, uint256 currentBoost) = _currentOwedBoost(_ownerId, _tokenId);

        // Mint the owedBost to the vTokenId before distributing
        LibTokenizedVault._internalMint(vTokenId0, vTokenId, owedBoost);

        // Add the current boost to the current interval
        s.stakeBoost[_tokenId][_tokenId][currentInterval] += currentBoost;

        // Then pay dividend normally and let the dividend mechanism handle the rest
        LibTokenizedVault._payDividend(_guid, _from, vTokenId, _rewardTokenId, _amount);
    }

    /**
     *
     * @param _ownerId Owner of the tokens
     * @param _tokenId ID of the token
     * @return owedBoost_ Amount of boost owed since the last collected interval
     * @return currentBoost_
     */
    function _currentOwedBoost(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256 owedBoost_, uint256 currentBoost_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 nextBoostIncrement;

        // 1. Get the last interval where distribution was collected by the user.
        uint64 lastCollectedInterval = s.lastCollectedInterval[_tokenId][_ownerId];

        // 2. Get the last interval where a distribution was paid
        uint64 lastIntervalPaid = s.lastIntervalPaid[_tokenId];

        // 3. Iterate through and add the boosts that the user should have until here
        // Todo: double check this loop
        for (uint64 i = lastCollectedInterval; i < lastIntervalPaid; ++i) {
            nextBoostIncrement = s.stakeBoost[_tokenId][_ownerId][i];
            currentBoost_ = s.stakeBoost[_tokenId][_ownerId][i + 1] + ((nextBoostIncrement * s.stakeConfigs[_tokenId].r) / s.stakeConfigs[_tokenId].divider);
            owedBoost_ += currentBoost_;
        }
    }

    function _owedBoostAtInterval(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256 owedBoost_, uint256 currentBoost_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 nextBoostIncrement;

        // 1. Get the last interval where distribution was collected by the user.
        uint64 lastCollectedInterval = s.stakePaid[_tokenId][_ownerId];

        // 2. Get the last interval where a distribution was paid
        uint64 lastIntervalPaid = s.stakePaid[_tokenId][_tokenId];

        // 3. Iterate through and add the boosts that the user should have until here
        // Todo: double check this loop
        for (uint64 i = lastCollectedInterval; i < lastIntervalPaid; ++i) {
            nextBoostIncrement = s.stakeBoost[_tokenId][_ownerId][i];
            currentBoost_ = s.stakeBoost[_tokenId][_ownerId][i + 1] + ((nextBoostIncrement * s.stakeConfigs[_tokenId].r) / s.stakeConfigs[_tokenId].divider);
            owedBoost_ += currentBoost_;
        }
    }

    function _currentVtokenBalance(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256 vTokenBalance_) {
        vTokenBalance_ = LibTokenizedVault._internalBalanceOf(_ownerId, _vTokenId(_tokenId, _currentInterval(_tokenId)));
    }

    // function _getTotalVtokenBalance(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256 _vTokenBalance) {
    //     _vTokenBalance = LibTokenizedVault._internalBalanceOf(_ownerId, _vTokenId(_tokenId, _currentInterval(_tokenId))) + _currentOwedBoost(_ownerId, _tokenId);
    // }

    function _withdrawAllDistributions(bytes32 _ownerId, bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // The boost has already been minted to the vTokenId when the last dividend was paid, so the tokens exist, and dividend is calculated properly.
        // We just need to transfer this to the owner without triggering a dividend payment to the vTokenId
        uint64 lastStakePaid = s.stakePaid[_tokenId][_tokenId];

        (uint256 owedBoost, uint256 currentBoost) = _currentOwedBoost(_ownerId, _tokenId);
        bytes32 vTokenId = _vTokenId(_tokenId, _currentInterval(_tokenId));

        // Transfer the tokens from the vTokenId to the ownerId WITHOUT giving the dividend to the token.
        // Todo: make a method that transfers tokens WITH their dividend in the tokenized vault facet, and use that!
        s.tokenBalances[vTokenId][vTokenId] -= owedBoost;
        s.tokenBalances[vTokenId][_ownerId] += owedBoost;
        LibTokenizedVault._withdrawAllDividends(_ownerId, vTokenId);

        // Add the stake boost on the last paid interval for the user
        s.stakeBoost[_tokenId][_ownerId][lastStakePaid] += currentBoost;

        // Set the current stake paid for the staker
        s.stakePaid[_tokenId][_ownerId] = lastStakePaid;
    }

    // This is an update to the tokenized vault facet
    function _patialWithdrawDividend(bytes32 _ownerId, bytes32 _tokenId, bytes32 _dividendTokenId, uint256 amountOwned) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.tokenBalances[_tokenId][_ownerId] >= amountOwned, "insufficient balance");

        bytes32 dividendBankId = LibHelpers._stringToBytes32(LC.DIVIDEND_BANK_IDENTIFIER);

        // uint256 amountOwned = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = LibTokenizedVault._internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        uint256 withdrawableDividend = LibTokenizedVault._getWithdrawableDividendAndDeductionMath(amountOwned, supply, totalDividend, withdrawnSoFar);
        if (withdrawableDividend > 0) {
            // Bump the withdrawn dividends for the owner
            s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId] += withdrawableDividend;

            // Move the dividend
            s.tokenBalances[_dividendTokenId][dividendBankId] -= withdrawableDividend;
            s.tokenBalances[_dividendTokenId][_ownerId] += withdrawableDividend;

            // emit InternalTokenBalanceUpdate(dividendBankId, _dividendTokenId, s.tokenBalances[_dividendTokenId][dividendBankId], "_withdrawDividend", msg.sender);
            // emit InternalTokenBalanceUpdate(_ownerId, _dividendTokenId, s.tokenBalances[_dividendTokenId][_ownerId], "_withdrawDividend", msg.sender);
            // emit DividendWithdrawn(_ownerId, _tokenId, amountOwned, _dividendTokenId, withdrawableDividend);
        }
    }

    error InvalidAValue();
    error InvalidRValue();
    error InvalidDividerValue();
    error APlusRCannotBeGreaterThanDivider();
    error InvalidIntervalSecondsValue();

    function _validateStakingParams(uint64 a, uint64 r, uint64 divider, uint64 intervalSeconds) internal pure {
        if (a == 0) revert InvalidAValue();

        if (r == 0) revert InvalidRValue();

        if (divider == 0) revert InvalidDividerValue();

        if (a + r > divider) revert APlusRCannotBeGreaterThanDivider();

        if (intervalSeconds == 0) revert InvalidIntervalSecondsValue();
    }
}
