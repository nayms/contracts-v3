// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Modifiers } from "../Modifiers.sol";
import { AppStorage, LibAppStorage } from "../AppStorage.sol";

contract GovernanceFacet is Modifiers {
    function createUpgrade(bytes32 id) external assertSysAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // 0 == upgrade is not scheduled / has been cancelled
        // block.timestamp + upgradeExpiration == upgrade is scheduled and expires at this time
        // 1 == upgrade has been successfully done
        s.upgradeScheduled[id] = block.timestamp + s.upgradeExpiration;
    }

    function updateUpgradeExpiration(uint256 duration) external assertSysAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.upgradeExpiration = duration;
    }

    function cancelUpgrade(bytes32 id) external assertSysAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.upgradeScheduled[id] = 0;
    }
}
