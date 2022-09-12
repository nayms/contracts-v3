// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, Modifiers, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibConstants } from "../libs/LibConstants.sol";

/// @notice https://github.com/aavegotchi/aavegotchi-contracts/blob/master/contracts/GHST/facets/GHSTFacet.sol

contract NaymsERC20Facet is Modifiers {
    uint256 private constant MAX_UINT = type(uint256).max;

    uint256 private immutable INITIAL_CHAIN_ID = block.chainid;

    bytes32 private immutable INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function name() public pure returns (string memory) {
        return "Nayms Token";
    }

    function symbol() external pure returns (string memory) {
        return "NAYM";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return s.totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        balance = s.balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        uint256 frombalances = s.balances[msg.sender];
        require(frombalances >= _value, "NAYM: Not enough NAYM to transfer");
        s.balances[msg.sender] = frombalances - _value;
        s.balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success) {
        uint256 fromBalance = s.balances[_from];
        if (msg.sender != _from && s.approvedContractIndexes[msg.sender] != 0) {
            uint256 l_allowance = s.allowance[_from][msg.sender];
            require(l_allowance >= _value, "NAYM: Not allowed to transfer");
            if (l_allowance != MAX_UINT) {
                s.allowance[_from][msg.sender] = l_allowance - _value;
                emit Approval(_from, msg.sender, l_allowance - _value);
            }
        }
        require(fromBalance >= _value, "NAYM: Not enough NAYM to transfer");
        s.balances[_from] = fromBalance - _value;
        s.balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        s.allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function increaseAllowance(address _spender, uint256 _value) external returns (bool success) {
        uint256 l_allowance = s.allowance[msg.sender][_spender];
        uint256 newAllowance = l_allowance + _value;
        require(newAllowance >= l_allowance, "NAYMFacet: Allowance increase overflowed");
        s.allowance[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        success = true;
    }

    function decreaseAllowance(address _spender, uint256 _value) external returns (bool success) {
        uint256 l_allowance = s.allowance[msg.sender][_spender];
        require(l_allowance >= _value, "NAYMFacet: Allowance decreased below 0");
        l_allowance -= _value;
        s.allowance[msg.sender][_spender] = l_allowance;
        emit Approval(msg.sender, _spender, l_allowance);
        success = true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining_) {
        remaining_ = s.allowance[_owner][_spender];
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 _s
    ) external virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        s.nonces[owner]++;
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                            owner,
                            spender,
                            value,
                            s.nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, _s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            s.allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    // solhint-disable func-name-mixedcase
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    // todo: don't do this.name() to retrive name of token
    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name())),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function mint() external {
        uint256 amount = 10000000e18;
        s.balances[msg.sender] += amount;
        s.totalSupply += uint96(amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function mintTo(address _user) external {
        uint256 amount = 10000000e18;
        s.balances[_user] += amount;
        s.totalSupply += uint96(amount);
        emit Transfer(address(0), _user, amount);
    }
}
