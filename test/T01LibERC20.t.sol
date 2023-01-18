// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults, console2 } from "./defaults/D03ProtocolDefaults.sol";
import { DummyToken } from "./utils/DummyToken.sol";
import { LibERC20Fixture } from "./fixtures/LibERC20Fixture.sol";
import { IDiamondCut } from "src/diamonds/nayms/INayms.sol";

contract T01LibERC20 is D03ProtocolDefaults {
    DummyToken private token;
    address private tokenAddress;

    LibERC20Fixture private fixture;
    address private fixtureAddress;

    function setUp() public virtual override {
        super.setUp();

        token = new DummyToken();
        tokenAddress = address(token);

        fixture = new LibERC20Fixture();
        fixtureAddress = address(fixture);

        bytes4[] memory funcSelectors = new bytes4[](2);
        funcSelectors[0] = fixture.decimals.selector;
        funcSelectors[1] = fixture.balanceOf.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(fixture), action: IDiamondCut.FacetCutAction.Add, functionSelectors: funcSelectors });

        nayms.diamondCut(cut, address(0), "");
    }

    function getDecimals(address tokenAddress) internal returns (uint8) {
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(fixture.decimals.selector, tokenAddress));
        require(success, "Should get token decimals via library fixture");
        return abi.decode(result, (uint8));
    }

    function getBalanceOf(address _token, address _who) internal returns (uint256) {
        (bool success, bytes memory result) = address(nayms).call(abi.encodeWithSelector(fixture.balanceOf.selector, _token, _who));
        require(success, "Should get holders balance via library fixture");
        return abi.decode(result, (uint256));
    }

    function testBalanceOf() public {
        token.mint(fixtureAddress, 100);
        assertEq(getBalanceOf(tokenAddress, fixtureAddress), 100, "invalid balance of");
    }

    function testTransfer() public {
        token.mint(fixtureAddress, 100);
        assertEq(token.balanceOf(fixtureAddress), 100);
        assertEq(token.balanceOf(account0), 0);

        vm.expectRevert("LibERC20: ERC20 token address has no code");
        fixture.transfer(address(0), account0, 1);

        // failed transfer
        vm.expectRevert("not enough balance");
        fixture.transfer(tokenAddress, account0, 101);

        // failed transfer of 0
        vm.expectRevert("LibERC20: transfer or transferFrom returned false");
        fixture.transfer(tokenAddress, account0, 0);

        // successful transfer
        fixture.transfer(tokenAddress, account0, 100);

        assertEq(token.balanceOf(fixtureAddress), 0);
        assertEq(token.balanceOf(account0), 100);
    }

    function testTransferFrom() public {
        token.mint(signer1, 100);
        assertEq(token.balanceOf(signer1), 100);
        assertEq(token.balanceOf(account0), 0);

        vm.prank(signer1);
        token.approve(fixtureAddress, 200);
        assertEq(token.allowance(signer1, fixtureAddress), 200);

        vm.expectRevert("LibERC20: ERC20 token address has no code");
        fixture.transferFrom(address(0), signer1, account0, 1);

        // not enough allowance
        vm.expectRevert("not enough allowance");
        fixture.transferFrom(tokenAddress, account0, signer1, 201);

        // not enough balance
        vm.expectRevert("not enough balance");
        fixture.transferFrom(tokenAddress, signer1, account0, 101);

        // failed transfer of 0 reverts with empty string
        vm.expectRevert("LibERC20: transfer or transferFrom reverted");
        fixture.transferFrom(tokenAddress, signer1, account0, 0);

        // successful transfer
        fixture.transferFrom(tokenAddress, signer1, account0, 100);

        assertEq(token.balanceOf(signer1), 0);
        assertEq(token.balanceOf(account0), 100);
    }

    function testDecimals() public {
        assertEq(getDecimals(tokenAddress), 18, "invalid decimals");
    }
}
