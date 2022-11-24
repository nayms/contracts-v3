// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// solhint-disable func-name-mixedcase

import { IERC20 } from "./IERC20.sol";
import { INayms } from "../diamonds/nayms/INayms.sol";
import { LibHelpers } from "../diamonds/nayms/libs/LibHelpers.sol";
import { LibConstants } from "../diamonds/nayms/libs/LibConstants.sol";

import { console2 } from "forge-std/console2.sol";

contract ERC20Wrapper is IERC20 {
    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/
    bytes32 internal tokenId;
    INayms internal nayms;
    mapping(address => mapping(address => uint256)) public allowances;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    constructor(bytes32 _tokenId) {
        // ensure only diamond can instantiate this
        nayms = INayms(msg.sender);

        require(nayms.isObjectTokenizable(_tokenId), "must be tokenizable");

        tokenId = _tokenId;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function name() external view returns (string memory) {
        (, , , bytes32 nameBytes32, ) = nayms.getObjectMeta(tokenId);
        return LibHelpers._bytes32ToString(nameBytes32);
    }

    function symbol() external view returns (string memory) {
        (, , bytes32 symbolBytes32, , ) = nayms.getObjectMeta(tokenId);
        return LibHelpers._bytes32ToString(symbolBytes32);
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return nayms.internalTokenSupply(tokenId);
    }

    function balanceOf(address who) external view returns (uint256) {
        return nayms.internalBalanceOf(LibHelpers._getIdForAddress(who), tokenId);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        bytes32 fromId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 toId = LibHelpers._getIdForAddress(to);
        nayms.wrapperInternalTransferFrom(fromId, toId, tokenId, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowances[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (value == 0) {
            revert();
        }
        uint256 allowed = allowances[from][msg.sender]; // Saves gas for limited approvals.
        require(allowed >= value, "not enough allowance");

        if (allowed != type(uint256).max) allowances[from][msg.sender] = allowed - value;

        bytes32 fromId = LibHelpers._getIdForAddress(from);
        bytes32 toId = LibHelpers._getIdForAddress(to);
        nayms.wrapperInternalTransferFrom(fromId, toId, tokenId, value);

        emit Transfer(from, to, value);
        return true;
    }

    // refer to https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol#L116
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowances[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(LibHelpers._bytes32ToBytes(tokenId)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}
