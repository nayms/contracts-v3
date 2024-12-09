// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { MockAccounts } from "./utils/users/MockAccounts.sol";
import { c, D03ProtocolDefaults, LibHelpers, LC } from "./defaults/D03ProtocolDefaults.sol";
import { Entity, CalculatedFees } from "../src/shared/AppStorage.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { TokenizedVaultFixture } from "test/fixtures/TokenizedVaultFixture.sol";
import "src/shared/CustomErrors.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { StdStyle } from "forge-std/Test.sol";

// solhint-disable max-states-count
// solhint-disable no-console

contract T03TokenizedVaultTest is D03ProtocolDefaults, MockAccounts {
    using LibHelpers for *;
    using StdStyle for *;

    bytes32 internal dividendBankId;

    bytes32 internal entity1 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("e5"));
    bytes32 internal entity2 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("e6"));

    uint256 internal constant collateralRatio_500 = 500;
    uint256 internal constant maxCapital_3000eth = 3_000 ether;

    uint256 internal constant depositAmount = 2_000 ether;

    NaymsAccount alice;
    NaymsAccount bob;
    NaymsAccount david;
    NaymsAccount emily;
    NaymsAccount faith;

    Entity internal entityWbtc;
    Entity internal entityWeth;

    TokenizedVaultFixture internal tokenizedVaultFixture;

    function setUp() public {
        dividendBankId = LibHelpers._stringToBytes32(LC.DIVIDEND_BANK_IDENTIFIER);

        nayms.addSupportedExternalToken(wbtcAddress, 1);
        entityWbtc = Entity({ assetId: wbtcId, collateralRatio: LC.BP_FACTOR, maxCapacity: 100 ether, utilizedCapacity: 0, simplePolicyEnabled: true });
        entityWeth = Entity({ assetId: wethId, collateralRatio: LC.BP_FACTOR, maxCapacity: 100 ether, utilizedCapacity: 0, simplePolicyEnabled: true });

        alice = makeNaymsAcc("Alice");
        bob = makeNaymsAcc("Bob");
        david = makeNaymsAcc("David");
        emily = makeNaymsAcc("Emily");
        faith = makeNaymsAcc("Faith");

        changePrank(sm.addr);

        hCreateEntity(alice.entityId, alice.id, entityWeth, "alice entitytest hash");
        hCreateEntity(bob.entityId, bob.id, entityWeth, "bob entitytest hash");
        hCreateEntity(david.entityId, david.id, entityWbtc, "david entitytest hash");
        hCreateEntity(emily.entityId, emily.id, entityWbtc, "emily entitytest hash");
        hCreateEntity(faith.entityId, faith.id, entityWbtc, "faith entitytest hash");

        tokenizedVaultFixture = new TokenizedVaultFixture();
        bytes4[] memory tvSelectors = new bytes4[](1);
        tvSelectors[0] = tokenizedVaultFixture.externalDepositDirect.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(tokenizedVaultFixture), action: IDiamondCut.FacetCutAction.Add, functionSelectors: tvSelectors });

        scheduleAndUpgradeDiamond(cut);
    }

    function externalDepositDirect(bytes32 to, address token, uint256 amount) internal {
        (bool success, ) = address(nayms).call(abi.encodeWithSelector(tokenizedVaultFixture.externalDepositDirect.selector, to, token, amount));
        require(success, "Should get commissions from app storage");
    }

    function testGetLockedBalance() public {
        changePrank(sm.addr);
        bytes32 entityId = createTestEntity(account0Id);

        // nothing at first
        assertEq(nayms.getLockedBalance(entityId, entityId), 0);

        // now start token sale to create an offer
        nayms.enableEntityTokenization(entityId, "Entity1", "Entity1 Token", 1);
        nayms.startTokenSale(entityId, 100, 100);

        assertEq(nayms.getLockedBalance(entityId, entityId), 100);
    }

    function testSingleExternalDeposit() public {
        changePrank(sm.addr);
        nayms.createEntity(entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_3000eth, true), "entity test hash");
        nayms.createEntity(entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_3000eth, true), "entity test hash");

        uint256 externalDepositAmount = depositAmount / 5;

        // note The following test shows that it's currently possible for a system admin to assign a
        // ROLE_ENTITY_ADMIN in the systemContext, which will pass the permissions check, but externalDeposit()
        // will revert if the user does not have an assigned valid parent entity.
        changePrank(systemAdmin);
        nayms.assignRole(address(999999)._getIdForAddress(), systemContext, LC.ROLE_ENTITY_ADMIN);

        // note: deposits must be an existing entity: s.existingEntities[_receiverId]
        changePrank(address(999999));
        vm.expectRevert("extDeposit: invalid receiver");
        nayms.externalDeposit(wethAddress, 1);

        vm.expectRevert("extDeposit: invalid ERC20 token");
        nayms.externalDeposit(address(0xBADAAAAAAAAA), 1);

        // deposit to entity1
        changePrank(address(signer1));

        vm.expectRevert(abi.encodePacked(ExternalDepositAmountCannotBeZero.selector));
        nayms.externalDeposit(wethAddress, 0);

        writeTokenBalance(signer1, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, externalDepositAmount);
        assertEq(weth.balanceOf(signer1), depositAmount - externalDepositAmount, "signer1 WETH balance after externalDeposit should DECREASE (transfer)");
        assertEq(weth.balanceOf(naymsAddress), externalDepositAmount, "nayms WETH balance after externalDeposit should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(entity1, wethId), externalDepositAmount, "entity1 wethId balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(wethId), externalDepositAmount, "wethId total supply should INCREASE (1:1 internal mint)");

        // deposit to entity2
        changePrank(address(signer2));
        writeTokenBalance(signer2, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, externalDepositAmount);
        vm.stopPrank();
        assertEq(weth.balanceOf(signer2), depositAmount - externalDepositAmount, "signer2 WETH balance after externalDeposit should DECREASE (transfer)");
        assertEq(weth.balanceOf(naymsAddress), externalDepositAmount * 2, "nayms WETH balance after externalDeposit should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(entity2, wethId), externalDepositAmount, "entity2 wethId balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(wethId), externalDepositAmount * 2, "wethId total supply should INCREASE (1:1 internal mint)");
    }

    // note: when creating entities for another userId, e.g. Alice is creating an entity for Bob, Alice needs to make sure they create the internal Nayms Id of Bob correctly.
    function testFuzzSingleExternalDeposit(bytes20 _entity1Partial, bytes20 _entity2Partial, address _signer1, address _signer2, uint256 _depositAmount) public {
        bytes32 _entity1 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(_entity1Partial));
        bytes32 _entity2 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(_entity2Partial));
        vm.assume(_entity1 > 0 && _entity2 > 0 && _entity1 != _entity2); // else revert: object already exists
        vm.assume(!nayms.isObject(_entity1) && !nayms.isObject(_entity2));
        vm.assume(_depositAmount > 5); // else revert: _internalMint: mint zero tokens, note: > 5 to ensure the externalDepositAmount isn't 0, see code below

        // _entity1 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(_entity1));
        // _entity2 = makeId(LC.OBJECT_TYPE_ENTITY, bytes20(_entity2));
        vm.assume(_signer1 != address(0) && _signer1 != address(999999));
        vm.assume(_signer2 != address(0) && _signer2 != address(999999));
        vm.assume(_signer1 != _signer2);

        vm.label(_signer1, "bob");
        vm.label(_signer2, "charlie");

        // force entity creation
        vm.assume(!nayms.isObject(_entity1));
        require(!nayms.isObject(_entity1), "entity1 is already an object, pick a different ID");
        require(!nayms.isObject(_entity2), "entity2 is already an object, pick a different ID");

        bytes32 signer1Id = LibHelpers._getIdForAddress(_signer1);
        bytes32 signer2Id = LibHelpers._getIdForAddress(_signer2);

        changePrank(sm.addr);
        nayms.createEntity(_entity1, signer1Id, initEntity(wethId, collateralRatio_500, maxCapital_3000eth, true), "entity test hash");
        nayms.createEntity(_entity2, signer2Id, initEntity(wethId, collateralRatio_500, maxCapital_3000eth, true), "entity test hash");

        uint256 externalDepositAmount = depositAmount / 5;

        // deposit to entity1
        changePrank(_signer1);
        writeTokenBalance(_signer1, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, externalDepositAmount);
        vm.stopPrank();

        assertEq(weth.balanceOf(_signer1), depositAmount - externalDepositAmount, "signer1 WETH balance after externalDeposit should DECREASE (transfer)");
        assertEq(weth.balanceOf(naymsAddress), externalDepositAmount, "nayms WETH balance after externalDeposit should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(_entity1, wethId), externalDepositAmount, "entity1 wethId balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(wethId), externalDepositAmount, "wethId total supply should INCREASE (1:1 internal mint)");

        // deposit to entity2
        vm.startPrank(address(_signer2));
        writeTokenBalance(_signer2, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, externalDepositAmount);
        assertEq(weth.balanceOf(_signer2), depositAmount - externalDepositAmount, "signer2 WETH balance after externalDeposit should DECREASE (transfer)");
        assertEq(weth.balanceOf(naymsAddress), externalDepositAmount * 2, "nayms WETH balance after externalDeposit should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(_entity2, wethId), externalDepositAmount, "entity2 wethId balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(wethId), externalDepositAmount * 2, "wethId total supply should INCREASE (1:1 internal mint)");
    }

    function testSingleInternalTransferFromEntity() public {
        // make entityId acc1's parent

        bytes32 acc0EntityId = nayms.getEntity(account0Id);
        changePrank(sm);
        nayms.setEntity(bob.id, acc0EntityId);

        assertEq(nayms.internalBalanceOf(account0Id, wethId), 0, "account0Id wethId balance should start at 0");

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);

        // note Depositing to account0's associated entity
        nayms.externalDeposit(wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(acc0EntityId, wethId), 1 ether, "account0's entityId (account0's parent) wethId balance should INCREASE (1:1 internal mint)");
        assertEq(nayms.internalTokenSupply(wethId), 1 ether, "wethId total supply should INCREASE (1:1 internal mint)");

        // from parent of sender (address(this)) to
        nayms.internalTransferFromEntity(account0Id, wethId, 1 ether);

        assertEq(
            nayms.internalBalanceOf(acc0EntityId, wethId),
            1 ether - 1 ether,
            "account0's entityId (account0's parent) wethId balance should DECREASE (transfer to account0Id)"
        );
        assertEq(nayms.internalBalanceOf(account0Id, wethId), 1 ether, "account0Id wethId balance should INCREASE (transfer from acc0EntityId)");

        assertEq(nayms.internalTokenSupply(wethId), 1 ether, "wethId total supply should STAY THE SAME (transfer)");

        // Must have ENTITY ADMIN role in order to internalTransferFromEntity
        changePrank(bob);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, bob.id, acc0EntityId, "", LC.GROUP_INTERNAL_TRANSFER_FROM_ENTITY));
        nayms.internalTransferFromEntity(bob.id, wethId, 1 ether);
    }

    function testSingleExternalWithdraw() public {
        testSingleExternalDeposit();

        uint256 account0WethBalanceAccount0 = weth.balanceOf(account0);
        uint256 naymsWethBalancePre = weth.balanceOf(naymsAddress);
        uint256 entity1WethInternalBalance = nayms.internalBalanceOf(entity1, wethId);
        uint256 naymsWethInternalTokenSupply = nayms.internalTokenSupply(wethId);

        vm.startPrank(sa.addr);
        nayms.assignRole(em.id, entity1, LC.ROLE_ENTITY_MANAGER);

        changePrank(em);
        nayms.assignRole(account0Id, entity1, LC.ROLE_ENTITY_COMPTROLLER_WITHDRAW);

        changePrank(signer1);

        vm.expectRevert(abi.encodePacked(ExternalWithdrawAmountCannotBeZero.selector));
        nayms.externalWithdrawFromEntity(entity1, account0, wethAddress, 0);

        nayms.externalWithdrawFromEntity(entity1, account0, wethAddress, 100);

        assertEq(weth.balanceOf(account0), account0WethBalanceAccount0 + 100, "account0 got WETH");
        assertEq(weth.balanceOf(naymsAddress), naymsWethBalancePre - 100, "nayms lost WETH");
        assertEq(nayms.internalBalanceOf(entity1, wethId), entity1WethInternalBalance - 100, "entity1 lost internal WETH");
        assertEq(nayms.internalTokenSupply(wethId), naymsWethInternalTokenSupply - 100, "nayms burned internal WETH");
    }

    function testOnlyRolesInGroupPayDividendFromEntityCanPayDividend() public {
        bytes32 acc0EntityId = nayms.getEntity(account0Id);
        changePrank(sm.addr);
        nayms.enableEntityTokenization(acc0EntityId, "E1", "E1", 1e6);
        nayms.startTokenSale(acc0EntityId, 1 ether, 1 ether);

        bytes32 acc9Id = LibHelpers._getIdForAddress(account9);
        nayms.setEntity(acc9Id, acc0EntityId);

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, 1 ether);
        changePrank(account9);

        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, acc9Id, acc0EntityId, "", LC.GROUP_PAY_DIVIDEND_FROM_ENTITY));
        nayms.payDividendFromEntity(bytes32("0x1"), 1 ether);
    }

    function testPayDividendsWithZeroParticipationTokenSupply() public {
        bytes32 acc0EntityId = nayms.getEntity(account0Id);
        nayms.assignRole(em.id, acc0EntityId, LC.ROLE_ENTITY_MANAGER);

        assertEq(nayms.internalBalanceOf(acc0EntityId, wethId), 0, "account0Id wethId balance should start at 0");

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);

        nayms.externalDeposit(wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(acc0EntityId, wethId), 1 ether, "account0Id wethId balance should INCREASE (mint)");

        uint256 withdrawableDiv = nayms.getWithdrawableDividend(account0Id, wethId, wethId);
        // No withdrawable dividends.
        assertEq(withdrawableDiv, 0);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(acc0EntityId), 0, "Testing when the participation token supply is 0, but par token supply is NOT 0");

        bytes32 randomGuid = makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1"));

        address nonAdminAddress = vm.addr(0xACC9);
        bytes32 nonAdminId = LibHelpers._getIdForAddress(nonAdminAddress);
        changePrank(sm.addr);
        nayms.setEntity(nonAdminId, acc0EntityId);

        changePrank(nonAdminAddress);
        vm.expectRevert(abi.encodeWithSelector(InvalidGroupPrivilege.selector, nonAdminId, acc0EntityId, "", LC.GROUP_PAY_DIVIDEND_FROM_ENTITY));
        nayms.payDividendFromEntity(randomGuid, 10 ether);

        changePrank(em.addr);
        nayms.assignRole(acc0EntityId, acc0EntityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);
        changePrank(account0);
        vm.expectRevert("payDividendFromEntity: insufficient balance");
        nayms.payDividendFromEntity(randomGuid, 10 ether);

        nayms.payDividendFromEntity(randomGuid, 1 ether);

        // note: When the participation token supply is 0, payDividend() should transfer the payout directly to the payee
        assertEq(nayms.internalBalanceOf(acc0EntityId, wethId), 1 ether, "acc0EntityId wethId balance should INCREASE (transfer)");
        assertEq(nayms.internalBalanceOf(account0Id, wethId), 1 ether - 1 ether, "account0Id wethId balance should DECREASE (transfer)");
        assertEq(nayms.internalTokenSupply(wethId), 1 ether, "wethId total supply should STAY THE SAME");
    }

    // start token sale, pay dividend,
    function testPayDividendsWithNonZeroParticipationTokenSupply() public {
        bytes32 acc0EntityId = nayms.getEntity(account0Id);
        nayms.assignRole(em.id, acc0EntityId, LC.ROLE_ENTITY_MANAGER);

        assertEq(nayms.internalBalanceOf(account0Id, wethId), 0, "acc0EntityId wethId balance should start at 0");

        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, depositAmount);

        // note Depositing to account0's associated entity
        nayms.externalDeposit(wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(acc0EntityId, wethId), 1 ether, "acc0EntityId wethId balance should INCREASE (mint)");

        uint256 withdrawableDiv = nayms.getWithdrawableDividend(account0Id, wethId, wethId);
        // No withdrawable dividends.
        assertEq(withdrawableDiv, 0);

        changePrank(sm.addr);
        // note: starting a token sale which mints participation tokens
        nayms.enableEntityTokenization(acc0EntityId, "eAlice", "eAlice", 1e6);
        nayms.startTokenSale(acc0EntityId, 1e18, 1e18);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(acc0EntityId), 1 ether, "");
        bytes32 randomGuid = makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1"));

        changePrank(em.addr);
        nayms.assignRole(acc0EntityId, acc0EntityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(account0);
        nayms.payDividendFromEntity(randomGuid, 1 ether);
        // note:When the participation token supply is non zero,
        assertEq(nayms.internalBalanceOf(acc0EntityId, wethId), 0, "acc0EntityId wethId balance should DECREASE (transfer)");
        assertEq(nayms.internalTokenSupply(wethId), 1 ether, "wethId total supply should STAY THE SAME");

        assertEq(
            nayms.internalBalanceOf(dividendBankId, wethId),
            1 ether,
            "The balance of the dividend bank should be non zero after payDividend() is called on a par token with a non zero supply."
        );

        assertEq(nayms.internalBalanceOf(signer1Id, wethId), 0, "");

        changePrank(signer1);
        writeTokenBalance(signer1, naymsAddress, wethAddress, depositAmount);

        bytes32 signer1EntityId = nayms.getEntity(signer1Id);

        // give signer1's entity wethId
        nayms.externalDeposit(wethAddress, 2 ether);
        assertEq(nayms.internalBalanceOf(signer1EntityId, wethId), 2 ether, "signer1EntityId wethId balance should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 1 ether, "dividendBankId wethId balance should STAY THE SAME");
        assertEq(nayms.internalTokenSupply(wethId), 3 ether, "wethId total supply should INCREASE (mint)");

        changePrank(sm.addr);
        nayms.assignRole(signer1Id, systemContext, LC.ROLE_ENTITY_CP);

        // the taker's buy amount
        uint256 takerBuyAmount = 1 ether;
        changePrank(signer1);
        nayms.internalBalanceOf(signer1Id, wethId);
        nayms.executeLimitOffer(wethId, 1 ether, acc0EntityId, takerBuyAmount);

        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 1 ether - 1 ether, "The dividend should've been transferred when executeLimitOffer() is called and executed");

        assertEq(
            nayms.internalBalanceOf(acc0EntityId, wethId),
            2 ether,
            "account0's entity should've received 1 ether from dividends and 1 ether from their order being filled for their participation tokens"
        );
        nayms.internalBalanceOf(signer1Id, wethId); // no change

        changePrank(account0);
        nayms.withdrawDividend(acc0EntityId, wethId, wethId);
        nayms.withdrawAllDividends(account0Id, wethId);
        assertEq(nayms.internalBalanceOf(acc0EntityId, wethId), 2 ether, "acc0EntityId wethId balance should STAY THE SAME");

        (uint256 totalFees_, ) = nayms.calculateTradingFees(signer1EntityId, wethId, acc0EntityId, takerBuyAmount);

        // the amount the taker receives from the matching order
        uint256 calculatedTakerAmount = takerBuyAmount - totalFees_;
        assertEq(nayms.internalBalanceOf(signer1EntityId, wethId), calculatedTakerAmount, "balance of signer1's entity should be the their buy amount minus the commission fees"); // order filled minus trading commissions)
    }

    function testMultipleDepositDividends() public {
        nayms.assignRole(em.id, alice.entityId, LC.ROLE_ENTITY_MANAGER);

        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, depositAmount);

        // note: starting a token sale which mints participation tokens
        changePrank(sm.addr);
        nayms.enableEntityTokenization(alice.entityId, "eAlice", "eAlice", 1e6);
        nayms.startTokenSale(alice.entityId, 1e18, 1e18);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(alice.entityId), 1e18, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(alice.entityId, alice.entityId), 1e18, "eAlice's eAlice balance should INCREASE (mint)");

        changePrank(alice);
        nayms.externalDeposit(wethAddress, 1 ether);
        assertEq(nayms.internalTokenSupply(wethId), 1 ether, "wethId token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 1 ether, "eAlice's wethId balance should INCREASE (deposit)");

        changePrank(em.addr);
        nayms.assignRole(alice.entityId, alice.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(alice);
        bytes32 randomGuid = makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1"));
        nayms.payDividendFromEntity(randomGuid, 1 ether); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 1 ether - 1 ether, "eAlice's wethId balance should DECREASE (transfer to dividend bank)");

        assertEq(
            nayms.internalBalanceOf(dividendBankId, wethId),
            1 ether,
            "The balance of the dividend bank should be non zero after payDividend() is called on a par token with a non zero supply."
        );

        uint256 takerBuyAmount = 1e18;
        c.log(nayms.getLockedBalance(alice.entityId, alice.entityId));

        (uint256 totalFees_, ) = nayms.calculateTradingFees(bob.entityId, wethId, alice.entityId, takerBuyAmount);

        changePrank(bob);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, 1 ether + totalFees_);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 1 ether + totalFees_, "eBob's wethId balance should INCREASE");

        changePrank(sm.addr);
        nayms.assignRole(bob.entityId, bob.entityId, LC.ROLE_ENTITY_CP);
        changePrank(bob);
        nayms.executeLimitOffer(wethId, 1 ether, alice.entityId, 1e18);
        vm.stopPrank();

        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 0, "eBob's wethId balance should DECREASE");
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 2 ether, "eAlice's wethId balance should INCREASE");
    }

    function testMultipleDepositDividendWithdraw2() public {
        changePrank(sm.addr);
        NaymsAccount memory charlie = makeNaymsAcc("Charlie");
        hCreateEntity(charlie.entityId, charlie.id, entityWbtc, "charlie entitytest hash");

        changePrank(sm.addr);
        nayms.assignRole(bob.entityId, bob.entityId, LC.ROLE_ENTITY_CP);
        nayms.assignRole(charlie.entityId, charlie.entityId, LC.ROLE_ENTITY_CP);

        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(alice.entityId, alice.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, depositAmount);

        nayms.externalDeposit(wethAddress, 80_000); // to be used for dividend payments

        (uint256 totalFees_, ) = nayms.calculateTradingFees(bob.entityId, wethId, alice.entityId, 3_000);
        changePrank(bob);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, 3_000 + totalFees_);

        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 3_000 + totalFees_);

        (totalFees_, ) = nayms.calculateTradingFees(charlie.entityId, wethId, alice.entityId, 17_000);
        changePrank(charlie);
        writeTokenBalance(charlie.addr, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, 17_000 + totalFees_);

        // note: starting a token sale which mints participation tokens
        changePrank(sm.addr);
        nayms.enableEntityTokenization(alice.entityId, "eAlice", "eAlice", 1);
        nayms.startTokenSale(alice.entityId, 20_000, 20_000);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(alice.entityId), 20_000, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(alice.entityId, alice.entityId), 20_000, "eAlice's eAlice balance should INCREASE (mint)");

        changePrank(bob);
        nayms.executeLimitOffer(wethId, 3_000, alice.entityId, 3_000); // 1:1 purchase price

        changePrank(charlie);
        nayms.executeLimitOffer(wethId, 17_000, alice.entityId, 17_000); // 1:1 purchase price

        assertEq(nayms.internalBalanceOf(bob.entityId, alice.entityId), 3_000);
        assertEq(nayms.internalBalanceOf(charlie.entityId, alice.entityId), 17_000);

        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 100_000);

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 0);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 0);

        changePrank(alice);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")), 40_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 60_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 40_000);

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 6_000);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 34_000);

        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x2")), 60_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 0);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 100_000);

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 15_000);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 85_000);

        nayms.withdrawDividend(bob.entityId, alice.entityId, wethId);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 15_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 85_000);

        nayms.withdrawDividend(charlie.entityId, alice.entityId, wethId);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 15_000);
        assertEq(nayms.internalBalanceOf(charlie.entityId, wethId), 85_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 0);
    }

    function testFuzzTwoEntityDepositDividendWithdraw(
        uint256 bobWethDepositAmount,
        uint256 eAliceParTokenSaleAmount,
        uint256 eAliceParTokenPrice,
        uint256 bobEAliceBuyAmount,
        uint256 dividendAmount
    ) public {
        vm.assume(1 < dividendAmount && dividendAmount < type(uint128).max);
        vm.assume(10_000 < bobWethDepositAmount && bobWethDepositAmount < type(uint128).max);
        vm.assume(10_000 < eAliceParTokenSaleAmount && eAliceParTokenSaleAmount < type(uint128).max);
        vm.assume(10_000 < eAliceParTokenPrice && eAliceParTokenPrice < type(uint128).max);
        vm.assume(10_000 < bobEAliceBuyAmount && bobEAliceBuyAmount < type(uint128).max);

        require(bobEAliceBuyAmount >= 10_000 && bobEAliceBuyAmount <= type(uint128).max);

        changePrank(sm.addr);
        nayms.assignRole(bob.entityId, bob.entityId, LC.ROLE_ENTITY_CP);
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(alice.entityId, alice.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, type(uint256).max);

        // --- Deposit WETH to eAlice --- //
        nayms.externalDeposit(wethAddress, type(uint256).max);

        // --- Internal transfer wethId from eAlice to eBob ---/
        (uint256 totalFees_, ) = nayms.calculateTradingFees(bob.entityId, wethId, alice.entityId, eAliceParTokenPrice);
        nayms.internalTransferFromEntity(bob.entityId, wethId, bobWethDepositAmount + eAliceParTokenPrice + totalFees_);

        c.log("commissions amount:", totalFees_);

        // note: starting a token sale which mints participation tokens
        changePrank(sm.addr);
        nayms.enableEntityTokenization(alice.entityId, "eAlice", "eAlice", 1e6);
        nayms.startTokenSale(alice.entityId, eAliceParTokenSaleAmount, eAliceParTokenPrice);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(alice.entityId), eAliceParTokenSaleAmount, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(alice.entityId, alice.entityId), eAliceParTokenSaleAmount, "eAlice's eAlice balance should INCREASE (mint)");

        changePrank(bob);
        // note: Purchase an arbitrary amount of eAlice
        // note: bob is selling bobWethDepositAmount of wethId for bobEAliceBuyAmount of eAlice
        // if the buy amount is less than the price of 1, then the buy amount is calculated to be 0 and the transaction will revert
        uint256 relativePriceOfEAlice = eAliceParTokenSaleAmount / eAliceParTokenPrice;
        c.log(string.concat(vm.toString(eAliceParTokenPrice), " relativePriceOfEAlice"), relativePriceOfEAlice);

        uint256 relativePriceOfEAlice18 = (eAliceParTokenPrice * 1e18) / eAliceParTokenSaleAmount;
        c.log(string.concat(vm.toString(eAliceParTokenPrice), " relativePriceOfEAlice18"), relativePriceOfEAlice18);
        c.log("bobWethDepositAmount", bobWethDepositAmount);
        c.log("eAliceParTokenSaleAmount", eAliceParTokenSaleAmount);
        c.log("eAliceParTokenPrice", eAliceParTokenPrice);
        c.log("bobEAliceBuyAmount", bobEAliceBuyAmount);

        uint256 relativeOfferPrice = bobWethDepositAmount / bobEAliceBuyAmount;

        if (bobEAliceBuyAmount < relativePriceOfEAlice || (bobEAliceBuyAmount < relativePriceOfEAlice && relativeOfferPrice < relativePriceOfEAlice)) {
            assertEq(nayms.internalBalanceOf(bob.entityId, alice.entityId), 0, "eBob's eAlice balance should STAY THE SAME (executeLimitOffer)");

            // when bob is trying to buy an amount of eAlice that is valued at less than 1 token, the buy amount is calculated to be 0
            vm.expectRevert("buy amount must be >0");
            nayms.executeLimitOffer(wethId, bobWethDepositAmount, alice.entityId, bobEAliceBuyAmount);
        } else {
            nayms.executeLimitOffer(wethId, bobWethDepositAmount, alice.entityId, bobEAliceBuyAmount);

            uint256 balanceOfEbob = nayms.internalBalanceOf(bob.entityId, alice.entityId);

            changePrank(alice);
            bytes32 randomGuid = makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1"));
            nayms.payDividendFromEntity(randomGuid, dividendAmount); // eAlice is paying out a dividend

            uint256 calc = (balanceOfEbob * dividendAmount) / eAliceParTokenSaleAmount;
            assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), calc, "Bob's withdrawable dividend doesn't match".red());

            changePrank(bob);
            uint256 bobWethBalance = nayms.internalBalanceOf(bob.entityId, wethId);
            nayms.withdrawDividend(bob.entityId, alice.entityId, wethId);
            assertEq(nayms.internalBalanceOf(bob.entityId, wethId), bobWethBalance + calc, "Bob's balance after divqidend withdrawal doesn't match".red());
        }
    }

    function testMultipleDepositDividendWithdrawWithTwoDividendTokens() public {
        changePrank(sm.addr);
        NaymsAccount memory charlie = makeNaymsAcc("Charlie");
        hCreateEntity(charlie.entityId, charlie.id, entityWbtc, "charlie entitytest hash");

        changePrank(sm.addr);
        nayms.assignRole(bob.entityId, bob.entityId, LC.ROLE_ENTITY_CP);
        nayms.assignRole(charlie.entityId, charlie.entityId, LC.ROLE_ENTITY_CP);
        nayms.assignRole(emily.entityId, emily.entityId, LC.ROLE_ENTITY_CP);
        nayms.assignRole(faith.entityId, faith.entityId, LC.ROLE_ENTITY_CP);

        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);

        changePrank(em.addr);
        nayms.assignRole(alice.entityId, alice.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);
        nayms.assignRole(david.entityId, david.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, depositAmount);
        writeTokenBalance(alice.addr, naymsAddress, wbtcAddress, depositAmount);

        nayms.externalDeposit(wethAddress, 80_000); // to be used for dividend payments

        changePrank(bob);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, depositAmount);
        (uint256 totalFees_, ) = nayms.calculateTradingFees(bob.entityId, wethId, alice.entityId, 3_000);
        nayms.externalDeposit(wethAddress, 3_000 + totalFees_);

        changePrank(charlie);
        writeTokenBalance(charlie.addr, naymsAddress, wethAddress, depositAmount);
        (totalFees_, ) = nayms.calculateTradingFees(charlie.entityId, wethId, alice.entityId, 17_000);
        nayms.externalDeposit(wethAddress, 17_000 + totalFees_);

        changePrank(david);
        writeTokenBalance(david.addr, naymsAddress, wbtcAddress, depositAmount);
        nayms.externalDeposit(wbtcAddress, 80_000); // to be used for dividend payments

        changePrank(emily);
        writeTokenBalance(emily.addr, naymsAddress, wbtcAddress, depositAmount);
        (totalFees_, ) = nayms.calculateTradingFees(emily.entityId, wbtcId, david.entityId, 3_000);
        nayms.externalDeposit(wbtcAddress, 3_000 + totalFees_);

        changePrank(faith);
        writeTokenBalance(faith.addr, naymsAddress, wbtcAddress, depositAmount);
        (totalFees_, ) = nayms.calculateTradingFees(faith.entityId, wbtcId, david.entityId, 17_000);
        nayms.externalDeposit(wbtcAddress, 17_000 + totalFees_);

        (uint256 bobTotalFees_, ) = nayms.calculateTradingFees(bob.entityId, wethId, alice.entityId, 3_000);
        (uint256 emiliyTotalFees_, ) = nayms.calculateTradingFees(emily.entityId, wbtcId, david.entityId, 3_000);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 3_000 + bobTotalFees_);
        assertEq(nayms.internalBalanceOf(emily.entityId, wbtcId), 3_000 + emiliyTotalFees_);

        changePrank(sm.addr);
        // note: starting a token sale which mints participation tokens
        nayms.enableEntityTokenization(alice.entityId, "eAlice", "eAlice", 1);
        nayms.enableEntityTokenization(david.entityId, "eDavid", "eDavid", 1);

        nayms.startTokenSale(alice.entityId, 20_000, 20_000);
        nayms.startTokenSale(david.entityId, 20_000, 20_000);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(alice.entityId), 20_000, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(alice.entityId, alice.entityId), 20_000, "eAlice's eAlice balance should INCREASE (mint)");
        assertEq(nayms.internalTokenSupply(david.entityId), 20_000, "eDavid participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(david.entityId, david.entityId), 20_000, "eDavid's eDavid balance should INCREASE (mint)");

        changePrank(bob);
        nayms.executeLimitOffer(wethId, 3_000, alice.entityId, 3_000); // 1:1 purchase price
        assertEq(nayms.internalBalanceOf(bob.entityId, alice.entityId), 3_000, "Bob's eAlice balance should increase".red());

        startPrank(charlie);
        nayms.executeLimitOffer(wethId, 17_000, alice.entityId, 17_000); // 1:1 purchase price
        assertEq(nayms.internalBalanceOf(charlie.entityId, alice.entityId), 17_000, "Charlie's eAlice balance should increase".red());

        changePrank(emily);
        nayms.executeLimitOffer(wbtcId, 3_000, david.entityId, 3_000); // 1:1 purchase price
        assertEq(nayms.internalBalanceOf(emily.entityId, david.entityId), 3_000, "Emily's eAlice balance should increase".red());

        changePrank(faith);
        nayms.executeLimitOffer(wbtcId, 17_000, david.entityId, 17_000); // 1:1 purchase price
        assertEq(nayms.internalBalanceOf(faith.entityId, david.entityId), 17_000, "Faith's eAlice balance should increase".red());

        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 100_000, "Alice's WETH balance should increase".red());

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 0);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 0);

        startPrank(alice);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")), 40_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 60_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 40_000);

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 6_000);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 34_000);

        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x2")), 60_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 0, "Alice' balance should be zero".red());
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 100_000, "Dividend bank balance should increase".red());

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 15_000);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 85_000);

        // eDavid, eEmily, eFaith
        assertEq(nayms.getWithdrawableDividend(emily.entityId, david.entityId, wethId), 0);
        assertEq(nayms.getWithdrawableDividend(faith.entityId, david.entityId, wethId), 0);

        assertEq(nayms.internalBalanceOf(david.entityId, wbtcId), 100_000);
        startPrank(david);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x3")), 40_000); // eDavid is paying out a dividend
        assertEq(nayms.internalBalanceOf(david.entityId, wbtcId), 60_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wbtcId), 40_000);

        assertEq(nayms.getWithdrawableDividend(emily.entityId, david.entityId, wbtcId), 6_000);
        assertEq(nayms.getWithdrawableDividend(faith.entityId, david.entityId, wbtcId), 34_000);

        startPrank(david);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x4")), 60_000); // eDavid is paying out a dividend
        assertEq(nayms.internalBalanceOf(david.entityId, wbtcId), 0);
        assertEq(nayms.internalBalanceOf(dividendBankId, wbtcId), 100_000);

        assertEq(nayms.getWithdrawableDividend(emily.entityId, david.entityId, wbtcId), 15_000);
        assertEq(nayms.getWithdrawableDividend(faith.entityId, david.entityId, wbtcId), 85_000);

        nayms.withdrawDividend(bob.entityId, alice.entityId, wethId);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 15_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 85_000);

        nayms.withdrawDividend(charlie.entityId, alice.entityId, wethId);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 15_000);
        assertEq(nayms.internalBalanceOf(charlie.entityId, wethId), 85_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 0);

        nayms.withdrawDividend(emily.entityId, david.entityId, wbtcId);
        assertEq(nayms.internalBalanceOf(emily.entityId, wbtcId), 15_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wbtcId), 85_000);

        nayms.withdrawDividend(faith.entityId, david.entityId, wbtcId);
        assertEq(nayms.internalBalanceOf(emily.entityId, wbtcId), 15_000);
        assertEq(nayms.internalBalanceOf(faith.entityId, wbtcId), 85_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wbtcId), 0);
    }

    function testDepositAndBurn() public {
        changePrank(sm.addr);
        NaymsAccount memory charlie = makeNaymsAcc("Charlie");
        hCreateEntity(charlie.entityId, charlie.id, entityWbtc, "charlie entitytest hash");

        uint256 defaultTradingFeeBP = defaultInitSaleFee;

        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, depositAmount);

        nayms.externalDeposit(wethAddress, 80_000); // to be used for dividend payments

        changePrank(bob);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, depositAmount);
        uint256 totalFees = (defaultTradingFeeBP * 3_000) / LC.BP_FACTOR;
        nayms.externalDeposit(wethAddress, 3_000 + totalFees);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 3_000 + totalFees);

        changePrank(charlie);
        writeTokenBalance(charlie.addr, naymsAddress, wethAddress, depositAmount);
        totalFees = (defaultTradingFeeBP * 17_000) / LC.BP_FACTOR;
        nayms.externalDeposit(wethAddress, 17_000 + totalFees);

        // note: starting a token sale which mints participation tokens
        changePrank(sm.addr);
        nayms.enableEntityTokenization(alice.entityId, "eAlice", "eAlice", 1);
        nayms.startTokenSale(alice.entityId, 20_000, 20_000);
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(alice.entityId, alice.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        // check token supply of participation token (entity token)
        assertEq(nayms.internalTokenSupply(alice.entityId), 20_000, "eAlice participation token supply should INCREASE (mint)");
        assertEq(nayms.internalBalanceOf(alice.entityId, alice.entityId), 20_000, "eAlice's eAlice balance should INCREASE (mint)");

        changePrank(sm.addr);

        nayms.assignRole(bob.entityId, bob.entityId, LC.ROLE_ENTITY_CP);
        nayms.assignRole(charlie.entityId, charlie.entityId, LC.ROLE_ENTITY_CP);

        changePrank(bob);
        nayms.executeLimitOffer(wethId, 3_000, alice.entityId, 3_000); // 1:1 purchase price

        changePrank(charlie);
        nayms.executeLimitOffer(wethId, 17_000, alice.entityId, 17_000); // 1:1 purchase price

        assertEq(nayms.internalBalanceOf(bob.entityId, alice.entityId), 3_000);
        assertEq(nayms.internalBalanceOf(charlie.entityId, alice.entityId), 17_000);

        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 100_000);

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 0);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 0);

        changePrank(alice);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")), 40_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 60_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 40_000);

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 6_000);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 34_000);

        vm.expectRevert("nonunique dividend distribution identifier");
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")), 60_000); // eAlice is paying out a dividend

        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x2")), 60_000); // eAlice is paying out a dividend
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 0);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 100_000);

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 15_000);
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 85_000);

        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 0, "eBob's wethId balance should be 0");

        changePrank(systemAdmin);
        nayms.internalBurn(bob.entityId, alice.entityId, 3_000);

        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 15_000);

        nayms.withdrawAllDividends(bob.entityId, alice.entityId);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 15_000);
        assertEq(nayms.internalBalanceOf(dividendBankId, wethId), 85_000);
    }

    function scopeToDefaults(uint256 _input) internal pure {
        scopeTo(_input, 1_000, type(uint128).max);
    }

    function scopeTo(uint256 _input, uint256 _min, uint256 _max) internal pure {
        vm.assume(_min <= _input && _input <= _max);
    }

    function testFuzzWithdrawableDividends(uint256 _parTokenSupply, uint256 _holdersShare, uint256 _dividendAmount) public {
        // -- Test Case -----------------------------
        // 1. start token sale
        // 2. distribute dividends
        // 3. purchase participation tokens
        // 4. taker SHOULD NOT have withdrawable dividend
        // 5. distribute another round of dividends
        // 6. SHOULD have withdrawable dividends now!
        // ------------------------------------------

        // scope input values
        scopeToDefaults(_parTokenSupply);
        scopeTo(_holdersShare, 1, 100);
        scopeTo(_dividendAmount, 1, _parTokenSupply);

        // prettier-ignore
        Entity memory e = Entity({ 
            assetId: wethId, 
            collateralRatio: 1_000, 
            maxCapacity: _parTokenSupply, 
            utilizedCapacity: 0, 
            simplePolicyEnabled: true 
        });

        changePrank(sm.addr);
        bytes32 entity0Id = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("0xe1"));
        bytes32 entity1Id = makeId(LC.OBJECT_TYPE_ENTITY, bytes20("0xe2"));
        nayms.createEntity(entity0Id, account0Id, e, "test");
        nayms.createEntity(entity1Id, signer1Id, e, "test");

        nayms.assignRole(nayms.getEntity(signer1Id), nayms.getEntity(signer1Id), LC.ROLE_ENTITY_CP);
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(account0Id, systemContext, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(sm.addr);
        // 1. ---- start token sale ----
        nayms.enableEntityTokenization(entity0Id, "e0token", "e0token", 1);

        nayms.startTokenSale(entity0Id, _parTokenSupply, _parTokenSupply);
        assertEq(nayms.internalTokenSupply(entity0Id), _parTokenSupply, "Entity 1 participation tokens should be minted");

        // 2. ---- distribute dividends ----

        // fund entity0 to distribute as dividends
        changePrank(account0);
        writeTokenBalance(account0, naymsAddress, wethAddress, _dividendAmount * 2);
        assertEq(nayms.internalBalanceOf(entity0Id, wethId), 0, "entity0 wethId balance should start at 0");
        nayms.externalDeposit(wethAddress, _dividendAmount);
        assertEq(nayms.internalBalanceOf(entity0Id, wethId), _dividendAmount, "entity0 wethId balance should INCREASE (mint)");

        // distribute dividends to entity0 shareholders
        bytes32 guid = makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0xc0ffe"));
        nayms.payDividendFromEntity(guid, _dividendAmount);

        // entity1 has no share, thus no withdrawable dividend at this point
        changePrank(signer1);
        uint256 entity1Div = nayms.getWithdrawableDividend(entity1Id, wethId, wethId);
        assertEq(entity1Div, 0, "Entity 1 has no tokens, so should NOT have dividend to claim");
        vm.stopPrank();

        // 3.  ---- purchase participation tokens  ----

        // fund entity1 to by par-tokens
        uint256 takeAmount = (_parTokenSupply * _holdersShare) / 100;

        (uint256 totalFees_, ) = nayms.calculateTradingFees(bob.entityId, wethId, entity0Id, takeAmount);

        vm.startPrank(signer1);
        writeTokenBalance(signer1, naymsAddress, wethAddress, takeAmount + totalFees_);
        nayms.externalDeposit(wethAddress, takeAmount + totalFees_);
        vm.stopPrank();
        assertEq(nayms.internalBalanceOf(entity1Id, wethId), takeAmount + totalFees_, "entity1 wethId balance should INCREASE (mint)");
        c.log(" -- e1 balance: ", nayms.internalBalanceOf(entity1Id, wethId));

        // place order, get the tokens
        vm.startPrank(signer1);
        nayms.executeLimitOffer(wethId, takeAmount, entity0Id, takeAmount);
        assertEq(nayms.internalBalanceOf(entity1Id, entity0Id), takeAmount, "entity1 SHOULD have entity0-tokens in his balance");
        vm.stopPrank();

        // 4.  ---- SHOULD NOT have withdrawable dividend  ----

        // withdrawable dividend should still be zero!
        vm.startPrank(signer1);
        uint256 entity1DivAfterPurchase = nayms.getWithdrawableDividend(entity1Id, entity0Id, wethId);
        assertEq(entity1DivAfterPurchase, 0, "Entity 1 should NOT have dividend to claim here!");
        vm.stopPrank();

        // 5.  ---- distribute another round of dividends  ----
        vm.startPrank(account0);
        c.log(nayms.internalBalanceOf(entity0Id, wethId));
        bytes32 guid2 = makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0xbEEf"));
        nayms.payDividendFromEntity(guid2, _dividendAmount);

        // 6.  ---- SHOULD have more withdrawable dividends now!  ----

        uint256 expectedDividend = (_dividendAmount * takeAmount) / _parTokenSupply;
        changePrank(signer1);
        uint256 entity1DivAfter2Purchase = nayms.getWithdrawableDividend(entity1Id, entity0Id, wethId);

        // tolerate rounding errors
        uint256 absDiff = entity1DivAfter2Purchase > expectedDividend ? entity1DivAfter2Purchase - expectedDividend : expectedDividend - entity1DivAfter2Purchase;
        assertTrue(absDiff <= 1, "Entity 1 should have a dividend to claim here!");

        vm.stopPrank();
    }

    function testWithdrawableDividendWhenPurchasedAfterDistribution() public {
        // test specific values
        testFuzzWithdrawableDividends(1_000 ether, 10, 100 ether);
    }

    function testReceivingDividendAfterTokenTrading() public {
        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, depositAmount);
        changePrank(sm.addr);
        nayms.assignRole(alice.entityId, alice.entityId, LC.ROLE_ENTITY_CP);
        nayms.assignRole(bob.entityId, bob.entityId, LC.ROLE_ENTITY_CP);
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(alice.id, systemContext, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        // STAGE 1: Alice is starting an eAlice token sale.
        changePrank(sm.addr);
        nayms.enableEntityTokenization(alice.entityId, "eAlice", "eAlice", 1);
        uint256 tokenAmount = 1e18;
        nayms.startTokenSale(alice.entityId, tokenAmount, tokenAmount);
        changePrank(alice);
        nayms.externalDeposit(wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 1 ether, "eAlice's wethId balance should INCREASE");
        // eAlice is paying out a dividend with guid 0x1
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")), 1 ether);

        // STAGE 2: Bob is trying to buy all of the newly sold eAlice Tokens.
        changePrank(bob);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, depositAmount);

        (uint256 totalFees_, ) = nayms.calculateTradingFees(bob.entityId, wethId, alice.entityId, tokenAmount);

        nayms.externalDeposit(wethAddress, 1 ether + totalFees_);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 1 ether + totalFees_, "eBob's wethId balance should INCREASE");
        nayms.executeLimitOffer(wethId, 1 ether, alice.entityId, tokenAmount);

        // STAGE 3: Bob selling the newly purchased eAlice token back to Alice.
        nayms.executeLimitOffer(alice.entityId, tokenAmount, wethId, 1 ether);

        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, 1 ether + totalFees_);

        nayms.objectMinimumSell(wethId);
        nayms.objectMinimumSell(alice.entityId);
        nayms.executeLimitOffer(wethId, 1 ether, alice.entityId, tokenAmount);

        // STAGE 4: Alice selling the newly purchased eAlice token back to Bob.
        nayms.executeLimitOffer(alice.entityId, tokenAmount, wethId, 1 ether);
        changePrank(bob);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, depositAmount);

        // secondary trading implies different fees
        (uint256 totalFees_2, ) = nayms.calculateTradingFees(bob.entityId, wethId, alice.entityId, tokenAmount);

        nayms.externalDeposit(wethAddress, 1 ether + totalFees_2);
        nayms.executeLimitOffer(wethId, 1 ether, alice.entityId, tokenAmount);

        // STAGE 5: Alice wants to pay a dividend to the eAlice token holders.
        changePrank(alice);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x2")), 1 ether); // eAlice is paying out a dividend with new guid "0x2"
        // Note that up to this point, Bob has not received any dividend because the initial dividend is already all taken by Alice.

        // STAGE 6: Bob tries to get this new dividend since he now has all the eAlice
        changePrank(bob);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 1 ether, "eBob's current balance");
        nayms.withdrawDividend(bob.entityId, alice.entityId, wethId);
        // This SHOULD NOT fail because nayms.getWithdrawableDividend(eBob, eAlice, wethId) will return 0, so Bob will not receive the new dividend.
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 2 ether, "eBob's current balance should increase by 1ETH after receiving dividend.");
        vm.stopPrank();
    }

    function testDoubleCountingDividendPayoutsFix() public {
        uint256 eAliceStartAmount = 500 ether;

        changePrank(sm.addr);
        nayms.enableEntityTokenization(alice.entityId, "eAlice", "eAlice", 1e6);
        nayms.assignRole(bob.entityId, bob.entityId, LC.ROLE_ENTITY_CP);
        changePrank(sa.addr);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        changePrank(em.addr);
        nayms.assignRole(alice.entityId, alice.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);

        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, depositAmount);

        // 1. Alice starts with 500 WETH in its internal balance
        nayms.externalDeposit(wethAddress, eAliceStartAmount);
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), eAliceStartAmount, "eAlice's wethId balance should INCREASE");

        // 2. Alice starts a sale, selling 100 ALICE tokens for 100 WETH;
        changePrank(sm.addr);
        uint256 tokenAmount = 100e18;
        nayms.startTokenSale(alice.entityId, tokenAmount, tokenAmount);

        // 3. Now Alice owns 100 ALICE but they are locked;
        assertEq(nayms.internalBalanceOf(alice.entityId, alice.entityId), tokenAmount, "eAlice's wethId balance should INCREASE");

        // 4. Alice pays 100 WETH as a dividend;
        changePrank(alice);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")), 100 ether);

        // 5. Alice pays 100 WETH as a dividend;
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x2")), 100 ether);

        // 6. Bob buys all 100 ALICE from Alice. Here, during the transfer,
        //    Alice would have withdrawn the 200 WETH dividend owed to her,
        //    so her balance is 600 WETH (300 + 200 for dividend + 100 from Bob's purchase);
        changePrank(bob);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, depositAmount);

        (uint256 totalFees_, ) = nayms.calculateTradingFees(bob.entityId, wethId, alice.entityId, tokenAmount);

        nayms.externalDeposit(wethAddress, tokenAmount + totalFees_);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), tokenAmount + totalFees_, "eBob's wethId balance should INCREASE");
        nayms.executeLimitOffer(wethId, tokenAmount, alice.entityId, tokenAmount);
        assertEq(nayms.internalBalanceOf(bob.entityId, alice.entityId), tokenAmount, "eBob's eAlice balance should INCREASE");
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), eAliceStartAmount + tokenAmount, "eAlice's wethId balance should INCREASE");

        // 7. Bob transfers all 100 ALICE back to Alice;
        nayms.internalTransferFromEntity(alice.entityId, alice.entityId, tokenAmount);
        assertEq(nayms.internalBalanceOf(alice.entityId, alice.entityId), tokenAmount, "eAlice's eAlice balance should INCREASE");
        assertEq(nayms.internalBalanceOf(bob.entityId, alice.entityId), 0, "eAlice's eAlice balance should INCREASE");

        // 8. Alice pays 500 WETH as a dividend;
        changePrank(alice);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x3")), eAliceStartAmount);

        // 9. Alice tries to withdraw the 500 WETH dividend, should withdraw all 500 WETH
        nayms.withdrawDividend(alice.entityId, alice.entityId, wethId);
        assertEq(
            nayms.internalBalanceOf(alice.entityId, wethId),
            eAliceStartAmount + tokenAmount,
            "eAlice's current balance should increase by 500 WETH after receiving dividend."
        );
    }

    function test_WithdrawDividendBurn() public {
        // - Entity1 issues 100 tokens for $1 each
        // - Bob buys 2 tokens
        // - Charlie buys 3 tokens
        // - Entity1 issues a dividend for $100
        // - Entity1 burns its 95 tokens
        // - Bob's dividend is $2
        // - Bob withdraws dividend of $2
        // - Charlie's dividend is $3
        // - Charlie withdraws dividend of $3

        changePrank(sm);
        NaymsAccount memory aliceCC = makeNaymsAcc("Alice Comptroller");
        NaymsAccount memory aliceEM = makeNaymsAcc("Alice Entity Manager");
        aliceCC.entityId = alice.entityId;
        aliceEM.entityId = alice.entityId;

        NaymsAccount memory charlie = makeNaymsAcc("Charlie");
        hCreateEntity(charlie.entityId, charlie.id, entityWbtc, "charlie entitytest hash");

        changePrank(sa);
        nayms.assignRole(em.id, systemContext, LC.ROLE_ENTITY_MANAGER);
        nayms.assignRole(aliceEM.id, alice.entityId, LC.ROLE_ENTITY_MANAGER);
        changePrank(em);
        nayms.assignRole(aliceCC.id, alice.entityId, LC.ROLE_ENTITY_COMPTROLLER_COMBINED);
        changePrank(sm);
        nayms.setEntity(aliceCC.id, alice.entityId);
        nayms.setEntity(aliceEM.id, alice.entityId);

        changePrank(alice);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, 1000e18);
        nayms.externalDeposit(wethAddress, 1000e18); // to be used for dividend payments

        changePrank(bob);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, 1000e18);
        nayms.externalDeposit(wethAddress, 100e18);

        changePrank(charlie);
        writeTokenBalance(charlie.addr, naymsAddress, wethAddress, 1000e18);
        nayms.externalDeposit(wethAddress, 100e18);

        changePrank(sm);
        // now start token sale to create an offer
        nayms.enableEntityTokenization(alice.entityId, "ALICE", "Alice Token", 1);
        nayms.startTokenSale(alice.entityId, 100e18, 100e18);

        // bob buys 2 p tokens
        changePrank(bob);
        nayms.executeLimitOffer({ _sellToken: wethId, _sellAmount: 2e18, _buyToken: alice.entityId, _buyAmount: 2e18 });
        assertEq(nayms.internalBalanceOf(bob.entityId, alice.entityId), 2e18, "Bob's internal balance should increase".red());

        // charlie buys 3 p tokens
        changePrank(charlie);
        nayms.executeLimitOffer({ _sellToken: wethId, _sellAmount: 3e18, _buyToken: alice.entityId, _buyAmount: 3e18 });
        assertEq(nayms.internalBalanceOf(charlie.entityId, alice.entityId), 3e18, "Charlie's internal balance should increase".red());

        changePrank(aliceCC);
        nayms.payDividendFromEntity(makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")), 100e18);

        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 2e18, "Bob's withdrawable dividend should increase".red());
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 3e18, "Charlie's withdrawable dividend should increase".red());

        // burn 95 p tokens
        changePrank(aliceEM);
        nayms.cancelOffer(1);

        // Withdrawable dividend should still be the same as above.
        assertEq(nayms.getWithdrawableDividend(bob.entityId, alice.entityId, wethId), 2e18, "Bob's withdrawable dividend should not change".red());
        assertEq(nayms.getWithdrawableDividend(charlie.entityId, alice.entityId, wethId), 3e18, "Charlie's withdrawable dividend should not change".red());

        // Check that weth balances increases as expected after withdrawing dividends.
        changePrank(bob);
        uint256 balanceBefore = nayms.internalBalanceOf(bob.entityId, wethId);
        c.log(balanceBefore);
        nayms.withdrawDividend(bob.entityId, alice.entityId, wethId);
        c.log(nayms.internalBalanceOf(bob.entityId, wethId));
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), balanceBefore + 2e18, "Bob's internal balance should include the dividend".red());

        changePrank(charlie);
        balanceBefore = nayms.internalBalanceOf(charlie.entityId, wethId);
        nayms.withdrawDividend(charlie.entityId, alice.entityId, wethId);
        assertEq(nayms.internalBalanceOf(charlie.entityId, wethId), balanceBefore + 3e18, "Charlie's internal balance should include the dividend".red());
    }

    function testRebasingTokenInterest() public {
        vm.expectRevert(abi.encodeWithSelector(RebasingInterestNotInitialized.selector, wethId));
        changePrank(sm);
        nayms.distributeAccruedInterest(wethId, 1 ether, makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")));

        changePrank(alice.addr);
        writeTokenBalance(alice.addr, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 1 ether, "acc0EntityId wethId balance should INCREASE (mint)");

        changePrank(bob.addr);
        writeTokenBalance(bob.addr, naymsAddress, wethAddress, depositAmount);
        nayms.externalDeposit(wethAddress, 1 ether);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 1 ether, "bobEntityId wethId balance should INCREASE (mint)");

        vm.warp(2 weeks);

        assertEq(nayms.accruedInterest(wethId), 0, "Accrued interest should be zero");
        vm.mockCall(wethAddress, abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(4 ether));
        assertEq(nayms.accruedInterest(wethId), 2 ether, "Accrued interest should increase");

        changePrank(sm);
        vm.expectRevert(abi.encodeWithSelector(RebasingInterestInsufficient.selector, wethId, 5 ether, 2 ether));
        nayms.distributeAccruedInterest(wethId, 5 ether, makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")));

        nayms.distributeAccruedInterest(wethId, 2 ether, makeId(LC.OBJECT_TYPE_DIVIDEND, bytes20("0x1")));

        changePrank(alice.addr);
        nayms.withdrawDividend(alice.entityId, wethId, wethId);
        assertEq(nayms.internalBalanceOf(alice.entityId, wethId), 2 ether, "Alice's wethId balance should INCREASE (mint)".red());
        assertEq(nayms.getWithdrawableDividend(alice.entityId, wethId, wethId), 0, "alice's withdrawable divident should be zero".red());

        changePrank(bob.addr);
        nayms.withdrawDividend(bob.entityId, wethId, wethId);
        assertEq(nayms.internalBalanceOf(bob.entityId, wethId), 2 ether, "Bob's wethId balance should INCREASE (mint)".red());
        assertEq(nayms.getWithdrawableDividend(bob.entityId, wethId, wethId), 0, "bob's withdrawable divident should be zero".red());
    }

    // note withdrawAllDividends() will still succeed even if there are 0 dividends to be paid out,
    // while withdrawDividend() will revert
}
