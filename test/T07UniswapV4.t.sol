// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { StdStorage, stdStorage, StdStyle, StdAssertions } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { D03ProtocolDefaults, c, LC, LibHelpers } from "./defaults/D03ProtocolDefaults.sol";
import { StakingConfig, StakingState } from "src/shared/FreeStructs.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { StakingFixture } from "test/fixtures/StakingFixture.sol";
import { DummyToken } from "./utils/DummyToken.sol";
import { LibTokenizedVaultStaking } from "src/libs/LibTokenizedVaultStaking.sol";
import { IERC20 } from "src/interfaces/IERC20.sol";

import { Deployers } from "v4-core/../test/utils/Deployers.sol";
// import { PoolManager } from "v4-core/PoolManager.sol";

contract T07UniswapV4 is D03ProtocolDefaults, Deployers {
    using LibHelpers for address;
    using stdStorage for StdStorage;
    using StdStyle for *;

    function setUp() public {
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();
    }

    function testUniswapV4() public {}
}
