// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { Vm } from "forge-std/Vm.sol";

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { Entity } from "src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms, IDiamondCut } from "src/diamonds/nayms/INayms.sol";
import { ERC20Wrapper } from "../src/erc20/ERC20Wrapper.sol";

contract T05TokenWrapper is D03ProtocolDefaults {
    bytes32 internal wethId;
    bytes32 internal entityId1 = "0xe1";

    string internal testSymbol = "E1";
    string internal testName = "Entity 1 Token";

    function setUp() public virtual override {
        super.setUp();

        wethId = LibHelpers._getIdForAddress(wethAddress);
    }

    function testOnlyDiamondCanWrapTokens() public {
        vm.expectRevert();
        new ERC20Wrapper(entityId1);
    }

    function testWrapEntityToken() public {
        nayms.createEntity(entityId1, account0Id, initEntity(weth, 5000, 30000, 0, true), "test");
        nayms.enableEntityTokenization(entityId1, testSymbol, testName);

        uint256 saleAmount = 1_000 ether;
        uint256 salePrice = 1_000 ether;
        nayms.startTokenSale(entityId1, saleAmount, salePrice);

        vm.recordLogs();

        nayms.wrapToken(entityId1);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries[0].topics.length, 2, "TokenWrapped: topics length incorrect");
        assertEq(entries[0].topics[0], keccak256("TokenWrapped(bytes32,address)"), "TokenWrapped: Invalid event signature");
        assertEq(entries[0].topics[1], entityId1, "TokenWrapped: incorrect tokenID"); // assert entity token
        address loggedWrapperAddress = abi.decode(entries[0].data, (address));

        (, , bytes32 tokenSymbol, bytes32 tokenName, address tokenWrapper) = nayms.getObjectMeta(entityId1);

        assertEq(tokenSymbol, LibHelpers._stringToBytes32(testSymbol), "token symbols should match");
        assertEq(tokenName, LibHelpers._stringToBytes32(testName), "token name should match");
        assertEq(tokenWrapper, loggedWrapperAddress, "token wrapper addresses should match");
    }
}
