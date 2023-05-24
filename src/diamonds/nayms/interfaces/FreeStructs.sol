// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct MarketInfo {
    bytes32 creator; // entity ID
    bytes32 sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    bytes32 buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    uint256 feeSchedule;
    uint256 state;
    uint256 rankNext;
    uint256 rankPrev;
}

struct TokenAmount {
    bytes32 token;
    uint256 amount;
}

/**
 * @param maxCapacity Maxmimum allowable amount of capacity that an entity is given. Denominated by assetId.
 * @param utilizedCapacity The utilized capacity of the entity. Denominated by assetId.
 */
struct Entity {
    bytes32 assetId;
    uint256 collateralRatio;
    uint256 maxCapacity;
    uint256 utilizedCapacity;
    bool simplePolicyEnabled;
}

/// @dev Only pass in the fields that are allowed to be updated.
/// @dev These are the variables of an entity that are allowed to be updated by the method updateEntity()
struct UpdateEntityTypeCell {
    uint256 collateralRatio;
    uint256 maxCapacity;
    bool simplePolicyEnabled;
}

struct CommissionReceiverInfo {
    bytes32 receiver;
    uint256 basisPoints;
}

struct SimplePolicy {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    bool fundsLocked;
    bool cancelled;
    uint256 claimsPaid;
    uint256 premiumsPaid;
    bytes32[] commissionReceivers;
    uint256[] commissionBasisPoints;
    uint256 feeStrategy; // The policy fee strategy for this policy
}

struct SimplePolicyInfo {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    bool fundsLocked;
    bool cancelled;
    uint256 claimsPaid;
    uint256 premiumsPaid;
}

struct PolicyCommissionsBasisPoints {
    uint16 premiumCommissionNaymsLtdBP;
    uint16 premiumCommissionNDFBP;
    uint16 premiumCommissionSTMBP;
}

struct Stakeholders {
    bytes32[] roles;
    bytes32[] entityIds;
    bytes[] signatures;
}

// Used in StakingFacet
struct LockedBalance {
    uint256 amount;
    uint256 endTime;
}

struct StakingCheckpoint {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts; // timestamp
    uint256 blk; // block number
}

struct FeeRatio {
    uint256 brokerShareRatio;
    uint256 naymsLtdShareRatio;
    uint256 ndfShareRatio;
}

struct TradingCommissions {
    uint256 roughCommissionPaid;
    uint256 commissionNaymsLtd;
    uint256 commissionNDF;
    uint256 commissionSTM;
    uint256 commissionMaker;
    uint256 totalCommissions;
}

struct TradingCommissionsBasisPoints {
    uint16 tradingCommissionTotalBP;
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
}

struct MarketplaceFeeStrategy {
    uint256 tradingCommissionTotalBP; // The total % of fees taken
    uint256 tradingCommissionMakerBP; // Of the total % of fees taken, the % that goes to the maker
    CommissionReceiverInfo[] commissionReceiversInfo; // The list of additional receivers of the fees
}
