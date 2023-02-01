// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Modifiers } from "../Modifiers.sol";
import { AppStorage, LibAppStorage } from "../AppStorage.sol";

contract GovernanceFacet is Modifiers {
    function createUpgrade(bytes32 id) external assertSysAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.upgradeScheduled[id] = true;
    }
}
