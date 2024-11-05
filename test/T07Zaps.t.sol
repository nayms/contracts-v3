// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { D03ProtocolDefaults, c, LC, LibHelpers, StdStyle } from "./defaults/D03ProtocolDefaults.sol";
import { DummyToken } from "test/utils/DummyToken.sol";
import { StakingConfig, PermitSignature } from "src/shared/FreeStructs.sol";

contract ZapFacetTest is D03ProtocolDefaults {
    using LibHelpers for address;
    using StdStyle for *;

    DummyToken internal naymToken = new DummyToken();
    DummyToken internal rewardToken;

    NaymsAccount bob = makeNaymsAcc("Bob");

    NaymsAccount nlf = makeNaymsAcc(LC.NLF_IDENTIFIER);

    uint64 private constant SCALE_FACTOR = 1_000_000; // 6 digits because USDC
    uint64 private constant A = (15 * SCALE_FACTOR) / 100;
    uint64 private constant R = (85 * SCALE_FACTOR) / 100;
    uint64 private constant I = 30 days;
    bytes32 NAYM_ID = address(naymToken)._getIdForAddress();
    function initStaking(uint256 initDate) internal {
        StakingConfig memory config = StakingConfig({
            tokenId: NAYM_ID,
            initDate: initDate,
            a: A, // Amplification factor
            r: R, // Boost decay factor
            divider: SCALE_FACTOR,
            interval: I // Amount of time per interval in seconds
        });

        startPrank(sa);
        nayms.initStaking(nlf.entityId, config);
        vm.stopPrank();
    }

    uint256 internal stakeAmount = 1e18;
    uint256 internal unstakeAmount = 1e18;

    function setUp() public {
        naymToken.mint(bob.addr, stakeAmount);

        startPrank(sa);
        nayms.addSupportedExternalToken(address(naymToken), 100);

        vm.startPrank(sm.addr);
        hCreateEntity(bob.entityId, bob, entity, "Bob data");
        hCreateEntity(nlf.entityId, nlf, entity, "NLF");
    }

    function test_zapStake_Success() public {
        initStaking(block.timestamp + 1 + 7 days);

        // Prepare permit data
        uint256 deadline = block.timestamp;

        // Create permit digest
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                naymToken.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(naymToken.PERMIT_TYPEHASH(), bob.addr, address(nayms), stakeAmount, naymToken.nonces(owner), deadline))
            )
        );

        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bob.pk, digest);

        startPrank(bob);

        PermitSignature memory permitSignature = PermitSignature({ deadline: deadline, v: v, r: r, s: s });

        vm.expectRevert("zapStake: invalid ERC20 token");
        nayms.zapStake(address(111), nlf.entityId, stakeAmount, stakeAmount, permitSignature);

        nayms.zapStake(address(naymToken), nlf.entityId, stakeAmount, stakeAmount, permitSignature);

        (uint256 staked, ) = nayms.getStakingAmounts(bob.entityId, nlf.entityId);

        assertEq(stakeAmount, staked, "bob's stake amount should increase");
    }

    function test_zapOrder_Success() public {
        changePrank(sm.addr);
        nayms.enableEntityTokenization(bob.entityId, "e1token", "e1token", 1e6);

        // Selling bob p tokens for weth
        nayms.startTokenSale(bob.entityId, 1 ether, 1 ether);

        deal(address(weth), bob.addr, 10 ether);

        // Prepare permit data
        uint256 deadline = block.timestamp;
        bytes32 PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        uint256 nonce = weth.nonces(bob.addr);
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, bob.addr, address(nayms), 10 ether, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", weth.DOMAIN_SEPARATOR(), structHash));
        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bob.pk, digest);
        PermitSignature memory permitSignature = PermitSignature({ deadline: deadline, v: v, r: r, s: s });

        startPrank(bob);

        vm.expectRevert("zapOrder: invalid ERC20 token");
        nayms.zapOrder(address(111), 10 ether, wethId, 1 ether, bob.entityId, 1 ether, permitSignature);

        // Call zapOrder
        // Caller should ensure they deposit enough to cover order fees.
        nayms.zapOrder(address(weth), 10 ether, wethId, 1 ether, bob.entityId, 1 ether, permitSignature);

        assertEq(nayms.internalBalanceOf(bob.entityId, bob.entityId), 1 ether, "bob should've purchased 1e18 bob p tokens");
    }
}
