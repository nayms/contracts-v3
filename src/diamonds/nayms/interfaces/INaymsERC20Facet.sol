// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/**
 * @title Nayms Token
 * @notice External facing representation of the NAYM token
 * @dev ERC20 compliant Nayms' token
 */
interface INaymsERC20Facet {
    /**
     * @notice Get the token name
     * @return token name
     */
    function name() external pure returns (string memory);

    /**
     * @notice Get the token symbol
     * @return token symbol
     */
    function symbol() external pure returns (string memory);

    /**
     * @notice Get the number of decimals for the token
     * @return number of decimals
     */
    function decimals() external pure returns (uint8);

    /**
     * @notice Get the total supply of token
     * @return total number of tokens in circulation
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Get token balance for `_owner`
     * @param _owner token owner
     * @return balance holding balance
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `_value` of tokens to `_to`
     * @param _to address to transfer to
     * @param _value amount to transfer
     * @return success true if transfer was successful, false otherwise
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice Transfer `_value` of tokens from `_from` to `_to`
     * @param _from address to transfer tokens from
     * @param _to address to transfer tokens to
     * @param _value amount to transfer
     * @return success true if transfer was successful, false otherwise
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /**
     * @notice Approve spending of `_value` to `_spender`
     * @param _spender address to approve spending
     * @param _value amount to approve
     * @return success true if approval was successful, false otherwise
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice Increase allowance for `_value` to `_spender`
     * @param _spender address to approve spending
     * @param _value amount to approve
     * @return success true if approval was successful, false otherwise
     */
    function increaseAllowance(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice Decrease allowance for `_value` to `_spender`
     * @param _spender address to approve spending
     * @param _value amount to approve
     * @return success true if approval was successful, false otherwise
     */
    function decreaseAllowance(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice Remaining allowance from `_owner` to `_spender`
     * @param _owner address that approved spending
     * @param _spender address that is approved for spending
     * @return remaining_ remaining unspent allowance
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining_);

    /**
     * @notice Gasless allowance approval
     * @param owner address that approves spending
     * @param spender address that is approved for spending
     * @param value approved amount
     * @param deadline permit deadline
     * @param v v value
     * @param r r value
     * @param _s s value
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 _s
    ) external;

    /**
     * @notice Domain separator
     @return domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Mint tokens
     */
    function mint() external;

    /**
     * @notice Mint tokens to `_user`
     * @param _user addres to mint tokens to
     */
    function mintTo(address _user) external;
}
