// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Vm } from "forge-std/Vm.sol";

import { D03ProtocolDefaults, c, LC } from "./defaults/D03ProtocolDefaults.sol";
import { Entity } from "src/shared/FreeStructs.sol";
import { ERC20Wrapper } from "../src/utils/ERC20Wrapper.sol";

contract T05TokenWrapper is D03ProtocolDefaults {
    bytes32 internal entityId1 = makeId(LC.OBJECT_TYPE_ENTITY, address(bytes20("0xe1")));
    bytes32 internal entityId2 = makeId(LC.OBJECT_TYPE_ENTITY, address(bytes20("0xe2")));

    string internal testSymbol = "E1";
    string internal testName = "Entity 1 Token";

    uint256 internal tokenAmount = 1_000 ether;

    bytes32 internal constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function setUp() public {}

    function testOnlyDiamondCanWrapTokens() public {
        vm.expectRevert();
        new ERC20Wrapper(entityId1);
    }

    function testWrapEntityToken() public {
        changePrank(sm.addr);
        nayms.createEntity(entityId1, account0Id, initEntity(wethId, 5_000, 30_000, true), "test");
        nayms.createEntity(entityId2, signer2Id, initEntity(wethId, 5_000, 30_000, true), "test");

        bytes32 eSigner2 = nayms.getEntity(signer2Id);
        nayms.assignRole(eSigner2, eSigner2, LC.ROLE_ENTITY_CP);

        changePrank(sa.addr);
        vm.expectRevert("must be tokenizable");
        nayms.wrapToken(entityId1);

        changePrank(sm.addr);
        nayms.enableEntityTokenization(entityId1, testSymbol, testName);
        nayms.startTokenSale(entityId1, tokenAmount, tokenAmount);

        changePrank(sa.addr);

        vm.recordLogs();

        nayms.wrapToken(entityId1);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "TokenWrapped: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("TokenWrapped(bytes32,address)"), "TokenWrapped: Invalid event signature");
        assertEq(entries[0].topics[1], entityId1, "TokenWrapped: incorrect tokenID"); // assert entity token
        address loggedWrapperAddress = abi.decode(entries[0].data, (address));

        (, , string memory storedSymbol, string memory storedName, address storedAddress) = nayms.getObjectMeta(entityId1);

        assertEq(storedSymbol, testSymbol, "token symbols should match");
        assertEq(storedName, testName, "token name should match");
        assertEq(storedAddress, loggedWrapperAddress, "token wrapper addresses should match");

        vm.expectRevert("must not be wrapped already");
        nayms.wrapToken(entityId1);

        ERC20Wrapper wrapper = ERC20Wrapper(storedAddress);

        assertEq(storedSymbol, wrapper.symbol(), "token symbol should match");
        assertEq(storedName, wrapper.name(), "token name  should match");
        assertEq(wrapper.decimals(), 18, "token decimals should match");
        assertEq(wrapper.totalSupply(), nayms.internalTokenSupply(entityId1), "token supply should match");
        assertEq(wrapper.totalSupply(), tokenAmount, "token supply should match sale amount");

        // fund signer2
        changePrank(signer2);
        (uint256 totalFees_, ) = nayms.calculateTradingFees(entityId2, wethId, entityId1, tokenAmount);
        uint256 amountWithFees = tokenAmount + totalFees_;
        writeTokenBalance(signer2, naymsAddress, wethAddress, amountWithFees);
        nayms.externalDeposit(wethAddress, amountWithFees);

        // signer2 buy p-tokens
        nayms.executeLimitOffer(wethId, tokenAmount, entityId1, tokenAmount);

        // signer2 transfer p-tokens to account0
        nayms.internalTransferFromEntity(account0Id, entityId1, tokenAmount);
        assertEq(wrapper.balanceOf(account0), nayms.internalBalanceOf(account0Id, entityId1), "wrapper balance should match diamond");
    }

    function testWrapperTransfersAndAllowance() public {
        testWrapEntityToken();
        (, , , , address wrapperAddress) = nayms.getObjectMeta(entityId1);
        ERC20Wrapper wrapper = ERC20Wrapper(wrapperAddress);

        changePrank(account0);
        wrapper.transfer(signer1, tokenAmount);

        assertEq(wrapper.balanceOf(signer1), tokenAmount, "signer1 balance should increase");
        assertEq(wrapper.allowance(signer1, account0), 0, "allowance should be 0");

        changePrank(signer1);
        wrapper.approve(account0, tokenAmount);
        vm.stopPrank();

        assertEq(wrapper.allowance(signer1, account0), tokenAmount, "allowance should have increased");

        vm.expectRevert();
        wrapper.transferFrom(signer1, account0, 0);

        vm.expectRevert("not enough allowance");
        wrapper.transferFrom(signer1, account0, tokenAmount * 2);

        wrapper.transferFrom(signer1, account0, tokenAmount);
        assertEq(wrapper.balanceOf(account0), tokenAmount, "account0 balance should increase");

        assertEq(wrapper.allowance(signer1, account0), 0, "allowance should have decreased");

        vm.startPrank(signer1);
        wrapper.increaseAllowance(account0, type(uint256).max);
        assertEq(wrapper.allowance(signer1, account0), type(uint256).max, "allowance should have increased");

        vm.expectRevert("ERC20: allowance overflow");
        wrapper.increaseAllowance(account0, 1);
        vm.stopPrank();

        vm.startPrank(signer1);
        wrapper.decreaseAllowance(account0, type(uint256).max);
        assertEq(wrapper.allowance(signer1, account0), 0, "allowance should have decreased");

        vm.expectRevert("ERC20: decreased allowance below zero");
        wrapper.decreaseAllowance(account0, 1);
        vm.stopPrank();
    }

    function testPermit() public {
        testWrapEntityToken();
        (, , , , address wrapperAddress) = nayms.getObjectMeta(entityId1);
        ERC20Wrapper token = ERC20Wrapper(wrapperAddress);

        uint256 privateKey = 0xBEEF;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1 ether, 0, block.timestamp))))
        );

        token.permit(owner, address(0xCAFE), 1 ether, block.timestamp, v, r, s);

        assertEq(token.allowance(owner, address(0xCAFE)), 1e18);
        assertEq(token.nonces(owner), 1);
    }
}
