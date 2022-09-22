// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface INaymsERC20Facet {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function increaseAllowance(address _spender, uint256 _value) external returns (bool success);

    function decreaseAllowance(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining_);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 _s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function mint() external;

    function mintTo(address _user) external;
}
