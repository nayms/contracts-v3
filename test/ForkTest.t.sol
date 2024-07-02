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

    IDiamondProxy nayms = IDiamondProxy(0xc9FBBCA30856A960f48667834C129011EFD5612a); // sepolia
    // IDiamondProxy nayms = IDiamondProxy(0x2561E3F2f79b2597CCF1752C47fb2EA54F463c95); // base sepolia
    // IDiamondProxy nayms = IDiamondProxy(0x4F10acBA59A206a66713380De02F9c09880A822F); // aurora testnet

    function testFork() public {
        vm.createSelectFork("base_sepolia", 11773451);
        // vm.createSelectFork("sepolia");

        bytes32 nlfId = 0x454e544954590000000000003bb87a26cb3adfbaa9931e33505cb23a50abca90;

        StakingFacet sf = new StakingFacet();
        vm.etch(0x3E81ba215eBF5B209a4fB03E698535a3056438D6, address(sf).code);

        address sender = 0xDD3e88c074B272Da66ff5Be7EA5BF4263080dDA3;
        bytes32 parentId = nayms.getEntity(LibHelpers._getIdForAddress(sender));
        // bytes32 senderId = 0xdd3e88c074b272da66ff5be7ea5bf4263080dda3000000000000000000000000;
        // bytes32 parentId = 454E544954590000000000006F26B7C2A46C0194FFDB21295DB1F12A93EC3988;
        c.log("parentId: ", parentId.greenBytes32());

        vm.label(sender, "Sender Account");
        vm.startPrank(sender);

        c.log("interval:  %s", nayms.currentInterval(nlfId));

        c.log("getting amounts...".green());
        (uint256 stakedAmount_, uint256 boostedAmount_) = nayms.getStakingAmounts(parentId, nlfId);
        c.log("amount: %s, bosted: %s".green(), stakedAmount_ / 1e18, boostedAmount_ / 1e18);

        // nayms.unstake(nlfId);
        nayms.stake(nlfId, 50_000_000_000_000_000_000);

        c.log("getting amounts again".green());
        (uint256 stakedAmount_2, uint256 boostedAmount_2) = nayms.getStakingAmounts(parentId, nlfId);
        c.log("amount: %s, boosted: %s".green(), stakedAmount_2 / 1e18, boostedAmount_2 / 1e18);

        c.log("[+] Done");
    }
}
