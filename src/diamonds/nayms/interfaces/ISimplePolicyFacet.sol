// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SimplePolicy } from "./FreeStructs.sol";

interface ISimplePolicyFacet {
    function paySimplePremium(bytes32 _policyId, uint256 _amount) external;

    function paySimpleClaim(
        bytes32 _id,
        bytes32 _insuredId,
        uint256 _amount
    ) external;

    function getSimplePolicyInfo(bytes32 _id) external view returns (SimplePolicy memory);

    function checkAndUpdateSimplePolicyState(bytes32 _id) external;
}
