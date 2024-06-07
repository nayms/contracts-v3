// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// solhint-disable no-console
// solhint-disable no-global-import

import { console2 as c, Test, StdStorage, stdStorage, StdStyle } from "forge-std/Test.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { LibConstants as LC } from "src/libs/LibConstants.sol";
import { LibHelpers } from "src/libs/LibHelpers.sol";
import { StakingFacet } from "src/facets/StakingFacet.sol";
import { IERC20 } from "src/interfaces/IERC20.sol";
import { StakingState } from "src/shared/FreeStructs.sol";

contract ForkTest is Test {
    using stdStorage for StdStorage;
    using StdStyle for *;
    using LibHelpers for *;

    IDiamondProxy nayms = IDiamondProxy(0x6404f9C48562F39E1BAf2cD160c6f16D80b2f37F);

    function test_fork() public {
        vm.createSelectFork("base_sepolia", 10828508);

        bytes32 nlfId = 0x454e544954590000000000000f474eb52b77eec4308fb39fdf589b68ce4775c5;

        StakingFacet sf = new StakingFacet();
        vm.etch(0x5eA7b3745061DbF892A7114f749A5ba2b8696607, address(sf).code);

        address sender = 0x9e55dbaED8480E0955F25D9269beD1ce4f1Ba437;
        // bytes32 senderId = 0x9e55dbaED8480E0955F25D9269beD1ce4f1Ba437000000000000000000000000;
        bytes32 parentId = 0x454e544954590000000000000af39486c725cb99db01684e91c7579ed7882033;
        vm.label(sender, "Sender Account");
        vm.startPrank(sender);

        c.log(" current interval: %s", nayms.currentInterval(nlfId));

        c.log("  -- getting amounts".green());
        (uint256 stakedAmount_, uint256 boostedAmount_) = nayms.getStakingAmounts(parentId, nlfId);
        c.log("  -- amount: %s, bosted: %s".green(), stakedAmount_ / 1e18, boostedAmount_ / 1e18);

        nayms.unstake(nlfId);

        c.log("  -- getting amounts again".green());
        (uint256 stakedAmount_2, uint256 boostedAmount_2) = nayms.getStakingAmounts(parentId, nlfId);
        c.log("  -- amount: %s, boosted: %s".green(), stakedAmount_2 / 1e18, boostedAmount_2 / 1e18);

        c.log(" >> unstake DONE!".green());
    }
}
