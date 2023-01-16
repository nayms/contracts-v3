// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Vm } from "forge-std/Vm.sol";

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, MarketInfo, SimplePolicy, SimplePolicyInfo, Stakeholders } from "src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";

import { LibACL } from "src/diamonds/nayms/libs/LibACL.sol";
import { LibTokenizedVault } from "src/diamonds/nayms/libs/LibTokenizedVault.sol";
import { LibFeeRouterFixture } from "test/fixtures/LibFeeRouterFixture.sol";
import { SimplePolicyFixture } from "test/fixtures/SimplePolicyFixture.sol";
import "src/diamonds/nayms/interfaces/CustomErrors.sol";

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
        // bytes32 structHash = keccak256(abi.encode(keccak256("PolicyHash(bytes32 dataHash))"), testPolicyDataHash));

        // policyHashedTypedData = nayms.hashTypedDataV4(structHash);

        (stakeholders, simplePolicy) = initPolicy(testPolicyDataHash);

        // setup trading commissions fixture
        simplePolicyFixture = new SimplePolicyFixture();
        bytes4[] memory funcSelectors = new bytes4[](2);
        funcSelectors[0] = simplePolicyFixture.getFullInfo.selector;
        funcSelectors[1] = simplePolicyFixture.update.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(simplePolicyFixture), action: IDiamondCut.FacetCutAction.Add, functionSelectors: funcSelectors });

        nayms.diamondCut(cut, address(0), "");
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
        weth.approve(naymsAddress, amount);
        writeTokenBalance(account0, naymsAddress, wethAddress, amount);
        assertEq(weth.balanceOf(account0), amount);
        nayms.externalDeposit(wethAddress, amount);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), amount);
    }

    function testDomainSeparator() public {
        bytes32 domainSeparator = nayms.domainSeparatorV4();

        bytes32 expected = bytes32(0x2558bfb28c101059c8344fa723b1d53b41339016ca92a7b1cf0d1b9d8b75c01c);
        assertEq(domainSeparator, expected);
    }

    function testEnableEntityTokenization() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 10000, false), "entity test hash");

        // Attempt to tokenize an entity when the entity does not exist. Should throw an error.
        bytes32 nonExistentEntity = bytes32("ffffaaa");
        vm.expectRevert(abi.encodePacked(EntityDoesNotExist.selector, (nonExistentEntity)));
        nayms.enableEntityTokenization(nonExistentEntity, "123456789012345", "1234567890123456");

        vm.expectRevert("symbol must be less than 16 characters");
        nayms.enableEntityTokenization(entityId1, "1234567890123456", "1234567890123456");

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
        weth.approve(naymsAddress, amount);
        writeTokenBalance(account0, naymsAddress, wethAddress, amount);
        nayms.externalDeposit(wethAddress, amount);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), amount);

        assertEq(nayms.getLockedBalance(entityId1, wethId), 0, "NO FUNDS shoud be locked");

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

        weth.approve(naymsAddress, 10000);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        nayms.externalDeposit(wethAddress, 100000);

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = initPolicySig(0xACC1, eAlice, testPolicyDataHash); // 0x2337f702bc9A7D1f415050365634FEbEdf4054Be
        signatures[1] = initPolicySig(0xACC2, eBob, testPolicyDataHash); // 0x167D6b35e51df22f42c4F42f26d365756D244fDE

        bytes32[] memory roles = new bytes32[](2);
        roles[0] = LibHelpers._stringToBytes32(LibConstants.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LibConstants.ROLE_BROKER);

        bytes32[] memory entityIds = new bytes32[](2);
        entityIds[0] = eAlice;
        entityIds[1] = eBob;

        Stakeholders memory stakeholders = Stakeholders(roles, entityIds, signatures);

        vm.expectRevert(abi.encodeWithSelector(DuplicateSignerCreatingSimplePolicy.selector, alice, bob));
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
    }

    function testSignatureWhenCreatingSimplePolicy() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 10000, true), "entity test hash");

        address alice = vm.addr(0xACC2);
        address bob = vm.addr(0xACC1);
        bytes32 bobId = LibHelpers._getIdForAddress(vm.addr(0xACC1));
        bytes32 aliceId = LibHelpers._getIdForAddress(vm.addr(0xACC2));

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

        weth.approve(naymsAddress, 10000);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        nayms.externalDeposit(wethAddress, 100000);

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = initPolicySig(0xACC2, eAlice, testPolicyDataHash);
        signatures[1] = initPolicySig(0xACC1, eBob, testPolicyDataHash);

        bytes32[] memory roles = new bytes32[](2);
        roles[0] = LibHelpers._stringToBytes32(LibConstants.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LibConstants.ROLE_BROKER);

        bytes32[] memory entityIds = new bytes32[](2);
        entityIds[0] = eAlice;
        entityIds[1] = eBob;

        Stakeholders memory stakeholders = Stakeholders(roles, entityIds, signatures);

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
        vm.prank(account9);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        vm.stopPrank();

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
        weth.approve(naymsAddress, 10000);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        assertEq(weth.balanceOf(account0), 100000);
        nayms.externalDeposit(wethAddress, 100000);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), 100000);

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

        // commission receivers
        vm.expectRevert("must have commission receivers");
        bytes32[] memory commissionReceiversOrig = simplePolicy.commissionReceivers;
        simplePolicy.commissionReceivers = new bytes32[](0);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.commissionReceivers = commissionReceiversOrig;

        // commission basis points
        vm.expectRevert("must have commission basis points");
        uint256[] memory commissionBasisPointsOrig = simplePolicy.commissionBasisPoints;
        simplePolicy.commissionBasisPoints = new uint256[](0);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.commissionBasisPoints = commissionBasisPointsOrig;

        // commission basis points array and commission receivers array must have same length
        vm.expectRevert("commissions lengths !=");
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

        SimplePolicyInfo memory simplePolicyInfo = nayms.getSimplePolicyInfo(policyId1);
        assertEq(simplePolicyInfo.startDate, simplePolicy.startDate, "Start dates should match");
        assertEq(simplePolicyInfo.maturationDate, simplePolicy.maturationDate, "Maturation dates should match");
        assertEq(simplePolicyInfo.asset, simplePolicy.asset, "Assets should match");
        assertEq(simplePolicyInfo.limit, simplePolicy.limit, "Limits should match");
        assertEq(simplePolicyInfo.fundsLocked, true, "Fund should be locked");
        assertEq(simplePolicyInfo.cancelled, false, "Cancelled flags should be false");
        assertEq(simplePolicyInfo.claimsPaid, simplePolicy.claimsPaid, "Claims paid amounts should match");
        assertEq(simplePolicyInfo.premiumsPaid, simplePolicy.premiumsPaid, "Premiums paid amounts should match");
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

    function testCreateSimplePolicySignersAreNotEntityAdminsOfStakeholderEntities() public {
        getReadyToCreatePolicies();

        // assign parent entity as system manager so that I can assign roles below
        nayms.assignRole(entityId1, systemContext, LibConstants.ROLE_SYSTEM_MANAGER);

        bytes32[] memory signerIds = new bytes32[](4);
        signerIds[0] = signer1Id;
        signerIds[1] = signer1Id;
        signerIds[2] = signer1Id;
        signerIds[3] = signer1Id;

        uint256 rolesCount = 1; //stakeholders.roles.length;
        for (uint256 i = 0; i < rolesCount; i++) {
            bytes32 signerId = signerIds[i];

            // check permissions
            assertEq(nayms.getRoleInContext(signerId, stakeholders.entityIds[i]), LibHelpers._stringToBytes32(LibConstants.ROLE_ENTITY_ADMIN), "must have role");
            assertTrue(nayms.canAssign(account0Id, signerId, stakeholders.entityIds[i], LibConstants.ROLE_ENTITY_ADMIN), "can assign");

            // remove role
            nayms.unassignRole(signerId, stakeholders.entityIds[i]);

            // try creating
            vm.expectRevert("invalid stakeholder");
            nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

            // restore role
            nayms.assignRole(signerId, stakeholders.entityIds[i], LibConstants.ROLE_ENTITY_ADMIN);
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
        assertEq(entries[4].topics.length, 2);
        assertEq(entries[4].topics[0], keccak256("SimplePolicyCreated(bytes32,bytes32)"));
        assertEq(entries[4].topics[1], policyId1);
        bytes32 entityId = abi.decode(entries[4].data, (bytes32));
        assertEq(entityId, entityId1);
    }

    function testSimplePolicyPremiumsCommissionsClaims() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        vm.expectRevert("not a policy handler");
        nayms.paySimplePremium(policyId1, 1000);

        vm.startPrank(signer2);

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

        simplePolicy.cancelled = true;
        updateSimplePolicy(policyId1, simplePolicy);
        vm.expectRevert("Policy is cancelled");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 1000);
        simplePolicy.fundsLocked = true;
        simplePolicy.cancelled = false;
        updateSimplePolicy(policyId1, simplePolicy);

        vm.prank(account9);
        vm.expectRevert("not a system manager");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 10000);
        vm.stopPrank();

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

        vm.expectRevert("must be tokenizable");
        nayms.startTokenSale(entityId1, sellAmount, sellAtPrice);

        nayms.enableEntityTokenization(entityId1, "e1token", "e1token");

        vm.prank(account9);
        vm.expectRevert("not a system manager");
        nayms.startTokenSale(entityId1, sellAmount, sellAtPrice);
        vm.stopPrank();

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
        uint256 expectedutilizedCapacity = utilizedCapacityBefore - (simplePolicy.limit * entityAfter2.collateralRatio) / LibConstants.BP_FACTOR;
        assertEq(expectedutilizedCapacity, entityAfter2.utilizedCapacity, "utilized capacity should increase");
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

        nayms.diamondCut(cut, address(0), "");

        getReadyToCreatePolicies();

        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        uint256 premiumPaid = 10_000;
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(libFeeRouterFixture.payPremiumCommissions.selector, policyId1, premiumPaid));
        (success, result) = address(nayms).call(abi.encodeWithSelector(libFeeRouterFixture.getPremiumCommissionBasisPointsFixture.selector));

        uint256 commissionNaymsLtd = (premiumPaid * nayms.getPremiumCommissionBasisPoints().premiumCommissionNaymsLtdBP) / LibConstants.BP_FACTOR;
        uint256 commissionNDF = (premiumPaid * nayms.getPremiumCommissionBasisPoints().premiumCommissionNDFBP) / LibConstants.BP_FACTOR;
        uint256 commissionSTM = (premiumPaid * nayms.getPremiumCommissionBasisPoints().premiumCommissionSTMBP) / LibConstants.BP_FACTOR;

        SimplePolicy memory sp = getSimplePolicy(policyId1);
        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), sp.asset), commissionNaymsLtd);
        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), sp.asset), commissionNDF);
        assertEq(nayms.internalBalanceOf(LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), sp.asset), commissionSTM);
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

        SimplePolicyInfo memory simplePolicyInfo = nayms.getSimplePolicyInfo(policyId1);
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
