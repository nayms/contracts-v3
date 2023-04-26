// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Vm } from "forge-std/Vm.sol";

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers, LibObject } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, MarketInfo, SimplePolicy, Stakeholders } from "src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";

import { LibACL } from "src/diamonds/nayms/libs/LibACL.sol";
import { LibTokenizedVault } from "src/diamonds/nayms/libs/LibTokenizedVault.sol";
import { LibFeeRouterFixture } from "test/fixtures/LibFeeRouterFixture.sol";
import { SimplePolicyFixture } from "test/fixtures/SimplePolicyFixture.sol";

// solhint-disable no-global-import
import "src/diamonds/nayms/interfaces/CustomErrors.sol";

// solhint-disable no-console
contract T04EntityTest is D03ProtocolDefaults {
    bytes32 internal entityId1 = "0xe1";
    bytes32 internal policyId1 = "0xC0FFEE";
    bytes32 public testPolicyDataHash = "test";
    bytes32 public policyHashedTypedData;

    SimplePolicyFixture internal simplePolicyFixture;

    Stakeholders internal stakeholders;
    SimplePolicy internal simplePolicy;

    address internal account9;
    bytes32 internal account9Id;

    function setUp() public virtual override {
        super.setUp();

        account9 = vm.addr(0xACC9);
        account9Id = LibHelpers._getIdForAddress(account9);

        (stakeholders, simplePolicy) = initPolicy(testPolicyDataHash);

        // setup trading commissions fixture
        simplePolicyFixture = new SimplePolicyFixture();
        bytes4[] memory funcSelectors = new bytes4[](2);
        funcSelectors[0] = simplePolicyFixture.getFullInfo.selector;
        funcSelectors[1] = simplePolicyFixture.update.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(simplePolicyFixture), action: IDiamondCut.FacetCutAction.Add, functionSelectors: funcSelectors });

        scheduleAndUpgradeDiamond(cut);
    }

    function getSimplePolicy(bytes32 _policyId) internal returns (SimplePolicy memory) {
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(simplePolicyFixture.getFullInfo.selector, _policyId));
        require(success, "Should get simple policy from app storage");
        return abi.decode(result, (SimplePolicy));
    }

    function updateSimplePolicy(bytes32 _policyId, SimplePolicy memory simplePolicy) internal {
        (bool success, ) = address(nayms).call(abi.encodeWithSelector(simplePolicyFixture.update.selector, _policyId, simplePolicy));
        require(success, "Should update simple policy in app storage");
    }

    function getReadyToCreatePolicies() public {
        // create entity
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5_000, 30_000, true), "test entity");

        // assign entity admin
        nayms.assignRole(account0Id, entityId1, LibConstants.ROLE_ENTITY_ADMIN);
        assertTrue(nayms.isInGroup(account0Id, entityId1, LibConstants.GROUP_ENTITY_ADMINS));

        // fund the entity balance
        uint256 amount = 21000;
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, amount);
        assertEq(weth.balanceOf(account0), amount);
        nayms.externalDeposit(wethAddress, amount);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), amount);
        changePrank(systemAdmin);
    }

    function testDomainSeparator() public {
        bytes32 domainSeparator = nayms.domainSeparatorV4();
        // bytes32 expected = bytes32(0x38c40ddfc309275c926499b83dd3de3a9c824318ef5204fd7ae58f823f845291);
        bytes32 expected = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Nayms")),
                keccak256("1"),
                block.chainid,
                naymsAddress
            )
        );
        assertEq(domainSeparator, expected);

        // change chain id
        vm.chainId(block.chainid + 1);
        // the new domain separator should be different
        assertTrue(nayms.domainSeparatorV4() != expected);
    }

    function testSimplePolicyStructHash() public {
        uint256 startDate;
        uint256 maturationDate;
        bytes32 asset;
        uint256 limit;
        bytes32 offchainDataHash;

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("SimplePolicy(uint256 startDate,uint256 maturationDate,bytes32 asset,uint256 limit,bytes32 offchainDataHash)"),
                startDate,
                maturationDate,
                asset,
                limit,
                offchainDataHash
            )
        );
        bytes32 hashTypedDataV4 = nayms.hashTypedDataV4(structHash);

        bytes32 signingHash = nayms.getSigningHash(startDate, maturationDate, asset, limit, offchainDataHash);
        assertTrue(hashTypedDataV4 == signingHash);
    }

    function testEnableEntityTokenization() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 10000, false), "entity test hash");

        // Attempt to tokenize an entity when the entity does not exist. Should throw an error.
        bytes32 nonExistentEntity = bytes32("ffffaaa");
        vm.expectRevert(abi.encodePacked(EntityDoesNotExist.selector, (nonExistentEntity)));
        nayms.enableEntityTokenization(nonExistentEntity, "123456789012345", "1234567890123456");

        vm.expectRevert("symbol must be less than 16 characters");
        nayms.enableEntityTokenization(entityId1, "1234567890123456", "1234567890123456");

        vm.expectRevert("name must not be empty");
        nayms.enableEntityTokenization(entityId1, "123456789012345", "");

        nayms.enableEntityTokenization(entityId1, "123456789012345", "1234567890123456");

        vm.expectRevert("object already tokenized");
        nayms.enableEntityTokenization(entityId1, "123456789012345", "1234567890123456");
    }

    function testUpdateEntity() public {
        vm.expectRevert(abi.encodePacked(EntityDoesNotExist.selector, (entityId1)));
        nayms.updateEntity(entityId1, initEntity(wethId, 10_000, 0, false));

        console2.logBytes32(wethId);
        nayms.createEntity(entityId1, account0Id, initEntity(0, 0, 0, false), testPolicyDataHash);
        console2.log(" >>> CREATED");

        nayms.addSupportedExternalToken(address(wbtc));
        vm.expectRevert("assetId change not allowed");
        nayms.updateEntity(entityId1, initEntity(wbtcId, 10_000, 0, false));

        vm.expectRevert("only cell has collateral ratio");
        nayms.updateEntity(entityId1, initEntity(0, 1_000, 0, false));

        vm.expectRevert("only cell can issue policies");
        nayms.updateEntity(entityId1, initEntity(0, 0, 0, true));

        vm.expectRevert("only cells have max capacity");
        nayms.updateEntity(entityId1, initEntity(0, 0, 10_000, false));

        vm.recordLogs();
        nayms.updateEntity(entityId1, initEntity(0, 0, 0, false));
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "Invalid event count");
        assertEq(entries[0].topics[0], keccak256("EntityUpdated(bytes32)"));
        assertEq(entries[0].topics[1], entityId1, "EntityUpdated: incorrect entity"); // assert entity
    }

    function testUpdateCell() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 100000, true), testPolicyDataHash);

        vm.expectRevert("external token is not supported");
        nayms.updateEntity(entityId1, initEntity(wbtcId, 0, LibConstants.BP_FACTOR, false));

        vm.expectRevert("collateral ratio should be 1 to 10000");
        nayms.updateEntity(entityId1, initEntity(wethId, 10001, LibConstants.BP_FACTOR, false));

        vm.expectRevert("max capacity should be greater than 0 for policy creation");
        nayms.updateEntity(entityId1, initEntity(wethId, LibConstants.BP_FACTOR, 0, true));

        vm.recordLogs();
        nayms.updateEntity(entityId1, initEntity(wethId, LibConstants.BP_FACTOR, LibConstants.BP_FACTOR, false));
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[1].topics.length, 2, "Invalid event count");
        assertEq(entries[1].topics[0], keccak256("EntityUpdated(bytes32)"));
        assertEq(entries[1].topics[1], entityId1, "EntityUpdated: incorrect entity"); // assert entity
    }

    function testUpdateCellCollateralRatio() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5_000, 30_000, true), "test entity");
        nayms.assignRole(account0Id, entityId1, LibConstants.ROLE_ENTITY_ADMIN);

        // fund the entity balance
        uint256 amount = 5_000;
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, amount);
        nayms.externalDeposit(wethAddress, amount);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), amount);

        assertEq(nayms.getLockedBalance(entityId1, wethId), 0, "NO FUNDS should be locked");

        changePrank(systemAdmin);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, "test");
        uint256 expectedLockedBalance = (simplePolicy.limit * 5_000) / LibConstants.BP_FACTOR;
        assertEq(nayms.getLockedBalance(entityId1, wethId), expectedLockedBalance, "funds SHOULD BE locked");

        Entity memory entity1 = nayms.getEntityInfo(entityId1);
        assertEq(entity1.utilizedCapacity, (simplePolicy.limit * 5_000) / LibConstants.BP_FACTOR, "utilized capacity should increase");

        entity1.collateralRatio = 7_000;
        vm.expectRevert("collateral ratio invalid, not enough balance");
        nayms.updateEntity(entityId1, entity1);

        vm.recordLogs();

        entity1.collateralRatio = 4_000;
        nayms.updateEntity(entityId1, entity1);
        assertEq(nayms.getLockedBalance(entityId1, wethId), (simplePolicy.limit * 4_000) / LibConstants.BP_FACTOR, "locked balance SHOULD decrease");

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "CollateralRatioUpdated: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("CollateralRatioUpdated(bytes32,uint256,uint256)"), "CollateralRatioUpdated: Invalid event signature");
        assertEq(entries[0].topics[1], entityId1, "CollateralRatioUpdated: incorrect entityID");
        (uint256 newCollateralRatio, uint256 newUtilisedCapacity) = abi.decode(entries[0].data, (uint256, uint256));
        assertEq(newCollateralRatio, 4_000, "CollateralRatioUpdated: invalid collateral ratio");
        assertEq(newUtilisedCapacity, (simplePolicy.limit * 4_000) / LibConstants.BP_FACTOR, "CollateralRatioUpdated: invalid utilised capacity");

        Entity memory entity1AfterUpdate = nayms.getEntityInfo(entityId1);
        assertEq(entity1AfterUpdate.utilizedCapacity, (simplePolicy.limit * 4_000) / LibConstants.BP_FACTOR, "utilized capacity should increase");

        nayms.cancelSimplePolicy(policyId1);
        assertEq(nayms.getLockedBalance(entityId1, wethId), 0, "locked balance SHOULD be released");
        Entity memory entity1After2ndUpdate = nayms.getEntityInfo(entityId1);
        assertEq(entity1After2ndUpdate.utilizedCapacity, 0, "utilized capacity should increase");
    }

    function testDuplicateSignerWhenCreatingSimplePolicy() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 10000, true), "entity test hash");

        address alice = vm.addr(0xACC1);
        address bob = vm.addr(0xACC2);
        bytes32 bobId = LibHelpers._getIdForAddress(vm.addr(0xACC2));
        bytes32 aliceId = LibHelpers._getIdForAddress(vm.addr(0xACC1));

        Entity memory entity = Entity({
            assetId: LibHelpers._getIdForAddress(wethAddress),
            collateralRatio: LibConstants.BP_FACTOR,
            maxCapacity: 100 ether,
            utilizedCapacity: 0,
            simplePolicyEnabled: true
        });

        bytes32 eAlice = "ealice";
        bytes32 eBob = "ebob";
        nayms.createEntity(eAlice, aliceId, entity, "entity test hash");
        nayms.createEntity(eBob, bobId, entity, "entity test hash");

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        nayms.externalDeposit(wethAddress, 100000);

        bytes32 signingHash = nayms.getSigningHash(simplePolicy.startDate, simplePolicy.maturationDate, simplePolicy.asset, simplePolicy.limit, testPolicyDataHash);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = initPolicySig(0xACC1, signingHash); // 0x2337f702bc9A7D1f415050365634FEbEdf4054Be
        signatures[1] = initPolicySig(0xACC2, signingHash); // 0x167D6b35e51df22f42c4F42f26d365756D244fDE
        signatures[2] = initPolicySig(0xACC3, signingHash); // 0x167D6b35e51df22f42c4F42f26d365756D244fDE

        bytes32[] memory roles = new bytes32[](3);
        roles[0] = LibHelpers._stringToBytes32(LibConstants.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LibConstants.ROLE_BROKER);
        roles[2] = LibHelpers._stringToBytes32(LibConstants.ROLE_CAPITAL_PROVIDER);

        bytes32[] memory entityIds = new bytes32[](3);
        entityIds[0] = eAlice;
        entityIds[1] = eBob;
        entityIds[1] = "eEve";

        Stakeholders memory stakeholders = Stakeholders(roles, entityIds, signatures);

        changePrank(systemAdmin);
        vm.expectRevert(abi.encodeWithSelector(DuplicateSignerCreatingSimplePolicy.selector, alice, bob));
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
    }

    function testSignatureWhenCreatingSimplePolicy() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 10000, true), "entity test hash");

        bytes32 bobId = LibHelpers._getIdForAddress(vm.addr(0xACC1));
        bytes32 aliceId = LibHelpers._getIdForAddress(vm.addr(0xACC2));
        bytes32 eveId = LibHelpers._getIdForAddress(vm.addr(0xACC3));

        Entity memory entity = Entity({
            assetId: LibHelpers._getIdForAddress(wethAddress),
            collateralRatio: LibConstants.BP_FACTOR,
            maxCapacity: 100 ether,
            utilizedCapacity: 0,
            simplePolicyEnabled: true
        });

        bytes32 eAlice = "eAlice";
        bytes32 eBob = "eBob";
        bytes32 eEve = "eEve";
        nayms.createEntity(eAlice, aliceId, entity, "entity test hash");
        nayms.createEntity(eBob, bobId, entity, "entity test hash");
        nayms.createEntity(eEve, eveId, entity, "entity test hash");

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        nayms.externalDeposit(wethAddress, 100000);

        bytes32 signingHash = nayms.getSigningHash(simplePolicy.startDate, simplePolicy.maturationDate, simplePolicy.asset, simplePolicy.limit, testPolicyDataHash);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = initPolicySig(0xACC2, signingHash);
        signatures[1] = initPolicySig(0xACC1, signingHash);
        signatures[2] = initPolicySig(0xACC3, signingHash);

        bytes32[] memory roles = new bytes32[](3);
        roles[0] = LibHelpers._stringToBytes32(LibConstants.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LibConstants.ROLE_BROKER);
        roles[2] = LibHelpers._stringToBytes32(LibConstants.ROLE_CAPITAL_PROVIDER);

        bytes32[] memory entityIds = new bytes32[](3);
        entityIds[0] = eAlice;
        entityIds[1] = eBob;
        entityIds[2] = eEve;

        Stakeholders memory stakeholders = Stakeholders(roles, entityIds, signatures);

        changePrank(systemAdmin);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
    }

    function testCreateSimplePolicyValidation() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, LibConstants.BP_FACTOR, LibConstants.BP_FACTOR, false), "entity test hash");

        // enable simple policy creation
        vm.expectRevert("simple policy creation disabled");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        nayms.updateEntity(entityId1, initEntity(wethId, LibConstants.BP_FACTOR, LibConstants.BP_FACTOR, true));

        // stakeholders entity ids array different length to signatures array
        bytes[] memory sig = stakeholders.signatures;
        stakeholders.signatures = new bytes[](0);
        vm.expectRevert("incorrect number of signatures");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        stakeholders.signatures = sig;

        // test limit
        simplePolicy.limit = 0;
        vm.expectRevert("limit not > 0");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.limit = 100000;

        bytes32 signingHash = nayms.getSigningHash(simplePolicy.startDate, simplePolicy.maturationDate, simplePolicy.asset, simplePolicy.limit, testPolicyDataHash);

        stakeholders.signatures[0] = initPolicySig(0xACC2, signingHash);
        stakeholders.signatures[1] = initPolicySig(0xACC1, signingHash);
        stakeholders.signatures[2] = initPolicySig(0xACC3, signingHash);
        stakeholders.signatures[3] = initPolicySig(0xACC4, signingHash);

        // external token not supported
        vm.expectRevert("external token is not supported");
        simplePolicy.asset = LibHelpers._getIdForAddress(wbtcAddress);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        nayms.addSupportedExternalToken(wbtcAddress);
        simplePolicy.asset = wbtcId;
        vm.expectRevert("asset not matching with entity");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.asset = wethId;

        // test caller is system manager
        vm.expectRevert("not a system manager");
        changePrank(account9);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        changePrank(systemAdmin);
        // test capacity
        vm.expectRevert("not enough available capacity");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // update max capacity
        nayms.updateEntity(entityId1, initEntity(wethId, 5000, 300000, true));

        // test collateral ratio constraint
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // fund the policy sponsor entity
        nayms.updateEntity(entityId1, initEntity(wethId, 5000, 300000, true));
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        assertEq(weth.balanceOf(account0), 100000);
        nayms.externalDeposit(wethAddress, 100000);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), 100000);

        changePrank(systemAdmin);

        // start date too early
        vm.warp(1);
        simplePolicy.startDate = block.timestamp - 1;
        vm.expectRevert("start date < block.timestamp");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.startDate = 1000;

        // start date after maturation date
        simplePolicy.startDate = simplePolicy.maturationDate;
        vm.expectRevert("start date > maturation date");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.startDate = 1000;

        uint256 maturationDateOrig = simplePolicy.maturationDate;
        simplePolicy.maturationDate = simplePolicy.startDate + 1;
        vm.expectRevert("policy period must be more than a day");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.maturationDate = maturationDateOrig;

        // commission receivers
        vm.expectRevert("must have commission receivers");
        bytes32[] memory commissionReceiversOrig = simplePolicy.commissionReceivers;
        simplePolicy.commissionReceivers = new bytes32[](0);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.commissionReceivers = commissionReceiversOrig;

        // commission basis points
        vm.expectRevert("number of commissions don't match");
        uint256[] memory commissionBasisPointsOrig = simplePolicy.commissionBasisPoints;
        simplePolicy.commissionBasisPoints = new uint256[](0);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.commissionBasisPoints = commissionBasisPointsOrig;

        // commission basis points array and commission receivers array must have same length
        vm.expectRevert("number of commissions don't match");
        simplePolicy.commissionBasisPoints = new uint256[](1);
        simplePolicy.commissionBasisPoints.push(1);
        simplePolicy.commissionReceivers = new bytes32[](2);
        simplePolicy.commissionReceivers.push(keccak256("a"));
        simplePolicy.commissionReceivers.push(keccak256("b"));
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.commissionBasisPoints = commissionBasisPointsOrig;
        simplePolicy.commissionReceivers = commissionReceiversOrig;

        // commission basis points total > 10000
        vm.expectRevert("bp cannot be > 10000");
        simplePolicy.commissionReceivers = new bytes32[](1);
        simplePolicy.commissionReceivers.push(keccak256("a"));
        simplePolicy.commissionBasisPoints = new uint256[](1);
        simplePolicy.commissionBasisPoints.push(10001);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.commissionBasisPoints = commissionBasisPointsOrig;
        simplePolicy.commissionReceivers = commissionReceiversOrig;

        // create it successfully
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        SimplePolicy memory simplePolicyInfo = nayms.getSimplePolicyInfo(policyId1);
        assertEq(simplePolicyInfo.startDate, simplePolicy.startDate, "Start dates should match");
        assertEq(simplePolicyInfo.maturationDate, simplePolicy.maturationDate, "Maturation dates should match");
        assertEq(simplePolicyInfo.asset, simplePolicy.asset, "Assets should match");
        assertEq(simplePolicyInfo.limit, simplePolicy.limit, "Limits should match");
        assertEq(simplePolicyInfo.fundsLocked, true, "Fund should be locked");
        assertEq(simplePolicyInfo.cancelled, false, "Cancelled flags should be false");
        assertEq(simplePolicyInfo.claimsPaid, simplePolicy.claimsPaid, "Claims paid amounts should match");
        assertEq(simplePolicyInfo.premiumsPaid, simplePolicy.premiumsPaid, "Premiums paid amounts should match");

        bytes32[] memory roles = new bytes32[](2);
        roles[0] = LibHelpers._stringToBytes32(LibConstants.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LibConstants.ROLE_BROKER);

        stakeholders.roles = roles;
        vm.expectRevert("too many commission receivers");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
    }

    function testCreateSimplePolicyAlreadyExists() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // todo: improve this error message when a premium is being created with the same premium ID
        vm.expectRevert("objectId is already being used by another object");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
    }

    function testCreateSimplePolicyUpdatesEntityUtilizedCapacity() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // check utilized capacity of entity
        Entity memory e = nayms.getEntityInfo(entityId1);
        assertEq(e.utilizedCapacity, (10_000 * e.collateralRatio) / LibConstants.BP_FACTOR, "utilized capacity");

        bytes32 policyId2 = "0xC0FFEF";
        (Stakeholders memory stakeholders2, SimplePolicy memory policy2) = initPolicy(testPolicyDataHash);
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders2, policy2, testPolicyDataHash);

        e = nayms.getEntityInfo(entityId1);
        assertEq(e.utilizedCapacity, (20_000 * e.collateralRatio) / LibConstants.BP_FACTOR, "utilized capacity");
    }

    function testCreateSimplePolicyFundsAreLockedInitially() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        SimplePolicy memory p = getSimplePolicy(policyId1);
        assertTrue(p.fundsLocked, "funds locked");
    }

    function testCreateSimplePolicyStakeholderEntitiesAreNotSignersParent() public {
        getReadyToCreatePolicies();

        bytes32[] memory signerIds = new bytes32[](4);
        signerIds[0] = signer1Id;
        signerIds[1] = signer2Id;
        signerIds[2] = signer3Id;
        signerIds[3] = signer4Id;

        uint256 rolesCount = 1; //stakeholders.roles.length;
        for (uint256 i = 0; i < rolesCount; i++) {
            bytes32 signerId = signerIds[i];

            // check permissions
            assertEq(nayms.getEntity(signerId), stakeholders.entityIds[i], "must be parent");

            // change parent
            nayms.setEntity(signerId, bytes32("e0"));

            // try creating
            vm.expectRevert();
            nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

            nayms.setEntity(signerId, stakeholders.entityIds[i]);
        }
    }

    function testCreateSimplePolicyEntitiesAreAssignedRolesOnPolicy() public {
        getReadyToCreatePolicies();

        string[] memory groups = new string[](4);
        groups[0] = LibConstants.GROUP_UNDERWRITERS;
        groups[1] = LibConstants.GROUP_BROKERS;
        groups[2] = LibConstants.GROUP_CAPITAL_PROVIDERS;
        groups[3] = LibConstants.GROUP_INSURED_PARTIES;

        uint256 rolesCount = stakeholders.roles.length;
        for (uint256 i = 0; i < rolesCount; i++) {
            assertFalse(nayms.isInGroup(stakeholders.entityIds[i], policyId1, groups[i]), "not in group yet");
        }

        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        for (uint256 i = 0; i < rolesCount; i++) {
            assertTrue(nayms.isInGroup(stakeholders.entityIds[i], policyId1, groups[i]), "in group");
        }
    }

    function testCreateSimplePolicyEmitsEvent() public {
        getReadyToCreatePolicies();

        vm.recordLogs();

        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        // events: 4 role assignments + 1 policy creation => we want event at index 4
        assertEq(entries[5].topics.length, 2);
        assertEq(entries[5].topics[0], keccak256("SimplePolicyCreated(bytes32,bytes32)"));
        assertEq(entries[5].topics[1], policyId1);
        bytes32 entityId = abi.decode(entries[5].data, (bytes32));
        assertEq(entityId, entityId1);
    }

    function testSimplePolicyEntityCapitalUtilization100CR() public {
        // create entity with 100% collateral ratio
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 10_000, 30_000, true), "test entity");

        // assign entity admin
        nayms.assignRole(account0Id, entityId1, LibConstants.ROLE_ENTITY_ADMIN);

        // fund the entity balance
        uint256 amount = 21000;
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, amount);
        nayms.externalDeposit(wethAddress, amount);

        changePrank(systemAdmin);
        // create policyId1 with limit of 21000
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 21000);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 21000, "entity balance of nWETH");
        assertEq(nayms.getEntityInfo(entityId1).utilizedCapacity, 21000, "entity utilization should INCREASE when a policy is created");
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000, "entity locked balance should INCREASE when a policy is created");

        // note: entity with 100% CR should be able to pay the claim - claim amount comes from the locked balance (locked in the policy)
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 2);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 21000 - 2, "entity balance of nWETH should DECREASE by pay claim amount");
        assertEq(nayms.getEntityInfo(entityId1).utilizedCapacity, 21000 - 2, "entity utilization should DECREASE when a claim is made");
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 2, "entity locked balance should DECREASE");

        // increase max cap from 30_000 to 221_000
        Entity memory newEInfo = nayms.getEntityInfo(entityId1);
        newEInfo.maxCapacity = 221_000;
        nayms.updateEntity(entityId1, newEInfo);

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 200_000);
        nayms.externalDeposit(wethAddress, 200_000);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 20998 + 200_000, "after deposit, entity balance of nWETH should INCREASE");

        changePrank(systemAdmin);
        bytes32 policyId2 = LibHelpers._stringToBytes32("policyId2");

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 200_001);
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 200_000);
        // note: brings us to 100% max capacity
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 2 + 200_000, "locked balance should INCREASE");

        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId2"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId3"), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        nayms.cancelSimplePolicy(policyId1);

        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 200_000 - 3, "after cancelling policy, the locked balance should DECREASE");

        changePrank(account0);
        vm.expectRevert("_internalBurn: insufficient balance available, funds locked");
        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 21_000);

        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 21_000 - 2 - 3);
    }

    function testSimplePolicyEntityCapitalUtilization50CR() public {
        getReadyToCreatePolicies();

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 42002);
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // create policyId1 with limit of 42000
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 42000);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000, "locked balance should INCREASE");

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 2);

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 1);
        nayms.externalDeposit(wethAddress, 1);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 21001, "entity balance of nWETH should INCREASE by deposit amount");

        changePrank(systemAdmin);
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 2); // claiming 2
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 20999, "entity balance of nWETH should DECREASE by pay claim amount");
        assertEq(nayms.getEntityInfo(entityId1).utilizedCapacity, 21000 - 1, "entity utilization should DECREASE when a claim is made");
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 1, "entity locked balance should DECREASE");

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 200_000);
        nayms.externalDeposit(wethAddress, 200_000);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 20999 + 200_000, "after deposit, entity balance of nWETH should INCREASE");

        // increase max cap from 30_000 to 221_000
        Entity memory newEInfo = nayms.getEntityInfo(entityId1);
        newEInfo.maxCapacity = 221_000;
        changePrank(systemAdmin);
        nayms.updateEntity(entityId1, newEInfo);

        bytes32 policyId2 = LibHelpers._stringToBytes32("policyId2");

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 400_003);
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 400_000);
        // note: brings us to 100% max capacity
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 1 + 200_000, "locked balance should INCREASE");

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId2"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId2"), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        nayms.cancelSimplePolicy(policyId1);

        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 1 + 200_000 - 20999, "after cancelling policy, the locked balance should DECREASE");

        changePrank(account0);
        vm.expectRevert("_internalBurn: insufficient balance available, funds locked");
        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 21_000);

        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 21_000 - 1);

        changePrank(systemAdmin);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId2"), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 1);

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 1);
        nayms.externalDeposit(wethAddress, 1);

        changePrank(systemAdmin);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId2"), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId2"), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 1);
    }

    function testSimplePolicyLockedBalancesAfterPaySimpleClaim() public {
        getReadyToCreatePolicies();

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 42002);
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // create policyId1 with limit of 42000
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 42000);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000, "locked balance should INCREASE");

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 21000);

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 20000);
        nayms.externalDeposit(wethAddress, 20000);

        changePrank(systemAdmin);

        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 21000);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 10500, "locked balance should DECREASE by half");

        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId1"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 1000);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 10000, "locked balance should DECREASE");

        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId2"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 1000);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 9500, "locked balance should DECREASE");

        nayms.internalBalanceOf(entityId1, simplePolicy.asset);
        // note: entity now has balance of 18000, locked balance of 9500
        // attempting to pay a claim that's above the entity's balance, below the policy limit triggers the following error
        vm.expectRevert("_internalTransfer: insufficient balance");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId3"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 19000);
    }

    function testSimplePolicyPremiumsCommissionsClaims() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        vm.expectRevert("not a policy handler");
        nayms.paySimplePremium(policyId1, 1000);

        changePrank(signer2);

        simplePolicy.cancelled = true;
        updateSimplePolicy(policyId1, simplePolicy);
        vm.expectRevert("Policy is cancelled");
        nayms.paySimplePremium(policyId1, 1000);
        simplePolicy.cancelled = false;
        updateSimplePolicy(policyId1, simplePolicy);

        vm.expectRevert("invalid premium amount");
        nayms.paySimplePremium(policyId1, 0);

        vm.stopPrank();

        // fund the insured party entity
        vm.startPrank(signer4);
        writeTokenBalance(signer4, naymsAddress, wethAddress, 100000);
        nayms.externalDeposit(wethAddress, 100000);
        vm.stopPrank();
        assertEq(nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, wethId), 100000);

        // test commissions
        {
            assertEq(simplePolicy.premiumsPaid, 0);

            uint256 premiumAmount = 10000;
            uint256 balanceBeforePremium = nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, wethId);

            vm.startPrank(signer4);
            nayms.paySimplePremium(policyId1, premiumAmount);
            vm.stopPrank();

            uint256 netPremiumAmount = premiumAmount;
            for (uint256 i = 0; i < simplePolicy.commissionReceivers.length; ++i) {
                uint256 commission = (premiumAmount * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
                netPremiumAmount -= commission;
                assertEq(nayms.internalBalanceOf(simplePolicy.commissionReceivers[i], simplePolicy.asset), commission);
            }
            simplePolicy = getSimplePolicy(policyId1);
            assertEq(simplePolicy.premiumsPaid, premiumAmount);
            assertEq(nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, wethId), balanceBeforePremium - premiumAmount);
        }

        changePrank(systemAdmin);

        simplePolicy.cancelled = true;
        updateSimplePolicy(policyId1, simplePolicy);
        vm.expectRevert("Policy is cancelled");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 1000);
        simplePolicy.fundsLocked = true;
        simplePolicy.cancelled = false;
        updateSimplePolicy(policyId1, simplePolicy);

        changePrank(account9);
        vm.expectRevert("not a system manager");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 10000);

        changePrank(systemAdmin);

        vm.expectRevert("not an insured party");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, 0, 10000);

        vm.expectRevert("invalid claim amount");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 0);

        // setup insured party account
        nayms.assignRole(LibHelpers._getIdForAddress(signer4), DEFAULT_INSURED_PARTY_ENTITY_ID, LibConstants.ROLE_INSURED_PARTY);
        assertTrue(nayms.isInGroup(LibHelpers._getIdForAddress(signer4), DEFAULT_INSURED_PARTY_ENTITY_ID, LibConstants.GROUP_INSURED_PARTIES));
        nayms.setEntity(LibHelpers._getIdForAddress(signer4), DEFAULT_INSURED_PARTY_ENTITY_ID);

        vm.expectRevert("exceeds policy limit");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 100001);

        uint256 claimAmount = 10000;
        uint256 balanceBeforeClaim = nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, simplePolicy.asset);
        simplePolicy = getSimplePolicy(policyId1);
        assertEq(simplePolicy.claimsPaid, 0);

        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, claimAmount);

        simplePolicy = getSimplePolicy(policyId1);
        assertEq(simplePolicy.claimsPaid, 10000);

        assertEq(nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, simplePolicy.asset), balanceBeforeClaim + claimAmount);
    }

    function testTokenSale() public {
        // whitelist underlying token
        nayms.addSupportedExternalToken(wethAddress);

        uint256 sellAmount = 1000;
        uint256 sellAtPrice = 1000;

        Entity memory entity1 = initEntity(wethId, 5000, 10000, false);
        nayms.createEntity(entityId1, account0Id, entity1, "entity test hash");

        assertEq(nayms.getLastOfferId(), 0);

        vm.expectRevert(abi.encodeWithSelector(ObjectCannotBeTokenized.selector, entityId1));
        nayms.startTokenSale(entityId1, sellAmount, sellAtPrice);

        nayms.enableEntityTokenization(entityId1, "e1token", "e1token");

        changePrank(account9);
        vm.expectRevert("not a system manager");
        nayms.startTokenSale(entityId1, sellAmount, sellAtPrice);
        vm.stopPrank();

        changePrank(systemAdmin);
        vm.expectRevert("mint amount must be > 0");
        nayms.startTokenSale(entityId1, 0, sellAtPrice);

        vm.expectRevert("total price must be > 0");
        nayms.startTokenSale(entityId1, sellAmount, 0);

        nayms.startTokenSale(entityId1, sellAmount, sellAtPrice);

        uint256 lastOfferId = nayms.getLastOfferId();
        assertEq(lastOfferId, 1);

        MarketInfo memory marketInfo = nayms.getOffer(lastOfferId);
        assertEq(marketInfo.creator, entityId1);
        assertEq(marketInfo.sellToken, entityId1);
        assertEq(marketInfo.sellAmount, sellAmount);
        assertEq(marketInfo.buyToken, entity1.assetId);
        assertEq(marketInfo.buyAmount, sellAtPrice);
        assertEq(marketInfo.state, LibConstants.OFFER_STATE_ACTIVE);
    }

    function testCheckAndUpdateSimplePolicyState() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        Entity memory entityBefore = nayms.getEntityInfo(entityId1);
        uint256 utilizedCapacityBefore = entityBefore.utilizedCapacity;

        vm.warp(simplePolicy.maturationDate + 1);

        // utilized capacity doesn't change, on cancelled policy
        simplePolicy.cancelled = true;
        updateSimplePolicy(policyId1, simplePolicy);

        nayms.checkAndUpdateSimplePolicyState(policyId1);
        Entity memory entityAfter = nayms.getEntityInfo(entityId1);
        assertEq(utilizedCapacityBefore, entityAfter.utilizedCapacity, "utilized capacity should not change");

        // revert changes
        simplePolicy.cancelled = false;
        simplePolicy.fundsLocked = true;
        updateSimplePolicy(policyId1, simplePolicy);

        nayms.checkAndUpdateSimplePolicyState(policyId1);
        Entity memory entityAfter2 = nayms.getEntityInfo(entityId1);
        uint256 expectedUtilizedCapacity = utilizedCapacityBefore - (simplePolicy.limit * entityAfter2.collateralRatio) / LibConstants.BP_FACTOR;
        assertEq(expectedUtilizedCapacity, entityAfter2.utilizedCapacity, "utilized capacity should increase");
    }

    function testPayPremiumCommissions() public {
        // Deploy the LibFeeRouterFixture
        LibFeeRouterFixture libFeeRouterFixture = new LibFeeRouterFixture();

        bytes4[] memory functionSelectors = new bytes4[](5);
        functionSelectors[0] = libFeeRouterFixture.payPremiumCommissions.selector;
        functionSelectors[1] = libFeeRouterFixture.payTradingCommissions.selector;
        functionSelectors[2] = libFeeRouterFixture.calculateTradingCommissionsFixture.selector;
        functionSelectors[3] = libFeeRouterFixture.getTradingCommissionsBasisPointsFixture.selector;
        functionSelectors[4] = libFeeRouterFixture.getPremiumCommissionBasisPointsFixture.selector;

        // Diamond cut this fixture contract into our nayms diamond in order to test against the diamond
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(libFeeRouterFixture), action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });

        scheduleAndUpgradeDiamond(cut);

        getReadyToCreatePolicies();

        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        uint256 premiumPaid = 10_000;
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(libFeeRouterFixture.payPremiumCommissions.selector, policyId1, premiumPaid));
        (success, result) = address(nayms).call(abi.encodeWithSelector(libFeeRouterFixture.getPremiumCommissionBasisPointsFixture.selector));

        uint256 commissionNaymsLtd = (premiumPaid * nayms.getPremiumCommissionBasisPoints().premiumCommissionNaymsLtdBP) / LibConstants.BP_FACTOR;
        uint256 commissionNDF = (premiumPaid * nayms.getPremiumCommissionBasisPoints().premiumCommissionNDFBP) / LibConstants.BP_FACTOR;
        uint256 commissionSTM = (premiumPaid * nayms.getPremiumCommissionBasisPoints().premiumCommissionSTMBP) / LibConstants.BP_FACTOR;

        SimplePolicy memory sp = getSimplePolicy(policyId1);

        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), sp.asset), commissionNaymsLtd, "Nayms LTD commission incorrect");
        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), sp.asset), commissionNDF, "NDF commission incorrect");
        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), sp.asset), commissionSTM, "STM commission incorrect");
    }

    function testCancelSimplePolicy() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        Entity memory entityBefore = nayms.getEntityInfo(entityId1);
        uint256 utilizedCapacityBefore = entityBefore.utilizedCapacity;

        nayms.cancelSimplePolicy(policyId1);

        Entity memory entityAfter = nayms.getEntityInfo(entityId1);
        assertEq(
            utilizedCapacityBefore - ((simplePolicy.limit * entityAfter.collateralRatio) / LibConstants.BP_FACTOR),
            entityAfter.utilizedCapacity,
            "utilized capacity should change"
        );

        SimplePolicy memory simplePolicyInfo = nayms.getSimplePolicyInfo(policyId1);
        assertEq(simplePolicyInfo.cancelled, true, "Simple policy should be cancelled");

        vm.expectRevert("Policy already cancelled");
        nayms.cancelSimplePolicy(policyId1);
    }

    function testUtilizedCapacityMustBeZeroOnEntityCreate() public {
        // prettier-ignore
        Entity memory e = Entity({ 
            assetId: wethId, 
            collateralRatio: 5_000, 
            maxCapacity: 10_000, 
            utilizedCapacity: 10_000, 
            simplePolicyEnabled: false 
        });

        vm.expectRevert("utilized capacity starts at 0");
        nayms.createEntity(entityId1, account0Id, e, "entity test hash");
    }
}
