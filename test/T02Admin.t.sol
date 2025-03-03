// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { D03ProtocolDefaults, LibHelpers, LC } from "./defaults/D03ProtocolDefaults.sol";

import { Entity, Stakeholders, SimplePolicy, PermitSignature, OnboardingApproval } from "../src/shared/FreeStructs.sol";
import { MockAccounts } from "test/utils/users/MockAccounts.sol";
import { Vm } from "forge-std/Vm.sol";
import { IDiamondProxy } from "../src/generated/IDiamondProxy.sol";
import "../src/shared/CustomErrors.sol";
import { LibString } from "solady/utils/LibString.sol";

contract T02AdminTest is D03ProtocolDefaults, MockAccounts {
    using LibHelpers for *;
    using LibString for *;

    function setUp() public {}

    function testGetSystemId() public {
        assertEq(nayms.getSystemId(), LibHelpers._stringToBytes32(LC.SYSTEM_IDENTIFIER));
    }

    function testGetMaxDividendDenominationsDefaultValue() public {
        assertEq(nayms.getMaxDividendDenominations(), 1);
    }

    function testSetMaxDividendDenominationsFailIfNotAdmin() public {
        changePrank(account1);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, account1._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_ADMINS));
        nayms.setMaxDividendDenominations(100);
        vm.stopPrank();
    }

    function testSetMaxDividendDenominationsFailIfLowerThanBefore() public {
        nayms.setMaxDividendDenominations(2);

        vm.expectRevert("_updateMaxDividendDenominations: cannot reduce");
        nayms.setMaxDividendDenominations(2);

        nayms.setMaxDividendDenominations(3);
    }

    function testSetMaxDividendDenominations() public {
        uint256 orig = nayms.getMaxDividendDenominations();

        vm.recordLogs();

        nayms.setMaxDividendDenominations(100);
        assertEq(nayms.getMaxDividendDenominations(), 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("MaxDividendDenominationsUpdated(uint8,uint8)"));
        (uint8 oldV, uint8 newV) = abi.decode(entries[0].data, (uint8, uint8));
        assertEq(oldV, orig);
        assertEq(newV, 100);
    }

    function testAddSupportedExternalTokenFailIfNotAdmin() public {
        changePrank(account1);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, account1._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_ADMINS));
        nayms.addSupportedExternalToken(wethAddress, 1e13);
        vm.stopPrank();
    }

    function testAddSupportedExternalTokenFailIfTokenAddressHasNoCode() public {
        vm.expectRevert("LibERC20: ERC20 token address has no code");
        nayms.addSupportedExternalToken(address(0xdddddaaaaa), 1e13);
    }

    function testAddSupportedExternalToken() public {
        address[] memory orig = nayms.getSupportedExternalTokens();

        vm.recordLogs();

        nayms.addSupportedExternalToken(wbtcAddress, 1e13);
        address[] memory v = nayms.getSupportedExternalTokens();
        assertEq(v.length, orig.length + 1);
        assertEq(v[v.length - 1], wbtcAddress);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[1].topics.length, 2);
        assertEq(entries[1].topics[0], keccak256("SupportedTokenAdded(address)"), "SupportedTokenAdded: Invalid event signature");
        assertEq(abi.decode(LibHelpers._bytes32ToBytes(entries[1].topics[1]), (address)), wbtcAddress, "SupportedTokenAdded: Invalid token address");
    }

    function testIsSupportedToken() public {
        bytes32 id = LibHelpers._getIdForAddress(wbtcAddress);

        assertFalse(nayms.isSupportedExternalToken(id));

        nayms.addSupportedExternalToken(wbtcAddress, 1e13);

        assertTrue(nayms.isSupportedExternalToken(id));
    }

    function testSupportedTokenSymbolUnique() public {
        changePrank(sm.addr);
        bytes32 entityId = createTestEntity(account0Id);
        nayms.enableEntityTokenization(entityId, wbtc.symbol(), "Entity1 Token", 1e6);

        changePrank(sa.addr);
        vm.expectRevert(abi.encodeWithSelector(ObjectTokenSymbolAlreadyInUse.selector, LibHelpers._getIdForAddress(wbtcAddress), wbtc.symbol()));
        nayms.addSupportedExternalToken(wbtcAddress, 1e13);
    }

    function testAddSupportedExternalTokenIfAlreadyAdded() public {
        address[] memory orig = nayms.getSupportedExternalTokens();

        vm.recordLogs();

        nayms.addSupportedExternalToken(wbtcAddress, 1e13);

        address[] memory v = nayms.getSupportedExternalTokens();
        assertEq(v.length, orig.length + 1);
        assertEq(v[v.length - 1], wbtcAddress);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[1].topics.length, 2);
        assertEq(entries[1].topics[0], keccak256("SupportedTokenAdded(address)"));
        assertEq(abi.decode(LibHelpers._bytes32ToBytes(entries[1].topics[1]), (address)), wbtcAddress, "SupportedTokenAdded: Invalid token address");
    }

    function testAddSupportedExternalTokenIfWrapper() public {
        changePrank(sm.addr);
        bytes32 entityId1 = createTestEntity(account0Id);
        nayms.enableEntityTokenization(entityId1, "E1", "E1 Token", 1e6);
        nayms.startTokenSale(entityId1, 100 ether, 100 ether);

        vm.recordLogs();

        changePrank(sa.addr);
        nayms.wrapToken(entityId1);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "TokenWrapped: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("TokenWrapped(bytes32,address)"), "TokenWrapped: Invalid event signature");
        assertEq(entries[0].topics[1], entityId1, "TokenWrapped: incorrect tokenID"); // assert entity token
        address loggedWrapperAddress = abi.decode(entries[0].data, (address));

        vm.expectRevert("cannot add participation token wrapper as external");
        nayms.addSupportedExternalToken(loggedWrapperAddress, 1e13);
    }

    function testOnlySystemAdminCanCallLockAndUnlockFunction(address userAddress) public {
        bytes32 userId = LibHelpers._getIdForAddress(userAddress);
        changePrank(userAddress);
        if (nayms.isInGroup(userId, systemContext, LC.GROUP_SYSTEM_ADMINS)) {
            nayms.lockFunction(bytes4(0x12345678));

            assertTrue(nayms.isFunctionLocked(bytes4(0x12345678)));

            nayms.unlockFunction(bytes4(0x12345678));
            assertFalse(nayms.isFunctionLocked(bytes4(0x12345678)));
        } else {
            string memory curentRole = nayms.getRoleInContext(userId, systemContext).fromSmallString();

            vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, userId, systemContext, curentRole, LC.GROUP_SYSTEM_ADMINS));
            nayms.lockFunction(bytes4(0x12345678));

            vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, userId, systemContext, curentRole, LC.GROUP_SYSTEM_ADMINS));
            nayms.unlockFunction(bytes4(0x12345678));
        }
    }

    function testLockFunction() public {
        // must be sys admin
        changePrank(account9);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, account9._getIdForAddress(), systemContext, "", LC.GROUP_SYSTEM_ADMINS));

        nayms.lockFunction(bytes4(0x12345678));

        changePrank(systemAdmin);

        vm.recordLogs();
        // assert happy path
        nayms.lockFunction(bytes4(0x12345678));

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("FunctionsLocked(bytes4[])"));
        (s_functionSelectors) = abi.decode(entries[0].data, (bytes4[]));

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = bytes4(0x12345678);

        assertEq(s_functionSelectors[0], functionSelectors[0]);

        assertTrue(nayms.isFunctionLocked(bytes4(0x12345678)));
    }

    function testLockFunctionExternalWithdrawFromEntity() public {
        bytes32 wethId = LibHelpers._getIdForAddress(wethAddress);

        changePrank(sm.addr);
        bytes32 systemAdminEntityId = createTestEntity(systemAdminId);

        // deposit
        changePrank(systemAdmin); // given the entity admin role above
        writeTokenBalance(systemAdmin, naymsAddress, wethAddress, 1 ether);
        nayms.externalDeposit(wethAddress, 1 ether);

        assertEq(nayms.internalBalanceOf(systemAdminEntityId, wethId), 1 ether, "entity1 lost internal WETH");
        assertEq(nayms.internalTokenSupply(wethId), 1 ether);

        nayms.lockFunction(IDiamondProxy.externalWithdrawFromEntity.selector);

        vm.expectRevert("function is locked");
        nayms.externalWithdrawFromEntity(systemAdminEntityId, systemAdmin, address(weth), 0.5 ether);

        assertEq(nayms.internalBalanceOf(systemAdminEntityId, wethId), 1 ether, "balance should stay the same");

        vm.recordLogs();

        nayms.unlockFunction(IDiamondProxy.externalWithdrawFromEntity.selector);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("FunctionsUnlocked(bytes4[])"));
        (s_functionSelectors) = abi.decode(entries[0].data, (bytes4[]));

        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondProxy.externalWithdrawFromEntity.selector;

        assertEq(s_functionSelectors[0], functionSelectors[0]);

        nayms.externalWithdrawFromEntity(systemAdminEntityId, systemAdmin, address(weth), 0.5 ether);

        assertEq(nayms.internalBalanceOf(systemAdminEntityId, wethId), 0.5 ether, "half of balance should be withdrawn");
    }

    bytes4[] internal s_functionSelectors;

    function test_lockUnlockAllFundTransferFunctions() public {
        vm.recordLogs();

        nayms.lockAllFundTransferFunctions();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[0].topics.length, 1);
        assertEq(entries[0].topics[0], keccak256("FunctionsLocked(bytes4[])"));
        (s_functionSelectors) = abi.decode(entries[0].data, (bytes4[]));

        bytes4[] memory lockedFunctions = new bytes4[](25);
        lockedFunctions[0] = IDiamondProxy.startTokenSale.selector;
        lockedFunctions[1] = IDiamondProxy.paySimpleClaim.selector;
        lockedFunctions[2] = IDiamondProxy.paySimplePremium.selector;
        lockedFunctions[3] = IDiamondProxy.checkAndUpdateSimplePolicyState.selector;
        lockedFunctions[4] = IDiamondProxy.cancelOffer.selector;
        lockedFunctions[5] = IDiamondProxy.executeLimitOffer.selector;
        lockedFunctions[6] = IDiamondProxy.internalTransferFromEntity.selector;
        lockedFunctions[7] = IDiamondProxy.payDividendFromEntity.selector;
        lockedFunctions[8] = IDiamondProxy.internalBurn.selector;
        lockedFunctions[9] = IDiamondProxy.wrapperInternalTransferFrom.selector;
        lockedFunctions[10] = IDiamondProxy.withdrawDividend.selector;
        lockedFunctions[11] = IDiamondProxy.withdrawAllDividends.selector;
        lockedFunctions[12] = IDiamondProxy.externalWithdrawFromEntity.selector;
        lockedFunctions[13] = IDiamondProxy.externalDeposit.selector;
        lockedFunctions[14] = IDiamondProxy.stake.selector;
        lockedFunctions[15] = IDiamondProxy.unstake.selector;
        lockedFunctions[16] = IDiamondProxy.collectRewards.selector;
        lockedFunctions[17] = IDiamondProxy.payReward.selector;
        lockedFunctions[18] = IDiamondProxy.cancelSimplePolicy.selector;
        lockedFunctions[19] = IDiamondProxy.createSimplePolicy.selector;
        lockedFunctions[20] = IDiamondProxy.createEntity.selector;
        lockedFunctions[21] = IDiamondProxy.collectRewardsToInterval.selector;
        lockedFunctions[22] = IDiamondProxy.compoundRewards.selector;
        lockedFunctions[23] = IDiamondProxy.zapStake.selector;
        lockedFunctions[24] = IDiamondProxy.zapOrder.selector;

        for (uint256 i = 0; i < lockedFunctions.length; i++) {
            assertTrue(nayms.isFunctionLocked(lockedFunctions[i]));
            assertEq(s_functionSelectors[i], lockedFunctions[i]);
        }
        vm.expectRevert("function is locked");
        nayms.startTokenSale(DEFAULT_ACCOUNT0_ENTITY_ID, 100, 100);

        vm.expectRevert("function is locked");
        nayms.paySimpleClaim(LibHelpers._stringToBytes32("claimId"), 0x1100000000000000000000000000000000000000000000000000000000000000, DEFAULT_INSURED_PARTY_ENTITY_ID, 2);

        vm.expectRevert("function is locked");
        nayms.paySimplePremium(0x1100000000000000000000000000000000000000000000000000000000000000, 1000);

        vm.expectRevert("function is locked");
        nayms.checkAndUpdateSimplePolicyState(0x1100000000000000000000000000000000000000000000000000000000000000);

        vm.expectRevert("function is locked");
        nayms.cancelOffer(1);

        vm.expectRevert("function is locked");
        nayms.executeLimitOffer(wethId, 1 ether, account0Id, 100);

        vm.expectRevert("function is locked");
        nayms.internalTransferFromEntity(account0Id, wethId, 1 ether);

        vm.expectRevert("function is locked");
        nayms.payDividendFromEntity(account0Id, 1 ether);

        vm.expectRevert("function is locked");
        nayms.internalBurn(account0Id, wethId, 1 ether);

        vm.expectRevert("function is locked");
        nayms.wrapperInternalTransferFrom(account0Id, account0Id, wethId, 1 ether);

        vm.expectRevert("function is locked");
        nayms.withdrawDividend(account0Id, wethId, wethId);

        vm.expectRevert("function is locked");
        nayms.withdrawAllDividends(account0Id, wethId);

        vm.expectRevert("function is locked");
        nayms.externalWithdrawFromEntity(bytes32("0x11"), account0, wethAddress, 1 ether);

        vm.expectRevert("function is locked");
        nayms.externalDeposit(wethAddress, 1 ether);

        vm.expectRevert("function is locked");
        nayms.stake(bytes32(0), 1 ether);

        vm.expectRevert("function is locked");
        nayms.unstake(bytes32(0));

        vm.expectRevert("function is locked");
        nayms.payReward(bytes32(0), bytes32(0), bytes32(0), 1 ether);

        vm.expectRevert("function is locked");
        nayms.collectRewards(bytes32(0));

        vm.expectRevert("function is locked");
        nayms.compoundRewards(bytes32(0));

        PermitSignature memory permSig;
        OnboardingApproval memory onboardingApproval;

        vm.expectRevert("function is locked");
        nayms.zapStake(address(0), bytes32(0), 0, 0, permSig, onboardingApproval);

        vm.expectRevert("function is locked");
        nayms.zapOrder(address(0), 0, bytes32(0), 0, bytes32(0), 0, permSig, onboardingApproval);

        vm.expectRevert("function is locked");
        nayms.collectRewardsToInterval(bytes32(0), 5);

        vm.expectRevert("function is locked");
        nayms.cancelSimplePolicy(bytes32(0));

        Stakeholders memory stakeholders;
        SimplePolicy memory simplePolicy;

        vm.expectRevert("function is locked");
        nayms.createSimplePolicy(bytes32(0), bytes32(0), stakeholders, simplePolicy, bytes32(0));

        vm.expectRevert("function is locked");
        nayms.createEntity(bytes32(0), bytes32(0), entity, bytes32(0));

        nayms.unlockAllFundTransferFunctions();

        assertFalse(nayms.isFunctionLocked(IDiamondProxy.startTokenSale.selector), "function startTokenSale locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.paySimpleClaim.selector), "function paySimpleClaim locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.paySimplePremium.selector), "function paySimplePremium locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.checkAndUpdateSimplePolicyState.selector), "function checkAndUpdateSimplePolicyState locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.cancelOffer.selector), "function cancelOffer locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.executeLimitOffer.selector), "function executeLimitOffer locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.internalTransferFromEntity.selector), "function internalTransferFromEntity locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.payDividendFromEntity.selector), "function payDividendFromEntity locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.internalBurn.selector), "function internalBurn locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.wrapperInternalTransferFrom.selector), "function wrapperInternalTransferFrom locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.withdrawDividend.selector), "function withdrawDividend locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.withdrawAllDividends.selector), "function withdrawAllDividends locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.externalWithdrawFromEntity.selector), "function externalWithdrawFromEntity locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.externalDeposit.selector), "function externalDeposit locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.stake.selector), "function stake locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.unstake.selector), "function unstake locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.payReward.selector), "function payReward locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.collectRewards.selector), "function collectRewards locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.collectRewardsToInterval.selector), "function collectRewardsToInterval locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.compoundRewards.selector), "function compoundRewards locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.cancelSimplePolicy.selector), "function cancelSimplePolicy locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.createSimplePolicy.selector), "function createSimplePolicy locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.createEntity.selector), "function createEntity locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.zapStake.selector), "function zapStake locked");
        assertFalse(nayms.isFunctionLocked(IDiamondProxy.zapOrder.selector), "function zapOrder locked");
    }
}
