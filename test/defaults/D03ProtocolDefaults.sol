// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { D02TestSetup, console2, LibHelpers, LibConstants, LibAdmin, LibObject, LibSimplePolicy } from "./D02TestSetup.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Entity, SimplePolicy, SimplePolicyInfo, Stakeholders } from "src/diamonds/nayms/interfaces/FreeStructs.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @notice Default test setup part 03
///         Protocol / project level defaults
///         Setup internal token IDs, entities,
contract D03ProtocolDefaults is D02TestSetup {
    bytes32 public immutable account0Id = LibHelpers._getIdForAddress(address(this));
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

        console2.log("\n -- END TEST SETUP D03 Protocol Defaults --\n");
    }

    function createTestEntity(bytes32 adminId) internal returns (bytes32 entityId) {
        // create entity with signer2 as child
        entityId = "0xe1";
        Entity memory entity1 = initEntity(wethId, 5000, 10000, false);
        nayms.createEntity(entityId, adminId, entity1, bytes32(0));
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
        return initPolicyWithLimit(offchainDataHash, 10_000);
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
        policy.maturationDate = 10000;
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
