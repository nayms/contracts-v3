// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Vm } from "forge-std/Vm.sol";

import { c, D03ProtocolDefaults, LibHelpers, LC } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, MarketInfo, SimplePolicy, SimplePolicyInfo, Stakeholders } from "src/shared/FreeStructs.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

import { LibEntity } from "src/libs/LibEntity.sol";
import { SimplePolicyFixture } from "test/fixtures/SimplePolicyFixture.sol";

// solhint-disable no-global-import
import "../src/shared/CustomErrors.sol";

import { StdStyle } from "forge-std/StdStyle.sol";

// solhint-disable no-console
contract T04EntityTest is D03ProtocolDefaults {
    using LibHelpers for *;
    using StdStyle for *;

    bytes32 internal entityId1 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(bytes32(0xe10d947335abff84f4d0ebc75f32f3a549614348ab29e220c4b20b0acbd1fa38)));
    bytes32 internal policyId1 = makeId(LC.OBJECT_TYPE_POLICY, bytes20(bytes32(0x1ea6c707069e49cdc3a4ad357dbe9f52e3a3679636e37698a9ca254b9cb33869)));
    bytes32 public testPolicyDataHash = 0x00a420601de63bf726c0be38414e9255d301d74ad0d820d633f3ab75effd6f5b;
    bytes32 public policyHashedTypedData;

    SimplePolicyFixture internal simplePolicyFixture;

    Stakeholders internal stakeholders;
    SimplePolicy internal simplePolicy;

    address internal account9;
    bytes32 internal account9Id;

    function setUp() public {
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

        changePrank(sm.addr);
    }

    function getSimplePolicy(bytes32 _policyId) internal returns (SimplePolicy memory) {
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(simplePolicyFixture.getFullInfo.selector, _policyId));
        require(success, "Should get simple policy from app storage");
        return abi.decode(result, (SimplePolicy));
    }

    function updateSimplePolicy(bytes32 _policyId, SimplePolicy memory _simplePolicy) internal {
        (bool success, ) = address(nayms).call(abi.encodeWithSelector(simplePolicyFixture.update.selector, _policyId, _simplePolicy));
        require(success, "Should update simple policy in app storage");
    }

    function getReadyToCreatePolicies() public {
        // create entity
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5_000, 30_000, true), "test entity");

        // assign entity admin
        assertTrue(nayms.isInGroup(account0Id, entityId1, LC.GROUP_ENTITY_ADMINS));

        // fund the entity balance
        uint256 amount = 21000;
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, amount);
        assertEq(weth.balanceOf(account0), amount);
        nayms.externalDeposit(wethAddress, amount);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), amount);
        changePrank(su.addr);
    }

    function testObjectTokenSymbol() public {
        bytes32 objectId = createTestEntity(account0Id);
        string memory symbol = "ptEN1";
        string memory name = "Entity1 PToken";

        nayms.enableEntityTokenization(objectId, symbol, name, 1e6);
        assertEq(nayms.getObjectTokenSymbol(objectId), symbol);
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

    function testEntityTokenSymbolAndNameValidation() public {
        changePrank(sm.addr);
        bytes32 entityId = createTestEntity(account0Id);
        bytes32 entityId2 = createTestEntityWithId(account0Id, makeId(LC.OBJECT_TYPE_ENTITY, bytes20("0xe2")));
        bytes32 entityId3 = createTestEntityWithId(account0Id, makeId(LC.OBJECT_TYPE_ENTITY, bytes20("0xe3")));

        string memory symbol = "ptEN1";
        string memory name = "Entity1 PToken";
        vm.expectRevert(abi.encodeWithSelector(ObjectTokenSymbolInvalid.selector, entityId, ""));
        nayms.enableEntityTokenization(entityId, "", name, 1e6);

        vm.expectRevert(abi.encodeWithSelector(ObjectTokenSymbolInvalid.selector, entityId, "12345678901234567"));
        nayms.enableEntityTokenization(entityId, "12345678901234567", name, 1e6);

        vm.expectRevert(abi.encodeWithSelector(ObjectTokenNameInvalid.selector, entityId, "Entity1 Token Entity1 Token Entity1 Token Entity1 Token Entity1 To"));
        nayms.enableEntityTokenization(entityId, symbol, "Entity1 Token Entity1 Token Entity1 Token Entity1 Token Entity1 To", 1e6);

        vm.expectRevert(abi.encodeWithSelector(ObjectTokenNameInvalid.selector, entityId, ""));
        nayms.enableEntityTokenization(entityId, symbol, "", 1e6);

        nayms.enableEntityTokenization(entityId, symbol, name, 1e6);

        vm.expectRevert(abi.encodeWithSelector(ObjectTokenSymbolAlreadyInUse.selector, entityId2, symbol));
        nayms.enableEntityTokenization(entityId2, symbol, "Entity2 PToken", 1e6);

        vm.expectRevert(abi.encodeWithSelector(ObjectTokenSymbolAlreadyInUse.selector, entityId3, "WETH"));
        nayms.enableEntityTokenization(entityId3, "WETH", "Entity3 Token", 1e6);
    }

    function testEnableEntityTokenization() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 10000, false), "entity test hash");

        // Attempt to tokenize an entity when the entity does not exist. Should throw an error.
        bytes32 nonExistentEntity = bytes32("ffffaaa");
        vm.expectRevert(abi.encodePacked(EntityDoesNotExist.selector, (nonExistentEntity)));
        nayms.enableEntityTokenization(nonExistentEntity, "123456789012345", "1234567890123456", 1e6);

        changePrank(signer1);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, signer1Id, systemContext, "", LC.GROUP_SYSTEM_MANAGERS));
        nayms.enableEntityTokenization(entityId1, "123456789012345", "1234567890123456", 1e6);
        changePrank(sm.addr);

        nayms.enableEntityTokenization(entityId1, "123456789012345", "1234567890123456", 1e6);

        vm.expectRevert("object already tokenized");
        nayms.enableEntityTokenization(entityId1, "123456789012346", "12345678901234567", 1e6);
    }

    function testUpdateEntityTokenInfo() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 10000, false), "entity test hash");
        nayms.enableEntityTokenization(entityId1, "TT", "Test Token", 1e6);

        string memory newTokenSymbol = "nTT";
        string memory newTokenName = "New Test Token";

        changePrank(signer1);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, signer1Id, systemContext, "", LC.GROUP_SYSTEM_MANAGERS));
        nayms.updateEntityTokenInfo(entityId1, newTokenSymbol, newTokenName);
        changePrank(sm.addr);

        vm.recordLogs();
        nayms.updateEntityTokenInfo(entityId1, newTokenSymbol, newTokenName);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "TokenInfoUpdated: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("TokenInfoUpdated(bytes32,string,string)"), "TokenInfoUpdated: Invalid event signature");
        assertEq(entries[0].topics[1], entityId1, "TokenInfoUpdated: incorrect entityID");
        (string memory eventTokenSymbol, string memory eventTokenName) = abi.decode(entries[0].data, (string, string));
        assertEq(newTokenSymbol, eventTokenSymbol, "TokenInfoUpdated: invalid token symbol");
        assertEq(newTokenName, eventTokenName, "TokenInfoUpdated: invalid token name");
    }

    function testUpdateEntity() public {
        vm.expectRevert(abi.encodePacked(EntityDoesNotExist.selector, (entityId1)));
        nayms.updateEntity(entityId1, initEntity(wethId, 10_000, 0, false));

        c.logBytes32(wethId);
        nayms.createEntity(entityId1, account0Id, initEntity(0, 0, 0, false), testPolicyDataHash);
        c.log(" >>> CREATED");

        changePrank(systemAdmin);
        nayms.addSupportedExternalToken(address(wbtc), 1);
        changePrank(sm.addr);
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
        nayms.updateEntity(entityId1, initEntity(wbtcId, 0, LC.BP_FACTOR, false));

        vm.expectRevert("collateral ratio should be 1 to 10000");
        nayms.updateEntity(entityId1, initEntity(wethId, 10001, LC.BP_FACTOR, false));

        vm.expectRevert("max capacity should be greater than 0 for policy creation");
        nayms.updateEntity(entityId1, initEntity(wethId, LC.BP_FACTOR, 0, true));

        vm.recordLogs();
        nayms.updateEntity(entityId1, initEntity(wethId, LC.BP_FACTOR, LC.BP_FACTOR, false));
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[1].topics.length, 2, "Invalid event count");
        assertEq(entries[1].topics[0], keccak256("EntityUpdated(bytes32)"));
        assertEq(entries[1].topics[1], entityId1, "EntityUpdated: incorrect entity"); // assert entity
    }

    function testUpdateCellCollateralRatio() public {
        changePrank(sm.addr);
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5_000, 30_000, true), "test entity");
        changePrank(systemAdmin);
        nayms.assignRole(account0Id, entityId1, LC.ROLE_ENTITY_ADMIN);

        // fund the entity balance
        uint256 amount = 5_000;
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, amount);
        nayms.externalDeposit(wethAddress, amount);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), amount);

        assertEq(nayms.getLockedBalance(entityId1, wethId), 0, "NO FUNDS should be locked");

        changePrank(su.addr);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        uint256 expectedLockedBalance = (simplePolicy.limit * 5_000) / LC.BP_FACTOR;
        assertEq(nayms.getLockedBalance(entityId1, wethId), expectedLockedBalance, "funds SHOULD BE locked");

        Entity memory entity1 = nayms.getEntityInfo(entityId1);
        assertEq(entity1.utilizedCapacity, (simplePolicy.limit * 5_000) / LC.BP_FACTOR, "utilized capacity should increase");

        changePrank(sm.addr);
        entity1.collateralRatio = 7_000;
        vm.expectRevert("collateral ratio invalid, not enough balance");
        nayms.updateEntity(entityId1, entity1);

        vm.recordLogs();

        entity1.collateralRatio = 4_000;
        nayms.updateEntity(entityId1, entity1);
        assertEq(nayms.getLockedBalance(entityId1, wethId), (simplePolicy.limit * 4_000) / LC.BP_FACTOR, "locked balance SHOULD decrease");

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "CollateralRatioUpdated: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("CollateralRatioUpdated(bytes32,uint256,uint256)"), "CollateralRatioUpdated: Invalid event signature");
        assertEq(entries[0].topics[1], entityId1, "CollateralRatioUpdated: incorrect entityID");
        (uint256 newCollateralRatio, uint256 newUtilisedCapacity) = abi.decode(entries[0].data, (uint256, uint256));
        assertEq(newCollateralRatio, 4_000, "CollateralRatioUpdated: invalid collateral ratio");
        assertEq(newUtilisedCapacity, (simplePolicy.limit * 4_000) / LC.BP_FACTOR, "CollateralRatioUpdated: invalid utilised capacity");

        Entity memory entity1AfterUpdate = nayms.getEntityInfo(entityId1);
        assertEq(entity1AfterUpdate.utilizedCapacity, (simplePolicy.limit * 4_000) / LC.BP_FACTOR, "utilized capacity should increase");

        changePrank(su.addr);
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
            collateralRatio: LC.BP_FACTOR,
            maxCapacity: 100 ether,
            utilizedCapacity: 0,
            simplePolicyEnabled: true
        });

        bytes32 eAlice = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("ealice"));
        bytes32 eBob = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("ebob"));
        nayms.createEntity(eAlice, aliceId, entity, "entity test hash");
        nayms.createEntity(eBob, bobId, entity, "entity test hash");

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        nayms.externalDeposit(wethAddress, 100000);

        bytes32 signingHash = nayms.getSigningHash(simplePolicy.startDate, simplePolicy.maturationDate, simplePolicy.asset, simplePolicy.limit, testPolicyDataHash);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = signWithPK(0xACC1, signingHash); // 0x2337f702bc9A7D1f415050365634FEbEdf4054Be
        signatures[1] = signWithPK(0xACC2, signingHash); // 0x167D6b35e51df22f42c4F42f26d365756D244fDE
        signatures[2] = signWithPK(0xACC3, signingHash); // 0x167D6b35e51df22f42c4F42f26d365756D244fDE

        bytes32[] memory roles = new bytes32[](3);
        roles[0] = LibHelpers._stringToBytes32(LC.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LC.ROLE_BROKER);
        roles[2] = LibHelpers._stringToBytes32(LC.ROLE_CAPITAL_PROVIDER);

        bytes32[] memory entityIds = new bytes32[](3);
        entityIds[0] = eAlice;
        entityIds[1] = eBob;
        entityIds[2] = "eEve";

        Stakeholders memory stakeholders2 = Stakeholders(roles, entityIds, signatures);

        changePrank(su.addr);
        vm.expectRevert(abi.encodeWithSelector(DuplicateSignerCreatingSimplePolicy.selector, alice, bob));
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders2, simplePolicy, testPolicyDataHash);
    }

    function testSignatureWhenCreatingSimplePolicy() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5000, 10000, true), "entity test hash");

        bytes32 bobId = LibHelpers._getIdForAddress(vm.addr(0xACC1));
        bytes32 aliceId = LibHelpers._getIdForAddress(vm.addr(0xACC2));
        bytes32 eveId = LibHelpers._getIdForAddress(vm.addr(0xACC3));

        Entity memory entity = Entity({
            assetId: LibHelpers._getIdForAddress(wethAddress),
            collateralRatio: LC.BP_FACTOR,
            maxCapacity: 100 ether,
            utilizedCapacity: 0,
            simplePolicyEnabled: true
        });

        bytes32 eAlice = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("eAlice"));
        bytes32 eBob = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("eBob"));
        bytes32 eEve = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("eEve"));
        nayms.createEntity(eAlice, aliceId, entity, "entity test hash");
        nayms.createEntity(eBob, bobId, entity, "entity test hash");
        nayms.createEntity(eEve, eveId, entity, "entity test hash");

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        nayms.externalDeposit(wethAddress, 100000);

        bytes32 signingHash = nayms.getSigningHash(simplePolicy.startDate, simplePolicy.maturationDate, simplePolicy.asset, simplePolicy.limit, testPolicyDataHash);

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = signWithPK(0xACC2, signingHash);
        signatures[1] = signWithPK(0xACC1, signingHash);
        signatures[2] = signWithPK(0xACC3, signingHash);

        bytes32[] memory roles = new bytes32[](3);
        roles[0] = LibHelpers._stringToBytes32(LC.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LC.ROLE_BROKER);
        roles[2] = LibHelpers._stringToBytes32(LC.ROLE_CAPITAL_PROVIDER);

        bytes32[] memory entityIds = new bytes32[](3);
        entityIds[0] = eAlice;
        entityIds[1] = eBob;
        entityIds[2] = eEve;

        Stakeholders memory stakeholders2 = Stakeholders(roles, entityIds, signatures);

        changePrank(su.addr);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders2, simplePolicy, testPolicyDataHash);
    }

    function testCreateSimplePolicyValidation() public {
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, LC.BP_FACTOR, LC.BP_FACTOR, false), "entity test hash");

        vm.startPrank(su.addr);
        vm.expectRevert("simple policy creation disabled");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        vm.stopPrank();

        // enable simple policy creation
        vm.startPrank(sm.addr);
        nayms.updateEntity(entityId1, initEntity(wethId, LC.BP_FACTOR, LC.BP_FACTOR, true));
        vm.stopPrank();

        vm.startPrank(su.addr);
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

        stakeholders.signatures[0] = signWithPK(0xACC2, signingHash);
        stakeholders.signatures[1] = signWithPK(0xACC1, signingHash);
        stakeholders.signatures[2] = signWithPK(0xACC3, signingHash);
        stakeholders.signatures[3] = signWithPK(0xACC4, signingHash);

        // external token not supported
        vm.expectRevert("external token is not supported");
        simplePolicy.asset = LibHelpers._getIdForAddress(wbtcAddress);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        vm.stopPrank();

        vm.startPrank(sa.addr);
        nayms.addSupportedExternalToken(wbtcAddress, 1e13);
        simplePolicy.asset = wbtcId;
        vm.startPrank(su.addr);
        vm.expectRevert("asset not matching with entity");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.asset = wethId;

        // test caller is not system underwriter
        vm.startPrank(account9);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, account9._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_UNDERWRITERS));
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        vm.startPrank(su.addr);
        // test capacity
        vm.expectRevert("not enough available capacity");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        vm.startPrank(sm.addr);
        // update max capacity
        nayms.updateEntity(entityId1, initEntity(wethId, 5000, 300000, true));
        vm.startPrank(su.addr);
        // test collateral ratio constraint
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        vm.startPrank(sm.addr);
        // fund the policy sponsor entity
        nayms.updateEntity(entityId1, initEntity(wethId, 5000, 300000, true));
        vm.startPrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 100000);
        assertEq(weth.balanceOf(account0), 100000);
        nayms.externalDeposit(wethAddress, 100000);
        assertEq(nayms.internalBalanceOf(entityId1, wethId), 100000);

        vm.startPrank(su.addr);

        // start date too early
        uint256 blockTimestampBeforeWarp;
        if (block.timestamp == 0) {
            vm.warp(1);
        } else {
            blockTimestampBeforeWarp = block.timestamp;
        }
        simplePolicy.startDate = block.timestamp - 1;
        vm.expectRevert("start date < block.timestamp");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.startDate = blockTimestampBeforeWarp + 1000;

        // start date after maturation date
        simplePolicy.startDate = simplePolicy.maturationDate;
        vm.expectRevert("start date > maturation date");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.startDate = blockTimestampBeforeWarp + 1000;

        vm.warp(blockTimestampBeforeWarp);

        uint256 maturationDateOrig = simplePolicy.maturationDate;
        simplePolicy.maturationDate = simplePolicy.startDate + 1;
        vm.expectRevert("policy period must be more than a day");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        simplePolicy.maturationDate = maturationDateOrig;

        // fee schedule receivers
        // change fee schedule to one that does not have any receivers
        // bytes32[] memory r;
        // uint16[] memory bp;

        // note: this test is not possible anymore because the fee schedule cannot be reset to be empty
        // vm.startPrank(systemAdmin);
        // nayms.addFeeSchedule(LC.DEFAULT_FEE_SCHEDULE, LC.FEE_TYPE_PREMIUM, r, bp);
        // vm.startPrank(su.addr);
        // vm.expectRevert("must have fee schedule receivers");
        // nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // // add back fee receiver
        // r = b32Array1(NAYMS_LTD_IDENTIFIER);
        // bp = u16Array1(300);
        // vm.startPrank(systemAdmin);
        // nayms.addFeeSchedule(LC.DEFAULT_FEE_SCHEDULE, LC.FEE_TYPE_PREMIUM, r, bp);

        vm.startPrank(su.addr);
        vm.expectRevert("number of commissions don't match");
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

        // commission basis points total > half of bp factor
        vm.expectRevert();
        simplePolicy.commissionReceivers = new bytes32[](1);
        simplePolicy.commissionReceivers.push(keccak256("a"));
        simplePolicy.commissionBasisPoints = new uint256[](1);
        simplePolicy.commissionBasisPoints.push(LC.BP_FACTOR / 2 + 1);
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

        nayms.cancelSimplePolicy(policyId1);

        bytes32[] memory roles = new bytes32[](2);
        roles[0] = LibHelpers._stringToBytes32(LC.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LC.ROLE_BROKER);

        stakeholders.roles = roles;
        vm.expectRevert("too many commission receivers");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
    }

    function testCreateSimplePolicyAlreadyExists() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        vm.expectRevert(abi.encodeWithSelector(ObjectExistsAlready.selector, policyId1));
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
    }

    function testCreateSimplePolicyUpdatesEntityUtilizedCapacity() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // check utilized capacity of entity
        Entity memory e = nayms.getEntityInfo(entityId1);
        assertEq(e.utilizedCapacity, (10_000 * e.collateralRatio) / LC.BP_FACTOR, "utilized capacity");

        bytes32 policyId2 = makeId(LC.OBJECT_TYPE_POLICY, bytes20("0xC0FFEF"));
        (Stakeholders memory stakeholders2, SimplePolicy memory policy2) = initPolicy(testPolicyDataHash);
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders2, policy2, testPolicyDataHash);

        e = nayms.getEntityInfo(entityId1);
        assertEq(e.utilizedCapacity, (20_000 * e.collateralRatio) / LC.BP_FACTOR, "utilized capacity");
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

            changePrank(sm.addr);
            // change parent
            nayms.setEntity(signerId, entityId1);
            changePrank(su.addr);
            // try creating
            vm.expectRevert();
            nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

            changePrank(sm.addr);
            nayms.setEntity(signerId, stakeholders.entityIds[i]);
        }
    }

    function testCreateSimplePolicyEntitiesAreAssignedRolesOnPolicy() public {
        getReadyToCreatePolicies();

        string[] memory groups = new string[](4);
        groups[0] = LC.GROUP_UNDERWRITERS;
        groups[1] = LC.GROUP_BROKERS;
        groups[2] = LC.GROUP_CAPITAL_PROVIDERS;
        groups[3] = LC.GROUP_INSURED_PARTIES;

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
        // events: 1 object creation, 4 role assignments + 1 policy creation => we want event at index 5
        assertEq(entries[5].topics.length, 2);
        assertEq(entries[5].topics[0], keccak256("SimplePolicyCreated(bytes32,bytes32)"));
        assertEq(entries[5].topics[1], policyId1);
        bytes32 entityId = abi.decode(entries[5].data, (bytes32));
        assertEq(entityId, entityId1);
    }

    function testSimplePolicyEntityCapitalUtilization100CR() public {
        // create entity with 100% collateral ratio
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 10_000, 30_000, true), "test entity");

        changePrank(systemAdmin);
        // assign entity admin
        nayms.assignRole(account0Id, entityId1, LC.ROLE_ENTITY_ADMIN);

        // fund the entity balance
        uint256 amount = 21000;
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, amount);
        nayms.externalDeposit(wethAddress, amount);

        changePrank(su.addr);
        // create policyId1 with limit of 21000
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 21000);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 21000, "entity balance of nWETH");
        assertEq(nayms.getEntityInfo(entityId1).utilizedCapacity, 21000, "entity utilization should INCREASE when a policy is created");
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000, "entity locked balance should INCREASE when a policy is created");

        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(nayms.getEntity(account0Id), nayms.getEntity(account0Id), LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(account0);
        // note: entity with 100% CR should be able to pay the claim - claim amount comes from the locked balance (locked in the policy)
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 2);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 21000 - 2, "entity balance of nWETH should DECREASE by pay claim amount");
        assertEq(nayms.getEntityInfo(entityId1).utilizedCapacity, 21000 - 2, "entity utilization should DECREASE when a claim is made");
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 2, "entity locked balance should DECREASE");

        // increase max cap from 30_000 to 221_000
        Entity memory newEInfo = nayms.getEntityInfo(entityId1);
        newEInfo.maxCapacity = 221_000;
        changePrank(sm.addr);
        nayms.updateEntity(entityId1, newEInfo);

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 200_000);
        nayms.externalDeposit(wethAddress, 200_000);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 20998 + 200_000, "after deposit, entity balance of nWETH should INCREASE");

        changePrank(su.addr);
        bytes32 policyId2 = makeId(LC.OBJECT_TYPE_POLICY, bytes20("policyId2"));

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 200_001);
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 200_000);
        // note: brings us to 100% max capacity
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 2 + 200_000, "locked balance should INCREASE");

        changePrank(account0);
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId2")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId3")), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        changePrank(su.addr);
        nayms.cancelSimplePolicy(policyId1);

        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 200_000 - 3, "after cancelling policy, the locked balance should DECREASE");

        changePrank(account0);
        vm.expectRevert("_internalBurn: insufficient balance available, funds locked");
        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 21_000);

        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 21_000 - 2 - 3);
    }

    function testSimplePolicyEntityCapitalUtilization50CR() public {
        getReadyToCreatePolicies();
        vm.stopPrank();
        vm.startPrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        vm.stopPrank();

        vm.startPrank(em.addr);
        nayms.assignRole(nayms.getEntity(account0Id), nayms.getEntity(account0Id), LC.ROLE_ENTITY_COMPTROLLER_COMBINED);
        vm.stopPrank();

        vm.startPrank(su.addr);
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 42002);
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // create policyId1 with limit of 42000
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 42000);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000, "locked balance should INCREASE");
        vm.stopPrank();

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 2);

        writeTokenBalance(account0, naymsAddress, wethAddress, 1);
        nayms.externalDeposit(wethAddress, 1);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 21001, "entity balance of nWETH should INCREASE by deposit amount");

        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 2); // claiming 2
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 20999, "entity balance of nWETH should DECREASE by pay claim amount");
        assertEq(nayms.getEntityInfo(entityId1).utilizedCapacity, 21000 - 1, "entity utilization should DECREASE when a claim is made");
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 1, "entity locked balance should DECREASE");

        writeTokenBalance(account0, naymsAddress, wethAddress, 200_000);
        nayms.externalDeposit(wethAddress, 200_000);
        assertEq(nayms.internalBalanceOf(entityId1, simplePolicy.asset), 20999 + 200_000, "after deposit, entity balance of nWETH should INCREASE");

        // increase max cap from 30_000 to 221_000
        Entity memory newEInfo = nayms.getEntityInfo(entityId1);
        newEInfo.maxCapacity = 221_000;
        vm.startPrank(sm.addr);
        nayms.updateEntity(entityId1, newEInfo);
        vm.stopPrank();

        bytes32 policyId2 = makeId(LC.OBJECT_TYPE_POLICY, bytes20("policyId2"));

        vm.startPrank(su.addr);
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 400_003);
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 400_000);
        // note: brings us to 100% max capacity
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 1 + 200_000, "locked balance should INCREASE");
        vm.stopPrank();

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId2")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId2")), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        vm.startPrank(su.addr);
        nayms.cancelSimplePolicy(policyId1);
        vm.stopPrank();

        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000 - 1 + 200_000 - 20999, "after cancelling policy, the locked balance should DECREASE");

        vm.expectRevert("_internalBurn: insufficient balance available, funds locked");
        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 21_000);
        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 21_000 - 1);

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId2")), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 1);

        writeTokenBalance(account0, naymsAddress, wethAddress, 1);
        nayms.externalDeposit(wethAddress, 1);

        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId2")), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 3);

        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId2")), policyId2, DEFAULT_INSURED_PARTY_ENTITY_ID, 1);
    }

    function testSimplePolicyLockedBalancesAfterPaySimpleClaim() public {
        getReadyToCreatePolicies();
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(nayms.getEntity(account0Id), nayms.getEntity(account0Id), LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(su.addr);
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 42002);
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        // create policyId1 with limit of 42000
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, 42000);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 21000, "locked balance should INCREASE");

        changePrank(account0);
        vm.expectRevert("_internalTransfer: insufficient balance available, funds locked");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 21000);

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, 20000);
        nayms.externalDeposit(wethAddress, 20000);

        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 21000);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 10500, "locked balance should DECREASE by half");

        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId1")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 1000);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 10000, "locked balance should DECREASE");

        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId2")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 1000);
        assertEq(nayms.getLockedBalance(entityId1, simplePolicy.asset), 9500, "locked balance should DECREASE");

        // note: entity now has balance of 18000, locked balance of 9500
        // attempting to pay a claim that's above the entity's balance, below the policy limit triggers the following error
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, wethId, entityId1, 18000, 19000));
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId3")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 19000);
    }

    function testSimplePolicyPremiumsCommissionsClaims() public {
        getReadyToCreatePolicies();
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(nayms.getEntity(account0Id), nayms.getEntity(account0Id), LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(su.addr);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        changePrank(account0);
        vm.expectRevert(); // u
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
                uint256 commission = (premiumAmount * simplePolicy.commissionBasisPoints[i]) / LC.BP_FACTOR;
                netPremiumAmount -= commission;
                assertEq(nayms.internalBalanceOf(simplePolicy.commissionReceivers[i], simplePolicy.asset), commission);
            }
            simplePolicy = getSimplePolicy(policyId1);
            assertEq(simplePolicy.premiumsPaid, premiumAmount);
            assertEq(nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, wethId), balanceBeforePremium - premiumAmount);
        }

        vm.startPrank(account0);

        simplePolicy.cancelled = true;
        updateSimplePolicy(policyId1, simplePolicy);
        vm.expectRevert("Policy is cancelled");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 1000);
        simplePolicy.fundsLocked = true;
        simplePolicy.cancelled = false;
        updateSimplePolicy(policyId1, simplePolicy);

        changePrank(account9);
        vm.expectRevert();
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 10000);

        vm.expectRevert(); // does not have comptroller combined | comptroller cliam role
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, 0, 10000);

        changePrank(account0);

        vm.expectRevert("invalid claim amount");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 0);

        changePrank(account0);

        vm.expectRevert("exceeds policy limit");
        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 100001);

        uint256 claimAmount = 10000;
        uint256 balanceBeforeClaim = nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, simplePolicy.asset);
        simplePolicy = getSimplePolicy(policyId1);
        assertEq(simplePolicy.claimsPaid, 0);

        nayms.paySimpleClaim(makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId")), policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, claimAmount);

        simplePolicy = getSimplePolicy(policyId1);
        assertEq(simplePolicy.claimsPaid, 10000);

        assertEq(nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, simplePolicy.asset), balanceBeforeClaim + claimAmount);
    }

    function testTokenSale() public {
        uint256 sellAmount = 1000;
        uint256 sellAtPrice = 1000;

        Entity memory entity1 = initEntity(wethId, 5000, 10000, false);
        nayms.createEntity(entityId1, account0Id, entity1, "entity test hash");

        vm.expectRevert(abi.encodeWithSelector(ObjectCannotBeTokenized.selector, entityId1));
        nayms.startTokenSale(entityId1, sellAmount, sellAtPrice);

        nayms.enableEntityTokenization(entityId1, "e1token", "e1token", 1e2);

        changePrank(account9);
        vm.expectRevert();
        nayms.startTokenSale(entityId1, sellAmount, sellAtPrice);
        vm.stopPrank();

        vm.startPrank(sm.addr);
        vm.expectRevert("mint amount must be > 0");
        nayms.startTokenSale(entityId1, 0, sellAtPrice);

        vm.expectRevert("total price must be > 0");
        nayms.startTokenSale(entityId1, sellAmount, 0);

        vm.expectRevert("total price must be greater than asset minimum sell amount");
        nayms.startTokenSale(entityId1, sellAmount, 1);

        uint256 lastOfferId = nayms.getLastOfferId();

        nayms.startTokenSale(entityId1, sellAmount, sellAtPrice);

        assertEq(lastOfferId, nayms.getLastOfferId() - 1);

        MarketInfo memory marketInfo = nayms.getOffer(lastOfferId + 1);
        assertEq(marketInfo.creator, entityId1);
        assertEq(marketInfo.sellToken, entityId1);
        assertEq(marketInfo.sellAmount, sellAmount);
        assertEq(marketInfo.buyToken, entity1.assetId);
        assertEq(marketInfo.buyAmount, sellAtPrice);
        assertEq(marketInfo.state, LC.OFFER_STATE_ACTIVE);
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
        uint256 expectedUtilizedCapacity = utilizedCapacityBefore - (simplePolicy.limit * entityAfter2.collateralRatio) / LC.BP_FACTOR;
        assertEq(expectedUtilizedCapacity, entityAfter2.utilizedCapacity, "utilized capacity should increase");
    }

    function testCancelSimplePolicy() public {
        getReadyToCreatePolicies();
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        Entity memory entityBefore = nayms.getEntityInfo(entityId1);
        uint256 utilizedCapacityBefore = entityBefore.utilizedCapacity;

        nayms.cancelSimplePolicy(policyId1);

        Entity memory entityAfter = nayms.getEntityInfo(entityId1);
        assertEq(utilizedCapacityBefore - ((simplePolicy.limit * entityAfter.collateralRatio) / LC.BP_FACTOR), entityAfter.utilizedCapacity, "utilized capacity should change");

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

    function testSimplePolicyDoubleUnlockFunds() public {
        getReadyToCreatePolicies();

        vm.stopPrank();
        vm.startPrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        vm.stopPrank();

        vm.startPrank(em.addr);
        nayms.assignRole(entityId1, entityId1, LC.ROLE_ENTITY_COMPTROLLER_COMBINED); // </3
        vm.stopPrank();

        uint256 limitAmount = 20000;

        vm.startPrank(su.addr);
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, limitAmount);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        uint256 lockedAmount = nayms.getLockedBalance(entityId1, wethId);

        bytes32 policyId2 = makeId(LC.OBJECT_TYPE_POLICY, bytes20("0xC0FFEF"));
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, limitAmount);
        nayms.createSimplePolicy(policyId2, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        lockedAmount = nayms.getLockedBalance(entityId1, wethId);

        vm.warp(block.timestamp + 3 days);
        nayms.checkAndUpdateSimplePolicyState(policyId1);

        lockedAmount = nayms.getLockedBalance(entityId1, wethId);

        vm.expectRevert(abi.encodeWithSelector(PolicyCannotCancelAfterMaturation.selector, policyId1));
        nayms.cancelSimplePolicy(policyId1);
    }

    function testPayClaimAfterMaturation_IM25127() public {
        getReadyToCreatePolicies();

        vm.stopPrank();
        vm.startPrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        vm.stopPrank();

        vm.startPrank(em.addr);
        nayms.assignRole(entityId1, entityId1, LC.ROLE_ENTITY_COMPTROLLER_COMBINED); // </3
        vm.stopPrank();

        uint256 limitAmount = 20000;

        vm.startPrank(su.addr);
        (stakeholders, simplePolicy) = initPolicyWithLimit(testPolicyDataHash, limitAmount);
        nayms.createSimplePolicy(policyId1, entityId1, stakeholders, simplePolicy, testPolicyDataHash);

        uint256 lockedAmount = nayms.getLockedBalance(entityId1, wethId);

        vm.warp(block.timestamp + 3 days);
        nayms.checkAndUpdateSimplePolicyState(policyId1);

        lockedAmount = nayms.getLockedBalance(entityId1, wethId);

        bytes32 claimId = makeId(LC.OBJECT_TYPE_CLAIM, bytes20("claimId"));

        vm.startPrank(account0);
        nayms.externalWithdrawFromEntity(entityId1, account0, wethAddress, 20000);
        c.log("balance of entity: ", nayms.internalBalanceOf(entityId1, wethId).green());

        uint256 lockedBalance = nayms.getLockedBalance(entityId1, wethId);
        uint256 utilizedCapacity = nayms.getEntityInfo(entityId1).utilizedCapacity;

        vm.expectRevert("not enough balance");
        nayms.paySimpleClaim(claimId, policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 2000);

        nayms.paySimpleClaim(claimId, policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 500);
        assertEq(lockedBalance, nayms.getLockedBalance(entityId1, wethId), "locked balance should not change");
        assertEq(utilizedCapacity, nayms.getEntityInfo(entityId1).utilizedCapacity, "utilized capacity should not change");
    }

    function testSelfOnboardingNotApproved() public {
        bytes32 roleId = LibHelpers._stringToBytes32(LC.ROLE_ENTITY_CP);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ONBOARDING_APPROVER);

        bytes32 entityId = randomEntityId(1);
        address userAddress = address(111);
        bytes memory noSig;

        vm.startPrank(userAddress);
        vm.expectRevert(abi.encodeWithSelector(EntityOnboardingNotApproved.selector, userAddress));
        nayms.onboardViaSignature(entityId, roleId, noSig);

        bytes memory sig = signWithPK(em.pk, nayms.getOnboardingHash(userAddress, entityId, roleId));

        vm.expectRevert(abi.encodeWithSelector(EntityOnboardingNotApproved.selector, userAddress));
        nayms.onboardViaSignature(0x0, roleId, sig);

        vm.expectRevert(abi.encodeWithSelector(EntityOnboardingNotApproved.selector, userAddress));
        nayms.onboardViaSignature(entityId, 0x0, sig);
        vm.stopPrank();

        vm.startPrank(sm.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_CP); // remove onboarding approver role
        vm.stopPrank();

        vm.startPrank(userAddress);
        vm.expectRevert(abi.encodeWithSelector(EntityOnboardingNotApproved.selector, userAddress));
        nayms.onboardViaSignature(entityId, roleId, sig);
    }

    function testSelfOnboardingInvalidGroup() public {
        bytes32 sysMgrRoleId = LibHelpers._stringToBytes32(LC.ROLE_SYSTEM_MANAGER);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ONBOARDING_APPROVER);

        bytes32 entityId = randomEntityId(1);
        address userAddress = address(111);

        bytes memory sig = signWithPK(em.pk, nayms.getOnboardingHash(userAddress, entityId, sysMgrRoleId));

        vm.startPrank(userAddress);
        vm.expectRevert(abi.encodeWithSelector(InvalidSelfOnboardRoleApproval.selector, sysMgrRoleId));
        nayms.onboardViaSignature(entityId, sysMgrRoleId, sig);
        vm.stopPrank();
    }

    function testSelfOnboardingSuccess() public {
        bytes32 roleId = LibHelpers._stringToBytes32(LC.ROLE_ENTITY_CP);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ONBOARDING_APPROVER);

        bytes32 entityId = randomEntityId(1);
        address userAddress = address(111);

        bytes memory sig = signWithPK(em.pk, nayms.getOnboardingHash(userAddress, entityId, roleId));

        vm.startPrank(userAddress);
        nayms.onboardViaSignature(entityId, roleId, sig);
        vm.stopPrank();

        assertEq(nayms.getEntity(LibHelpers._getIdForAddress(userAddress)), entityId, "parent should be set");

        assertTrue(nayms.isInGroup(entityId, systemContext, LC.GROUP_CAPITAL_PROVIDERS), "should belong capital providers group");
        assertTrue(nayms.isInGroup(entityId, entityId, LC.GROUP_CAPITAL_PROVIDERS), "should belong capital providers group");
    }

    function testSelfOnboardingUpgradeToCapitalProvider() public {
        nayms.assignRole(em.id, systemContext, LC.ROLE_ONBOARDING_APPROVER);

        address userAddress = address(111);
        bytes32 roleIdTokenHolder = LibHelpers._stringToBytes32(LC.ROLE_ENTITY_TOKEN_HOLDER);
        bytes32 roleIdCapitalProvider = LibHelpers._stringToBytes32(LC.ROLE_ENTITY_CP);

        bytes32 e1 = randomEntityId(1);

        bytes memory sigTokenHolder = signWithPK(em.pk, nayms.getOnboardingHash(userAddress, e1, roleIdTokenHolder));
        bytes memory sigCapitalProvider = signWithPK(em.pk, nayms.getOnboardingHash(userAddress, e1, roleIdCapitalProvider));

        vm.startPrank(userAddress);
        nayms.onboardViaSignature(e1, roleIdTokenHolder, sigTokenHolder);

        vm.recordLogs();

        nayms.onboardViaSignature(e1, roleIdCapitalProvider, sigCapitalProvider);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertRoleUpdateEvent(entries, 0, e1, e1, roleIdTokenHolder, "_unassignRole");
        assertRoleUpdateEvent(entries, 1, systemContext, e1, roleIdTokenHolder, "_unassignRole");
        assertRoleUpdateEvent(entries, 2, systemContext, e1, roleIdCapitalProvider, "_assignRole");
        assertRoleUpdateEvent(entries, 3, e1, e1, roleIdCapitalProvider, "_assignRole");
    }

    function test_selfOnboarding_InvalidEntityId() public {
        bytes32 roleId = LibHelpers._stringToBytes32(LC.ROLE_ENTITY_CP);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ONBOARDING_APPROVER);

        bytes32 entityId = keccak256("invalid entity id");
        address userAddress = address(111);

        bytes memory sig = signWithPK(em.pk, nayms.getOnboardingHash(userAddress, entityId, roleId));

        vm.startPrank(userAddress);
        vm.expectRevert(abi.encodeWithSelector(InvalidObjectType.selector, entityId, LC.OBJECT_TYPE_ENTITY));
        nayms.onboardViaSignature(entityId, roleId, sig);
        vm.stopPrank();
    }

    function randomEntityId(uint256 salt) public view returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, salt));
        return bytes32(abi.encodePacked(LC.OBJECT_TYPE_ENTITY, bytes20(hash)));
    }
}
