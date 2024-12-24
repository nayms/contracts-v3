// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC20 } from "src/interfaces/IERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DummyToken is IERC20 {
    using ECDSA for bytes32;

    string public name = "Dummy";
    string public symbol = "DUM";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // EIP-2612 permit state variables
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6d47c92dbe9aa29a8e9e38d25f3f54ab645e5df690ddf0d3e2a24ec2445a44f0;
    mapping(address => uint256) public nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x8b73e7bb5ba7313e92d4a46294e43b9c1bafabf1adbe7b6f4bdfd44c38a7e6d4,
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "not enough balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, "not enough allowance");
        require(balanceOf[from] >= value, "not enough balance");
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) external {
        balanceOf[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice Approves tokens via signature, as per EIP-2612
     * @param owner The token owner's address
     * @param spender The spender's address
     * @param value The amount to approve
     * @param deadline The deadline timestamp by which the permit must be used
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(block.timestamp <= deadline, "permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        address recoveredAddress = digest.recover(v, r, s);
        require(recoveredAddress == owner, "permit: invalid signature");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}
