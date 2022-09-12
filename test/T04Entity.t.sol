// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";

import { Entity, MarketInfo, SimplePolicy, Stakeholders } from "src/diamonds/nayms/AppStorage.sol";

import { LibACL } from "src/diamonds/nayms/libs/LibACL.sol";
import { LibTokenizedVault } from "src/diamonds/nayms/libs/LibTokenizedVault.sol";

import "src/utils/ECDSA.sol";

import { initEntity } from "test/T03SystemFacet.t.sol";

contract T04EntityTest is D03ProtocolDefaults {
    bytes32 internal wethId;

    bytes32 internal objectContext1 = "0xe1c";
    bytes32 internal policySponsorEntityId = "0xe1";
    bytes32 internal policyId1 = "0xC0FFEE";

    Stakeholders internal stakeholders;
    SimplePolicy internal simplePolicy;

    address internal account9;
    bytes32 internal account9Id;

    function setUp() public virtual override {
        super.setUp();

        wethId = LibHelpers._getIdForAddress(address(weth));

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

        bytes[] memory signatures = new bytes[](4);
        signatures[0] = initSig(0xACC1, policyId1);
        signatures[1] = initSig(0xACC2, policyId1);
        signatures[2] = initSig(0xACC3, policyId1);
        signatures[3] = initSig(0xACC4, policyId1);

        stakeholders = Stakeholders(roles, entityIds, signatures);

        bytes32[] memory commissionReceivers = new bytes32[](3);
        commissionReceivers[0] = DEFAULT_UNDERWRITER_ENTITY_ID;
        commissionReceivers[1] = DEFAULT_BROKER_ENTITY_ID;
        commissionReceivers[2] = DEFAULT_CAPITAL_PROVIDER_ENTITY_ID;

        uint256[] memory commissions = new uint256[](3);
        commissions[0] = 10;
        commissions[1] = 10;
        commissions[2] = 10;

        simplePolicy.startDate = 1000;
        simplePolicy.maturationDate = 10000;
        simplePolicy.asset = wethId;
        simplePolicy.commissionReceivers = commissionReceivers;
        simplePolicy.commissionBasisPoints = commissions;

        account9 = vm.addr(0xACC9);
        account9Id = LibHelpers._getIdForAddress(account9);
    }

    function initSig(uint256 account, bytes32 policyId) internal returns (bytes memory sig_) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(account, ECDSA.toEthSignedMessageHash(policyId));
        sig_ = abi.encodePacked(r, s, v);
    }

    function testTokenSale() public {
        // whitelist underlying token
        // nayms.whitelistExternalToken(address(weth));
        nayms.addSupportedExternalToken(address(weth));

        bytes32 entityId1 = "0xe1";

        uint256 sellAmount = 100;
        uint256 sellAtPrice = 100;

        Entity memory entity1 = initEntity(weth, 500, 1000, 0, false);
        nayms.createEntity(entityId1, objectContext1, entity1, "entity test hash");

        assertEq(nayms.getLastOfferId(), 0);

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

    function testSimplePolicy() public {
        vm.expectRevert("object already exists");
        nayms.createEntity(0, objectContext1, initEntity(weth, 500, 10000, 10000, false), "entity test hash");

        nayms.createEntity(policySponsorEntityId, objectContext1, initEntity(weth, 500, 10000, 0, false), "entity test hash");

        vm.expectRevert("simple policy creation disabled");
        nayms.createSimplePolicy(policyId1, policySponsorEntityId, stakeholders, simplePolicy, "simple policy test");

        vm.expectRevert("collateral ratio should be 1 to 1000");
        nayms.updateEntity(policySponsorEntityId, initEntity(weth, 0, 1000, 0, true));

        // nayms.updateEntity(policySponsorEntityId, initEntity(weth, 500, 0, 0, true));

        nayms.updateEntity(policySponsorEntityId, initEntity(weth, 1000, 1000, 0, true));

        // test limit
        vm.expectRevert("limit not > 0");
        nayms.createSimplePolicy(policyId1, policySponsorEntityId, stakeholders, simplePolicy, "simple policy test");

        simplePolicy.limit = 10000;

        // kp note todo: for the following test below, some notes -
        // nayms.createSimplePolicy currently checks if msg.sender (in this case account9) is a system manager in the system context
        // todo - is that the desired check?
        //
        // test entity admin constraint
        vm.expectRevert("not a system manager");
        vm.prank(account9);
        nayms.createSimplePolicy(policyId1, policySponsorEntityId, stakeholders, simplePolicy, "simple policy test");
        vm.stopPrank();

        nayms.assignRole(account0Id, policySponsorEntityId, LibConstants.ROLE_ENTITY_ADMIN);
        assertTrue(nayms.isInGroup(account0Id, policySponsorEntityId, LibConstants.GROUP_ENTITY_ADMINS));

        // fail on 0 collateral ratio note: an entity can no longer be created when its collateral ratio is == 0

        // test collateral ratio constraint
        nayms.updateEntity(policySponsorEntityId, initEntity(weth, 500, 30000, 0, true));
        vm.expectRevert("not enough capital");
        nayms.createSimplePolicy(policyId1, policySponsorEntityId, stakeholders, simplePolicy, "simple policy test");

        // mint weth for test account
        nayms.updateEntity(policySponsorEntityId, initEntity(weth, 500, 20000, 0, true));

        // fund the policy sponsor entity
        weth.approve(address(nayms), 10000);
        writeTokenBalance(account0, address(nayms), address(weth), 10000);
        assertEq(weth.balanceOf(account0), 10000);
        nayms.externalDeposit(policySponsorEntityId, address(weth), 10000);
        assertEq(nayms.internalBalanceOf(policySponsorEntityId, wethId), 10000);

        nayms.createSimplePolicy(policyId1, policySponsorEntityId, stakeholders, simplePolicy, "simple policy test");

        // todo: improve this error message when a premium is being created with the same premium ID
        vm.expectRevert("object already exists");
        nayms.createSimplePolicy(policyId1, policySponsorEntityId, stakeholders, simplePolicy, "simple policy test");

        vm.expectRevert("invalid premium amount");
        nayms.paySimplePremium(policyId1, 0);

        // fund the insured party entity
        weth.approve(address(nayms), 10000);
        writeTokenBalance(account0, address(nayms), address(weth), 10000);
        assertEq(weth.balanceOf(account0), 10000);
        nayms.externalDeposit(DEFAULT_INSURED_PARTY_ENTITY_ID, address(weth), 10000);
        assertEq(nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, wethId), 10000);

        // test commissions
        {
            assertEq(simplePolicy.premiumsPaid, 0);

            uint256 premiumAmount = 1000;
            uint256 balanceBeforePremium = nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, wethId);

            vm.startPrank(signer4);
            nayms.paySimplePremium(policyId1, premiumAmount);
            vm.stopPrank();

            uint256 netPremiumAmount = premiumAmount;
            for (uint256 i = 0; i < simplePolicy.commissionReceivers.length; ++i) {
                uint256 commission = (premiumAmount * simplePolicy.commissionBasisPoints[i]) / 1000;
                netPremiumAmount -= commission;
                assertEq(nayms.internalBalanceOf(simplePolicy.commissionReceivers[i], simplePolicy.asset), commission);
            }
            simplePolicy = nayms.getSimplePolicyInfo(policyId1);
            assertEq(simplePolicy.premiumsPaid, premiumAmount);
            assertEq(nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, wethId), balanceBeforePremium - premiumAmount);
        }

        vm.prank(account9);
        vm.expectRevert("not a system manager");
        nayms.paySimpleClaim(policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 1000);
        vm.stopPrank();

        // setup insured party account
        nayms.assignRole(LibHelpers._getIdForAddress(signer4), DEFAULT_INSURED_PARTY_ENTITY_ID, LibConstants.ROLE_INSURED_PARTY);
        assertTrue(nayms.isInGroup(LibHelpers._getIdForAddress(signer4), DEFAULT_INSURED_PARTY_ENTITY_ID, LibConstants.GROUP_INSURED_PARTIES));
        nayms.setEntity(LibHelpers._getIdForAddress(signer4), DEFAULT_INSURED_PARTY_ENTITY_ID);

        vm.expectRevert("exceeds policy limit");
        nayms.paySimpleClaim(policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, 10001);

        uint256 claimAmount = 1000;
        uint256 balanceBeforeClaim = nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, simplePolicy.asset);
        simplePolicy = nayms.getSimplePolicyInfo(policyId1);
        assertEq(simplePolicy.claimsPaid, 0);

        nayms.paySimpleClaim(policyId1, DEFAULT_INSURED_PARTY_ENTITY_ID, claimAmount);

        simplePolicy = nayms.getSimplePolicyInfo(policyId1);
        assertEq(simplePolicy.claimsPaid, 1000);
        assertEq(nayms.internalBalanceOf(DEFAULT_INSURED_PARTY_ENTITY_ID, simplePolicy.asset), balanceBeforeClaim + claimAmount);
    }
}
