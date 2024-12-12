// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";

contract DividendPatchInitDiamond {
    function init() external {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 _tokenId = 0x59d9356e565ab3a36dd77763fc0d87feaf85508c000000000000000000000000; // USDM
        bytes32 _dividendTokenId = 0x59d9356e565ab3a36dd77763fc0d87feaf85508c000000000000000000000000; // USDM
        bytes32 _ownerId = 0x454e54495459000000000000653eeaf2a1e51089765e3c6291e780a640085943; // ILW

        s.tokenSupply[_tokenId] = 533337609745764857001482;
        s.totalDividends[_tokenId][_dividendTokenId] = 16406802958540022191510;
        s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId] = 16171508827360588570817;
    }
}
