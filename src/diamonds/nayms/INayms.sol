// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { IDiamondCut } from "../shared/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../shared/interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../shared/interfaces/IERC165.sol";
import { IERC173 } from "../shared/interfaces/IERC173.sol";

import { IACLFacet } from "./interfaces/IACLFacet.sol";
import { INaymsERC20Facet } from "./interfaces/INaymsERC20Facet.sol";
import { IUserFacet } from "./interfaces/IUserFacet.sol";
import { IAdminFacet } from "./interfaces/IAdminFacet.sol";
import { ISystemFacet } from "./interfaces/ISystemFacet.sol";
import { IStakingFacet } from "./interfaces/IStakingFacet.sol";
import { ISSFFacet } from "./interfaces/ISSFFacet.sol";
import { INDFFacet } from "./interfaces/INDFFacet.sol";
import { ITokenizedVaultFacet } from "./interfaces/ITokenizedVaultFacet.sol";
import { ITokenizedVaultIOFacet } from "./interfaces/ITokenizedVaultIOFacet.sol";
import { IMarketFacet } from "./interfaces/IMarketFacet.sol";
import { IEntityFacet } from "./interfaces/IEntityFacet.sol";
import { ISimplePolicyFacet } from "./interfaces/ISimplePolicyFacet.sol";

/**
 * @title Nayms Diamond
 * @notice Everything is a part of one big diamond.
 * @dev Every facet should be cut into this diamond.
 */
interface INayms is
    IDiamondCut,
    IDiamondLoupe,
    IERC165,
    IERC173,
    IACLFacet,
    INaymsERC20Facet,
    IAdminFacet,
    IUserFacet,
    ISystemFacet,
    ITokenizedVaultFacet,
    ITokenizedVaultIOFacet,
    IMarketFacet,
    IEntityFacet,
    ISimplePolicyFacet,
    ISSFFacet,
    INDFFacet,
    IStakingFacet
{

}
