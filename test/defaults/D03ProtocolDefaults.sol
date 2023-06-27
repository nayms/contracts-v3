// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D02TestSetup, LibHelpers, console2 } from "./D02TestSetup.sol";
import { Entity, SimplePolicy, Stakeholders, FeeSchedule } from "src/diamonds/nayms/interfaces/FreeStructs.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { LibAdmin } from "src/diamonds/nayms/libs/LibAdmin.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";

// solhint-disable no-console
// solhint-disable state-visibility

/// @notice Default test setup part 03
///         Protocol / project level defaults
///         Setup internal token IDs, entities,
contract D03ProtocolDefaults is D02TestSetup {
    bytes32 public immutable account0Id = LibHelpers._getIdForAddress(account0);
    bytes32 public naymsTokenId;

    bytes32 public immutable systemContext = LibAdmin._getSystemId();

    bytes32 public constant DEFAULT_ACCOUNT0_ENTITY_ID = bytes32("e0");
    bytes32 public constant DEFAULT_UNDERWRITER_ENTITY_ID = bytes32("e1");
    bytes32 public constant DEFAULT_BROKER_ENTITY_ID = bytes32("e2");
    bytes32 public constant DEFAULT_CAPITAL_PROVIDER_ENTITY_ID = bytes32("e3");
    bytes32 public constant DEFAULT_INSURED_PARTY_ENTITY_ID = bytes32("e4");

    // deriving public keys from private keys
    address public immutable signer1 = vm.addr(0xACC2);
    address public immutable signer2 = vm.addr(0xACC1);
    address public immutable signer3 = vm.addr(0xACC3);
    address public immutable signer4 = vm.addr(0xACC4);

    bytes32 public immutable signer1Id = LibHelpers._getIdForAddress(vm.addr(0xACC2));
    bytes32 public immutable signer2Id = LibHelpers._getIdForAddress(vm.addr(0xACC1));
    bytes32 public immutable signer3Id = LibHelpers._getIdForAddress(vm.addr(0xACC3));
    bytes32 public immutable signer4Id = LibHelpers._getIdForAddress(vm.addr(0xACC4));

    // 0x4e61796d73204c74640000000000000000000000000000000000000000000000
    bytes32 public immutable NAYMS_LTD_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER);
    bytes32 public immutable NDF_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER);
    bytes32 public immutable STM_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER);
    bytes32 public immutable SSF_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.SSF_IDENTIFIER);

    bytes32 public immutable DIVIDEND_BANK_IDENTIFIER = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 public immutable USDC_IDENTIFIER = LibHelpers._getIdForAddress(USDC_ADDRESS);

    FeeSchedule premiumFeeScheduleDefault;
    FeeSchedule tradingFeeScheduleDefault;

    function setUp() public virtual override {
        console2.log("\n Test SETUP:");
        super.setUp();
        console2.log("\n -- D03 Protocol Defaults\n");
        console2.log("Test contract address ID, aka account0Id:");
        console2.logBytes32(account0Id);

        naymsTokenId = LibHelpers._getIdForAddress(naymsAddress);
        console2.log("Nayms Token ID:");
        console2.logBytes32(naymsTokenId);

        vm.label(signer1, "Account 1 (Underwriter Rep)");
        vm.label(signer2, "Account 2 (Broker Rep)");
        vm.label(signer3, "Account 3 (Capital Provider Rep)");
        vm.label(signer4, "Account 4 (Insured Party Rep)");

        vm.startPrank(systemAdmin);
        nayms.addSupportedExternalToken(wethAddress);

        Entity memory entity = Entity({
            assetId: LibHelpers._getIdForAddress(wethAddress),
            collateralRatio: LibConstants.BP_FACTOR,
            maxCapacity: 100 ether,
            utilizedCapacity: 0,
            simplePolicyEnabled: true
        });

        nayms.createEntity(DEFAULT_ACCOUNT0_ENTITY_ID, account0Id, entity, "entity test hash");
        nayms.createEntity(DEFAULT_UNDERWRITER_ENTITY_ID, signer1Id, entity, "entity test hash");
        nayms.createEntity(DEFAULT_BROKER_ENTITY_ID, signer2Id, entity, "entity test hash");
        nayms.createEntity(DEFAULT_CAPITAL_PROVIDER_ENTITY_ID, signer3Id, entity, "entity test hash");
        nayms.createEntity(DEFAULT_INSURED_PARTY_ENTITY_ID, signer4Id, entity, "entity test hash");

        // Setup fee schedules
        premiumFeeScheduleDefault = feeSched1(NAYMS_LTD_IDENTIFIER, 300);
        tradingFeeScheduleDefault = feeSched1(NAYMS_LTD_IDENTIFIER, 30);

        // For Premiums
        nayms.addFeeSchedule(LibConstants.DEFAULT_PREMIUM_FEE_SCHEDULE, LibConstants.FEE_TYPE_PREMIUM, premiumFeeScheduleDefault);

        // For Marketplace
        nayms.addFeeSchedule(LibConstants.DEFAULT_TRADING_FEE_SCHEDULE, LibConstants.FEE_TYPE_TRADING, tradingFeeScheduleDefault);
        nayms.addFeeSchedule(LibConstants.DEFAULT_INITIAL_SALE_FEE_SCHEDULE, LibConstants.FEE_TYPE_INITIAL_SALE, tradingFeeScheduleDefault);

        console2.log("\n -- END TEST SETUP D03 Protocol Defaults --\n");
    }

    function feeSched1(bytes32 _receiver, uint256 _basisPoints) public pure returns (FeeSchedule memory) {
        bytes32[] memory receiver_ = new bytes32[](1);
        receiver_[0] = _receiver;

        uint256[] memory basisPoints_ = new uint256[](1);
        basisPoints_[0] = _basisPoints;

        return FeeSchedule({ receiver: receiver_, basisPoints: basisPoints_ });
    }

    function feeSched3(
        bytes32 _receiver1,
        bytes32 _receiver2,
        bytes32 _receiver3,
        uint256 _basisPoints1,
        uint256 _basisPoints2,
        uint256 _basisPoints3
    ) public pure returns (FeeSchedule memory) {
        bytes32[] memory receiver_ = new bytes32[](3);
        receiver_[0] = _receiver1;
        receiver_[1] = _receiver2;
        receiver_[2] = _receiver3;

        uint256[] memory basisPoints_ = new uint256[](3);
        basisPoints_[0] = _basisPoints1;
        basisPoints_[1] = _basisPoints2;
        basisPoints_[2] = _basisPoints3;

        return FeeSchedule({ receiver: receiver_, basisPoints: basisPoints_ });
    }

    function createTestEntity(bytes32 adminId) internal returns (bytes32) {
        return createTestEntityWithId(adminId, "0xe1");
    }

    function createTestEntityWithId(bytes32 adminId, bytes32 entityId) internal returns (bytes32) {
        Entity memory entity1 = initEntity(wethId, LibConstants.BP_FACTOR / 2, LibConstants.BP_FACTOR, false);
        nayms.createEntity(entityId, adminId, entity1, bytes32(0));
        return entityId;
    }

    function initEntity(
        bytes32 _assetId,
        uint256 _collateralRatio,
        uint256 _maxCapacity,
        bool _simplePolicyEnabled
    ) public pure returns (Entity memory e) {
        e.assetId = _assetId;
        e.collateralRatio = _collateralRatio;
        e.maxCapacity = _maxCapacity;
        e.utilizedCapacity = 0;
        e.simplePolicyEnabled = _simplePolicyEnabled;
    }

    function initPolicy(bytes32 offchainDataHash) internal returns (Stakeholders memory policyStakeholders, SimplePolicy memory policy) {
        return initPolicyWithLimit(offchainDataHash, LibConstants.BP_FACTOR);
    }

    function initPolicyWithLimit(bytes32 offchainDataHash, uint256 limitAmount) internal returns (Stakeholders memory policyStakeholders, SimplePolicy memory policy) {
        bytes32[] memory roles = new bytes32[](4);
        roles[0] = LibHelpers._stringToBytes32(LibConstants.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LibConstants.ROLE_BROKER);
        roles[2] = LibHelpers._stringToBytes32(LibConstants.ROLE_CAPITAL_PROVIDER);
        roles[3] = LibHelpers._stringToBytes32(LibConstants.ROLE_INSURED_PARTY);

        bytes32[] memory entityIds = new bytes32[](4);
        entityIds[0] = DEFAULT_UNDERWRITER_ENTITY_ID;
        entityIds[1] = DEFAULT_BROKER_ENTITY_ID;
        entityIds[2] = DEFAULT_CAPITAL_PROVIDER_ENTITY_ID;
        entityIds[3] = DEFAULT_INSURED_PARTY_ENTITY_ID;

        bytes32[] memory commissionReceivers = new bytes32[](3);
        commissionReceivers[0] = DEFAULT_UNDERWRITER_ENTITY_ID;
        commissionReceivers[1] = DEFAULT_BROKER_ENTITY_ID;
        commissionReceivers[2] = DEFAULT_CAPITAL_PROVIDER_ENTITY_ID;

        uint256[] memory commissions = new uint256[](3);
        commissions[0] = 10;
        commissions[1] = 10;
        commissions[2] = 10;

        policy.startDate = 1000;
        policy.maturationDate = 1000 + 2 days;
        policy.asset = wethId;
        policy.limit = limitAmount;
        policy.commissionReceivers = commissionReceivers;
        policy.commissionBasisPoints = commissions;

        bytes[] memory signatures = new bytes[](4);

        bytes32 signingHash = nayms.getSigningHash(policy.startDate, policy.maturationDate, policy.asset, policy.limit, offchainDataHash);

        signatures[0] = initPolicySig(0xACC2, signingHash);
        signatures[1] = initPolicySig(0xACC1, signingHash);
        signatures[2] = initPolicySig(0xACC3, signingHash);
        signatures[3] = initPolicySig(0xACC4, signingHash);

        policyStakeholders = Stakeholders(roles, entityIds, signatures);
    }

    function initPolicySig(uint256 privateKey, bytes32 signingHash) internal returns (bytes memory sig_) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(signingHash));
        sig_ = abi.encodePacked(r, s, v);
    }
}
