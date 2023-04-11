// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable-next-line no-global-import
import "./D02TestSetup.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Entity, SimplePolicy, SimplePolicyInfo, Stakeholders } from "src/diamonds/nayms/interfaces/FreeStructs.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
 * D03ProtocolDefaults (D03ProtocolDefaults.sol)
 *
 * This file is responsible for setting up protocol-specific configurations,
 * variables, and defaults required for testing.
 *
 * Key features and responsibilities of this file include:
 *   - Defining protocol-specific variables or configurations.
 *   - Setting default values for protocol-specific settings.
 *   - Providing helper functions or utilities specific to the protocol being
 *     tested.
 *
 * The D03ProtocolDefaults.sol file should focus on providing protocol-specific
 * settings and configurations that are essential for conducting accurate and
 * reliable tests.
 */

contract D03ProtocolDefaults is D02TestSetup {
    bytes32 public naymsTokenId;
    bytes32 public wethId;
    bytes32 public wbtcId;

    bytes32 public immutable systemContext = LibAdmin._getSystemId();

    bytes32 public constant DEFAULT_ACCOUNT0_ENTITY_ID = 0xe000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_UNDERWRITER_ENTITY_ID = 0xe100000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_BROKER_ENTITY_ID = 0xe200000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_CAPITAL_PROVIDER_ENTITY_ID = 0xe300000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant DEFAULT_INSURED_PARTY_ENTITY_ID = 0xe400000000000000000000000000000000000000000000000000000000000000;

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

        wethId = LibHelpers._getIdForAddress(wethAddress);
        wbtcId = LibHelpers._getIdForAddress(wbtcAddress);

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

    function createTestEntity(bytes32 adminId) internal returns (bytes32) {
        return createTestEntityWithId(adminId, "0xe1");
    }

    function createTestEntityWithId(bytes32 adminId, bytes32 entityId) internal returns (bytes32) {
        Entity memory entity1 = initEntity(wethId, 5000, 10000, false);

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

    function initPolicy(bytes32 offchainDataHash) internal view returns (Stakeholders memory policyStakeholders, SimplePolicy memory policy) {
        return initPolicyWithLimit(offchainDataHash, 10_000);
    }

    function initPolicyWithLimit(bytes32 offchainDataHash, uint256 limitAmount) internal view returns (Stakeholders memory policyStakeholders, SimplePolicy memory policy) {
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

        policy.startDate = block.timestamp + 1000;
        policy.maturationDate = block.timestamp + 10000;
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

    function initPolicySig(uint256 privateKey, bytes32 signingHash) internal pure returns (bytes memory sig_) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ECDSA.toEthSignedMessageHash(signingHash));
        sig_ = abi.encodePacked(r, s, v);
    }
}
