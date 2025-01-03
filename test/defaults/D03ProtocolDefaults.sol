// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Vm } from "forge-std/Vm.sol";

import { D02TestSetup, LibHelpers, c } from "./D02TestSetup.sol";
import { Entity, SimplePolicy, MarketInfo, Stakeholders, FeeSchedule } from "src/shared/FreeStructs.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { LibAdmin } from "src/libs/LibAdmin.sol";
import { LibConstants as LC } from "src/libs/LibConstants.sol";
import { StdStyle } from "forge-std/StdStyle.sol";

import { IERC20 } from "src/interfaces/IERC20.sol";

// solhint-disable no-console
// solhint-disable state-visibility
// solhint-disable max-states-count

/// @notice Default test setup part 03
///         Protocol / project level defaults
///         Setup internal token IDs, entities,
contract D03ProtocolDefaults is D02TestSetup {
    using LibHelpers for *;
    using StdStyle for *;

    bytes32 public immutable account0Id;
    bytes32 public naymsTokenId;

    bytes32 public immutable systemContext = LibAdmin._getSystemId();

    string[3] internal rolesThatCanAssignRoles = [LC.ROLE_SYSTEM_ADMIN, LC.ROLE_SYSTEM_MANAGER, LC.ROLE_ENTITY_MANAGER];
    mapping(string => string[]) internal roleCanAssignRoles;
    mapping(string => bytes32[]) internal roleToUsers;
    mapping(string => address[]) internal roleToUsersAddr;
    mapping(bytes32 => bytes32) internal objectToContext;

    mapping(string => string[]) internal functionToRoles;
    string[] internal functionsUsingAssertP = [
        LC.GROUP_START_TOKEN_SALE,
        LC.GROUP_EXECUTE_LIMIT_OFFER,
        LC.GROUP_CANCEL_OFFER,
        LC.GROUP_PAY_SIMPLE_PREMIUM,
        LC.GROUP_PAY_SIMPLE_CLAIM,
        LC.GROUP_PAY_DIVIDEND_FROM_ENTITY,
        LC.GROUP_EXTERNAL_DEPOSIT,
        LC.GROUP_EXTERNAL_WITHDRAW_FROM_ENTITY
    ];

    bytes32 public DEFAULT_ACCOUNT0_ENTITY_ID;
    bytes32 public DEFAULT_UNDERWRITER_ENTITY_ID = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("E2"));
    bytes32 public DEFAULT_BROKER_ENTITY_ID = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("E3"));
    bytes32 public DEFAULT_CAPITAL_PROVIDER_ENTITY_ID = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("E4"));
    bytes32 public DEFAULT_INSURED_PARTY_ENTITY_ID = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("E5"));

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
    bytes32 public immutable NAYMS_LTD_IDENTIFIER = LibHelpers._stringToBytes32(LC.NAYMS_LTD_IDENTIFIER);
    bytes32 public immutable NDF_IDENTIFIER = LibHelpers._stringToBytes32(LC.NDF_IDENTIFIER);
    bytes32 public immutable STM_IDENTIFIER = LibHelpers._stringToBytes32(LC.STM_IDENTIFIER);
    bytes32 public immutable SSF_IDENTIFIER = LibHelpers._stringToBytes32(LC.SSF_IDENTIFIER);

    bytes32 public immutable DIVIDEND_BANK_IDENTIFIER = LibHelpers._stringToBytes32(LC.DIVIDEND_BANK_IDENTIFIER);

    address public constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 public immutable USDC_IDENTIFIER = LibHelpers._getIdForAddress(USDC_ADDRESS);

    Entity entity;

    bytes32[] public defaultFeeRecipients;
    uint16[] public defaultPremiumFeeBPs;
    uint16[] public defaultTradingFeeBPs;
    uint16[] public defaultInitSaleFeeBPs;

    uint16 public defaultPremiumFee = 300;
    uint16 public defaultTradingFee = 30;
    uint16 public defaultInitSaleFee = 100;

    FeeSchedule premiumFeeScheduleDefault;
    FeeSchedule tradingFeeScheduleDefault;
    FeeSchedule initialSaleFeeScheduleDefault;

    NaymsAccount sa = makeNaymsAcc("System Admin");
    NaymsAccount sm = makeNaymsAcc("System Manager");
    NaymsAccount su = makeNaymsAcc("System Underwriter");

    NaymsAccount ea = makeNaymsAcc("Entity Admin");
    NaymsAccount em = makeNaymsAcc("Entity Manager");

    NaymsAccount ts = makeNaymsAcc("Tenant Sponsor");
    NaymsAccount tcp = makeNaymsAcc("Tenant CP");
    NaymsAccount ti = makeNaymsAcc("Tenant Insured");
    NaymsAccount tb = makeNaymsAcc("Tenant Broker");
    NaymsAccount tc = makeNaymsAcc("Tenant Consultant");

    NaymsAccount cc = makeNaymsAcc("Comptroller Combined");
    NaymsAccount cw = makeNaymsAcc("Comptroller Withdraw");
    NaymsAccount cClaim = makeNaymsAcc("Comptroller Claim");
    NaymsAccount cd = makeNaymsAcc("Comptroller Dividend");

    constructor() payable {
        c.log("\n -- D03 Protocol Defaults\n");
        c.log("Test contract address ID, aka account0Id:");

        account0Id = LibHelpers._getIdForAddress(account0);
        c.logBytes32(account0Id);

        naymsTokenId = LibHelpers._getIdForAddress(naymsAddress);
        c.log("Nayms Token ID:");
        c.logBytes32(naymsTokenId);

        vm.label(signer1, "Account 1 (Underwriter Rep)");
        vm.label(signer2, "Account 2 (Broker Rep)");
        vm.label(signer3, "Account 3 (Capital Provider Rep)");
        vm.label(signer4, "Account 4 (Insured Party Rep)");

        changePrank(systemAdmin);

        if (!nayms.isSupportedExternalToken(wethId)) nayms.addSupportedExternalToken(wethAddress, 1);
        try nayms.addSupportedExternalToken(usdcAddress, 1) {} catch {}

        entity = Entity({
            assetId: LibHelpers._getIdForAddress(wethAddress),
            collateralRatio: LC.BP_FACTOR,
            maxCapacity: 100 ether,
            utilizedCapacity: 0,
            simplePolicyEnabled: true
        });

        hAssignRole(sa.id, systemContext, LC.ROLE_SYSTEM_ADMIN);
        hAssignRole(sm.id, systemContext, LC.ROLE_SYSTEM_MANAGER);
        hAssignRole(su.id, systemContext, LC.ROLE_SYSTEM_UNDERWRITER);

        DEFAULT_ACCOUNT0_ENTITY_ID = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(account0));

        changePrank(sm.addr);
        nayms.createEntity(DEFAULT_ACCOUNT0_ENTITY_ID, account0Id, entity, "entity test hash");
        nayms.createEntity(DEFAULT_UNDERWRITER_ENTITY_ID, signer1Id, entity, "entity test hash");
        nayms.createEntity(DEFAULT_BROKER_ENTITY_ID, signer2Id, entity, "entity test hash");
        nayms.createEntity(DEFAULT_CAPITAL_PROVIDER_ENTITY_ID, signer3Id, entity, "entity test hash");
        nayms.createEntity(DEFAULT_INSURED_PARTY_ENTITY_ID, signer4Id, entity, "entity test hash");

        // Setup fee schedules
        defaultFeeRecipients = b32Array1(NAYMS_LTD_IDENTIFIER);
        defaultPremiumFeeBPs = u16Array1(defaultPremiumFee);
        defaultTradingFeeBPs = u16Array1(defaultTradingFee);
        defaultInitSaleFeeBPs = u16Array1(defaultInitSaleFee);

        premiumFeeScheduleDefault = feeSched1(NAYMS_LTD_IDENTIFIER, defaultPremiumFee);
        tradingFeeScheduleDefault = feeSched1(NAYMS_LTD_IDENTIFIER, defaultTradingFee);
        initialSaleFeeScheduleDefault = feeSched1(NAYMS_LTD_IDENTIFIER, defaultInitSaleFee);

        changePrank(sa.addr);

        // For Premiums
        nayms.addFeeSchedule(LC.DEFAULT_FEE_SCHEDULE, LC.FEE_TYPE_PREMIUM, defaultFeeRecipients, defaultPremiumFeeBPs);

        // For Marketplace
        nayms.addFeeSchedule(LC.DEFAULT_FEE_SCHEDULE, LC.FEE_TYPE_TRADING, defaultFeeRecipients, defaultTradingFeeBPs);
        nayms.addFeeSchedule(LC.DEFAULT_FEE_SCHEDULE, LC.FEE_TYPE_INITIAL_SALE, defaultFeeRecipients, defaultInitSaleFeeBPs);

        c.log("\n -- END TEST SETUP D03 Protocol Defaults --\n");
    }

    /// @dev Print roles
    function hRoles(address id) public view {
        hRoles(LibHelpers._getIdForAddress(id));
    }

    function hRoles(address id, bytes32 context) public view {
        hRoles(LibHelpers._getIdForAddress(id), context);
    }

    function hRoles(NaymsAccount memory id) public view {
        hRoles(id.id);
    }

    function hRoles(NaymsAccount memory id, bytes32 context) public view {
        hRoles(id.id, context);
    }

    function hRoles(bytes32 id, bytes32 context) public view {
        bytes32 parent = hRoles(id);
        c.log(string.concat("Parent role in given context ", hGetRoleInContext(parent, context).blue()));
        c.log(string.concat("User role in given context ", hGetRoleInContext(id, parent).blue()));
    }

    function hRoles(bytes32 id) public view returns (bytes32 parent) {
        parent = nayms.getEntity(id);
        c.log(string.concat("User ", vm.toString(id)));
        c.log(id._getAddressFromId());
        c.log(string.concat("Parent ", vm.toString(parent)));
        c.log(string.concat("Parent role in parent context ", hGetRoleInContext(parent, parent).blue()));
        c.log(string.concat("User role in parent context ", hGetRoleInContext(id, parent).blue()));
        c.log(string.concat("User role in system context ", hGetRoleInContext(id, systemContext).blue()));
        c.log(string.concat("Parent role in system context (not checked by assertPrivilege)", hGetRoleInContext(parent, systemContext).blue()));
    }

    function hAssignRole(bytes32 _objectId, bytes32 _contextId, string memory _role) internal {
        nayms.assignRole(_objectId, _contextId, _role);
        roleToUsers[_role].push(_objectId);
        roleToUsersAddr[_role].push(_objectId._getAddressFromId());
        if (objectToContext[_objectId] == systemContext) {
            c.log("warning: object's context is currently systemContext");
        } else {
            objectToContext[_objectId] = _contextId;
        }
    }

    function hUnassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        nayms.unassignRole(_objectId, _contextId);
    }

    function hCreateEntity(bytes32 _entityId, bytes32 _entityAdmin, Entity memory _entityData, bytes32 _dataHash) internal {
        nayms.createEntity(_entityId, _entityAdmin, _entityData, _dataHash);
        roleToUsers[LC.ROLE_ENTITY_ADMIN].push(_entityAdmin);

        if (objectToContext[_entityAdmin] == systemContext) {
            c.log("warning: object's context is currently systemContext");
        } else {
            objectToContext[_entityAdmin] = _entityId;
        }
    }

    /// @dev Create an entity for a NaymsAccount, and assign _entityId to NaymsAccount.entityId
    function hCreateEntity(bytes32 _entityId, NaymsAccount memory _entityAdmin, Entity memory _entityData, bytes32 _dataHash) internal {
        bytes32 previousParent = nayms.getEntity(_entityAdmin.id);
        nayms.createEntity(_entityId, _entityAdmin.id, _entityData, _dataHash);
        roleToUsers[LC.ROLE_ENTITY_ADMIN].push(_entityAdmin.id);

        if (objectToContext[_entityAdmin.id] == systemContext) {
            c.log("warning: object's context is currently systemContext");
        } else {
            objectToContext[_entityAdmin.id] = _entityId;
        }
        if (previousParent != 0) {
            c.log(string.concat("The entity admin's parent has been updated from ", vm.toString(previousParent), " to ", vm.toString(_entityId)));
        }
        _entityAdmin.entityId = _entityId;
    }

    function hCreateEntity(NaymsAccount memory _entityAdmin, Entity memory _entityData, bytes32 _dataHash) internal {
        bytes32 previousParent = nayms.getEntity(_entityAdmin.id);
        bytes32 entityId = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(_entityAdmin.addr));
        nayms.createEntity(entityId, _entityAdmin.id, _entityData, _dataHash);
        roleToUsers[LC.ROLE_ENTITY_ADMIN].push(_entityAdmin.id);

        if (objectToContext[_entityAdmin.id] == systemContext) {
            c.log("warning: object's context is currently systemContext");
        } else {
            objectToContext[_entityAdmin.id] = entityId;
        }
        if (previousParent != 0) {
            c.log(string.concat("The entity admin's parent has been updated from ", vm.toString(previousParent), " to ", vm.toString(entityId)));
        }
        _entityAdmin.entityId = entityId;
    }

    /// @dev Return the role as a decoded string
    function hGetRoleInContext(bytes32 objectId, bytes32 contextId) public view returns (string memory roleString) {
        roleString = string(nayms.getRoleInContext(objectId, contextId)._bytes32ToBytes());
    }

    /// @dev Set the parent of the user and also update NaymsAccount.entityId
    function hSetEntity(NaymsAccount memory acc, bytes32 entityId) public {
        nayms.setEntity(acc.id, entityId);
        acc.entityId = entityId;
    }

    function logOfferDetails(uint256 offerId) public view returns (MarketInfo memory m) {
        m = nayms.getOffer(offerId);
        string memory offerState;
        if (m.state == 1) offerState = "Active".green();
        if (m.state == 2) offerState = "Cancelled".red();
        if (m.state == 3) offerState = "Fulfilled".blue();

        string memory sellSymbol = vm.toString(m.sellToken);
        string memory buySymbol = vm.toString(m.buyToken);

        bool sellExternal = nayms.isSupportedExternalToken(m.sellToken);
        if (sellExternal) {
            sellSymbol = IERC20(LibHelpers._getAddressFromId(m.sellToken)).symbol();
            (, , buySymbol, , ) = nayms.getObjectMeta(m.buyToken);
        } else {
            (, , sellSymbol, , ) = nayms.getObjectMeta(m.sellToken);
            buySymbol = IERC20(LibHelpers._getAddressFromId(m.buyToken)).symbol();
        }

        c.log("");
        c.log(string.concat("--".green(), " ID: ", vm.toString(offerId), " (", offerState, ") ", "---------------------------------------------".green()));
        c.log(string.concat(" ", sellSymbol.red(), ":    ", vm.toString(m.sellAmount), " (", vm.toString(m.sellAmountInitial), ")"));
        c.log(string.concat(" ", buySymbol.green(), ":    ", vm.toString(m.buyAmount), " (", vm.toString(m.buyAmountInitial), ")"));

        // price is multiplied by 1000 to prevent rounding loss for small amounts in tests
        uint256 price;
        uint256 priceInitial;
        if (sellExternal) {
            price = m.buyAmount == 0 ? 0 : ((m.sellAmount * 1000) / m.buyAmount);
            priceInitial = m.buyAmountInitial == 0 ? 0 : ((m.sellAmountInitial * 1000) / m.buyAmountInitial);
        } else {
            price = m.sellAmount == 0 ? 0 : ((m.buyAmount * 1000) / m.sellAmount);
            priceInitial = m.sellAmountInitial == 0 ? 0 : ((m.buyAmountInitial * 1000) / m.sellAmountInitial);
        }

        c.log(
            string.concat(
                "-- ".green(),
                "Price: ",
                vm.toString(price).blue(),
                " (",
                vm.toString(priceInitial).blue(),
                ")",
                " ------------------------------------------------\n".green()
            )
        );
    }

    function b32Array1(bytes32 _value) internal pure returns (bytes32[] memory) {
        bytes32[] memory arr = new bytes32[](1);
        arr[0] = _value;
        return arr;
    }

    function b32Array3(bytes32 _value1, bytes32 _value2, bytes32 _value3) internal pure returns (bytes32[] memory) {
        bytes32[] memory arr_ = new bytes32[](3);
        arr_[0] = _value1;
        arr_[1] = _value2;
        arr_[2] = _value3;
        return arr_;
    }

    function u16Array1(uint16 _value) internal pure returns (uint16[] memory) {
        uint16[] memory arr = new uint16[](1);
        arr[0] = _value;
        return arr;
    }

    function u16Array3(uint16 _value1, uint16 _value2, uint16 _value3) internal pure returns (uint16[] memory) {
        uint16[] memory arr = new uint16[](3);
        arr[0] = _value1;
        arr[1] = _value2;
        arr[2] = _value3;
        return arr;
    }

    function u256Array1(uint256 _value) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](1);
        arr[0] = _value;
        return arr;
    }

    function u256Array3(uint256 _value1, uint256 _value2, uint256 _value3) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](3);
        arr[0] = _value1;
        arr[1] = _value2;
        arr[2] = _value3;
        return arr;
    }

    function feeSched1(bytes32 _receiver, uint16 _basisPoints) internal pure returns (FeeSchedule memory) {
        return FeeSchedule({ receiver: b32Array1(_receiver), basisPoints: u16Array1(_basisPoints) });
    }

    function feeSched(bytes32[] memory _receiver, uint16[] memory _basisPoints) internal pure returns (FeeSchedule memory) {
        return FeeSchedule({ receiver: _receiver, basisPoints: _basisPoints });
    }

    function createTestEntity(bytes32 adminId) internal returns (bytes32) {
        return createTestEntityWithId(adminId, makeId(LC.OBJECT_TYPE_ENTITY, bytes20("0xe1")));
    }

    function createTestEntityWithId(bytes32 adminId, bytes32 entityId) internal returns (bytes32) {
        Entity memory entity1 = initEntity(wethId, LC.BP_FACTOR / 2, LC.BP_FACTOR, false);
        nayms.createEntity(entityId, adminId, entity1, bytes32(0));
        return entityId;
    }

    function initEntity(bytes32 _assetId, uint256 _collateralRatio, uint256 _maxCapacity, bool _simplePolicyEnabled) public pure returns (Entity memory e) {
        e.assetId = _assetId;
        e.collateralRatio = _collateralRatio;
        e.maxCapacity = _maxCapacity;
        e.utilizedCapacity = 0;
        e.simplePolicyEnabled = _simplePolicyEnabled;
    }

    function initPolicy(bytes32 offchainDataHash) internal view returns (Stakeholders memory policyStakeholders, SimplePolicy memory policy) {
        return initPolicyWithLimit(offchainDataHash, LC.BP_FACTOR);
    }

    function initPolicyWithLimit(bytes32 offchainDataHash, uint256 limitAmount) internal view returns (Stakeholders memory policyStakeholders, SimplePolicy memory policy) {
        return initPolicyWithLimitAndAsset(offchainDataHash, limitAmount, wethId);
    }

    function initPolicyWithLimitAndAsset(
        bytes32 offchainDataHash,
        uint256 limitAmount,
        bytes32 assetId
    ) internal view returns (Stakeholders memory policyStakeholders, SimplePolicy memory policy) {
        bytes32[] memory roles = new bytes32[](4);
        roles[0] = LibHelpers._stringToBytes32(LC.ROLE_UNDERWRITER);
        roles[1] = LibHelpers._stringToBytes32(LC.ROLE_BROKER);
        roles[2] = LibHelpers._stringToBytes32(LC.ROLE_CAPITAL_PROVIDER);
        roles[3] = LibHelpers._stringToBytes32(LC.ROLE_INSURED_PARTY);

        bytes32[] memory entityIds = new bytes32[](4);
        entityIds[0] = DEFAULT_UNDERWRITER_ENTITY_ID;
        entityIds[1] = DEFAULT_BROKER_ENTITY_ID;
        entityIds[2] = DEFAULT_CAPITAL_PROVIDER_ENTITY_ID;
        entityIds[3] = DEFAULT_INSURED_PARTY_ENTITY_ID;

        {
            bytes32[] memory commissionReceivers = new bytes32[](3);
            commissionReceivers[0] = DEFAULT_UNDERWRITER_ENTITY_ID;
            commissionReceivers[1] = DEFAULT_BROKER_ENTITY_ID;
            commissionReceivers[2] = DEFAULT_CAPITAL_PROVIDER_ENTITY_ID;

            uint256[] memory commissions = new uint256[](3);
            commissions[0] = 10;
            commissions[1] = 10;
            commissions[2] = 10;

            policy.startDate = block.timestamp + 1000;
            policy.maturationDate = block.timestamp + 1000 + 2 days;
            policy.asset = assetId;
            policy.limit = limitAmount;
            policy.commissionReceivers = commissionReceivers;
            policy.commissionBasisPoints = commissions;
        }

        {
            bytes[] memory signatures = new bytes[](4);
            bytes32 signingHash = nayms.getSigningHash(policy.startDate, policy.maturationDate, policy.asset, policy.limit, offchainDataHash);

            signatures[0] = signWithPK(0xACC2, signingHash);
            signatures[1] = signWithPK(0xACC1, signingHash);
            signatures[2] = signWithPK(0xACC3, signingHash);
            signatures[3] = signWithPK(0xACC4, signingHash);

            policyStakeholders = Stakeholders(roles, entityIds, signatures);
        }
    }

    function signWithPK(uint256 privateKey, bytes32 signingHash) internal pure returns (bytes memory sig_) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, MessageHashUtils.toEthSignedMessageHash(signingHash));
        sig_ = abi.encodePacked(r, s, v);
    }

    function fundEntityWeth(NaymsAccount memory acc, uint256 amount) internal {
        deal(address(weth), acc.addr, amount);
        changePrank(acc.addr);
        weth.approve(address(nayms), amount);
        uint256 balanceBefore = nayms.internalBalanceOf(acc.entityId, wethId);
        nayms.externalDeposit(address(weth), amount);
        assertEq(nayms.internalBalanceOf(acc.entityId, wethId), balanceBefore + amount, "entity's weth balance is incorrect");
    }

    function fundEntityUsdc(NaymsAccount memory acc, uint256 amount) internal {
        deal(usdcAddress, acc.addr, amount);
        changePrank(acc.addr);
        usdc.approve(address(nayms), amount);
        uint256 balanceBefore = nayms.internalBalanceOf(acc.entityId, usdcId);
        nayms.externalDeposit(usdcAddress, amount);
        uint256 balanceAfter = nayms.internalBalanceOf(acc.entityId, usdcId);
        assertEq(balanceAfter, balanceBefore + amount, "entity's usdc balance is incorrect");
    }

    /// Pretty print ///
    function hCr(bytes32 objectId) public view {
        bytes32[] memory cr = nayms.getPolicyCommissionReceivers(objectId);
        c.log(string.concat(vm.toString(objectId), "'s commission receivers:").blue());
        for (uint256 i; i < cr.length; i++) {
            c.logBytes32(cr[i]);
        }
    }

    function assertRoleUpdateEvent(Vm.Log[] memory entries, uint256 _index, bytes32 _ctxId, bytes32 _entityId, bytes32 _roleId, string memory _action) internal {
        assertEq(entries[_index].topics.length, 2);
        assertEq(entries[_index].topics[0], keccak256("RoleUpdated(bytes32,bytes32,bytes32,string)"));
        assertEq(entries[_index].topics[1], _entityId, "incorrect entityID".red());

        (bytes32 contextId, bytes32 roleId, string memory action) = abi.decode(entries[_index].data, (bytes32, bytes32, string));
        assertEq(contextId, _ctxId, "incorrect context".red());
        assertEq(_roleId, roleId, "incorrect role ID".red());
        assertEq(action, _action, "incorrect action".red());
    }
}
