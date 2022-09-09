// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { D03ProtocolDefaults, console2, LibAdmin, LibConstants, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";

import { Entity, FeeRatio, MarketInfo } from "src/diamonds/nayms/AppStorage.sol";

contract T03TokenizedVaultTest is D03ProtocolDefaults {
    bytes32 internal nWETH;

    function setUp() public virtual override {
        super.setUp();
        nWETH = LibHelpers._getIdForAddress(address(weth));
    }

    function testSingleExternalDeposit() public {
        // create an entity (already done in D03 defaults)
        // DEFAULT_UNDERWRITER_ENTITY_ID is a valid entity associated with default signer1

        uint256 amount = 100;
        address assetAddress = address(weth);
        writeTokenBalance(account0, address(nayms), assetAddress, amount);

        nayms.externalDeposit(DEFAULT_ACCOUNT0_ENTITY_ID, assetAddress, amount);

        // get balance of weth
        assertEq(weth.balanceOf(account0), 0);
        assertEq(weth.balanceOf(address(nayms)), amount);

        // get balance of object
        assertEq(nayms.internalBalanceOf(DEFAULT_ACCOUNT0_ENTITY_ID, nWETH), amount);

        // get total supply of underlying token
        assertEq(nayms.internalTokenSupply(nWETH), amount);
    }

    function testSingleInternalTransfer() public {
        testSingleExternalDeposit();
        // todo
    }

    // function testFuzzExternalDeposit(
    //     bytes32 account0Id,
    //     bytes32 account0Id,
    //     uint256 depositAmount
    // ) public {
    //     Entity memory entityInfo;
    //     // LibConstants.ROLE_UNDERWRITER
    //     nayms.createEntity(account0Id, objectContext1, entityInfo, "entity test hash");

    //     // if account0Id == account0Id, createEntity will revert
    //     vm.assume(account0Id != account0Id);

    //     nayms.createEntity(account0Id, objectContext1, entityInfo, "entity test hash");

    //     weth.approve(address(nayms), depositAmount);
    //     address assetAddress = address(weth);
    //     writeTokenBalance(account0, assetAddress, depositAmount);
    //     assertEq(weth.balanceOf(account0), depositAmount);

    //     if (account0Id == "") {
    //         vm.expectRevert("MultiToken: mint to zero address");
    //         nayms.externalDeposit(account0Id, assetAddress, depositAmount);
    //     } else {
    //         nayms.externalDeposit(account0Id, assetAddress, depositAmount);
    //     }

    //     // get balance of weth
    //     assertEq(weth.balanceOf(account0), 0);
    //     assertEq(weth.balanceOf(address(nayms)), depositAmount);

    //     // get balance of object
    //     assertEq(nayms.internalBalanceOf(account0Id, nWETH), depositAmount);

    //     // get total supply of naymsVaultToken
    //     assertEq(nayms.internalTokenSupply(nWETH), depositAmount);
    // }

    function testSingleExternalWithdraw() public {
        testSingleExternalDeposit();

        weth.approve(address(nayms), 100);

        assertEq(weth.allowance(account0, address(nayms)), 100);
        assertEq(weth.balanceOf(account0), 0);
        assertEq(weth.balanceOf(address(nayms)), 100);
        assertEq(weth.balanceOf(address(msg.sender)), 0);

        // vm.prank(signer1);
        // send to self
        nayms.externalWithdrawFromEntity(DEFAULT_ACCOUNT0_ENTITY_ID, account0, address(weth), 100);
    }
}
