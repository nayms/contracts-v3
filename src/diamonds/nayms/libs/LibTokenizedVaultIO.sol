// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibERC20 } from "../../../erc20/LibERC20.sol";
import { ExternalDepositAmountCannotBeZero, ExternalWithdrawAmountCannotBeZero } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

/**
 * @dev Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 * https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
library LibTokenizedVaultIO {
    event NaymsVaultTokenTransfer(address operator, bytes32 indexed from, bytes32 indexed to, uint256 amount);

    event ExternalDeposit();

    function _externalDeposit(
        bytes32 _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            revert ExternalDepositAmountCannotBeZero();
        }

        bytes32 internalTokenId = LibHelpers._getIdForAddress(_externalTokenAddress);

        // Funds are transferred to entity
        LibTokenizedVault._internalMint(_receiverId, internalTokenId, _amount);

        LibERC20.transferFrom(_externalTokenAddress, msg.sender, address(this), _amount);
    }

    function _externalWithdraw(
        bytes32 _entityId,
        address _receiver,
        address _externalTokenAddress,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            revert ExternalWithdrawAmountCannotBeZero();
        }

        // withdraw from the user's entity
        bytes32 internalTokenId = LibHelpers._getIdForAddress(_externalTokenAddress);

        // burn internal token
        LibTokenizedVault._internalBurn(_entityId, internalTokenId, _amount);

        // transfer AFTER burn
        LibERC20.transfer(address(_externalTokenAddress), _receiver, _amount);
    }
}
