// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { AppStorage, LibAppStorage } from "./AppStorage.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibConstants } from "./libs/LibConstants.sol";
import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibACL } from "./libs/LibACL.sol";
import { LibDiamond } from "../shared/libs/LibDiamond.sol";
import { LibEIP712 } from "src/diamonds/nayms/libs/LibEIP712.sol";
import { IERC165 } from "../shared/interfaces/IERC165.sol";
import { IDiamondCut } from "../shared/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../shared/interfaces/IDiamondLoupe.sol";
import { IERC173 } from "../shared/interfaces/IERC173.sol";
import { IERC20 } from "../../erc20/IERC20.sol";
import { IACLFacet } from "../nayms/interfaces/IACLFacet.sol";
import { IAdminFacet } from "../nayms/interfaces/IAdminFacet.sol";
import { IEntityFacet } from "../nayms/interfaces/IEntityFacet.sol";
import { IMarketFacet } from "../nayms/interfaces/IMarketFacet.sol";
import { INaymsTokenFacet } from "../nayms/interfaces/INaymsTokenFacet.sol";
import { ISimplePolicyFacet } from "../nayms/interfaces/ISimplePolicyFacet.sol";
import { ISystemFacet } from "../nayms/interfaces/ISystemFacet.sol";
import { ITokenizedVaultFacet } from "../nayms/interfaces/ITokenizedVaultFacet.sol";
import { ITokenizedVaultIOFacet } from "../nayms/interfaces/ITokenizedVaultIOFacet.sol";
import { IUserFacet } from "../nayms/interfaces/IUserFacet.sol";
import { IGovernanceFacet } from "../nayms/interfaces/IGovernanceFacet.sol";
import { FeeSchedule } from "../nayms/interfaces/FreeStructs.sol";

error DiamondAlreadyInitialized();

contract InitDiamond {
    event InitializeDiamond(address sender);

    function initialize() external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.diamondInitialized) {
            revert DiamondAlreadyInitialized();
        }

        // ERC20
        s.name = "Nayms";
        s.totalSupply = 100_000_000e18;
        s.balances[msg.sender] = s.totalSupply;

        // EIP712 domain separator
        s.initialChainId = block.chainid;
        s.initialDomainSeparator = LibEIP712._computeDomainSeparator();

        // disallow creating an object with ID of 0
        s.existingObjects[0] = true;

        // Set Commissions (all are in basis points)
        bytes32[] memory receiver = new bytes32[](1);
        receiver[0] = LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER);

        uint16[] memory premiumBP = new uint16[](1);
        premiumBP[0] = 300;
        uint16[] memory tradingBP = new uint16[](1);
        tradingBP[0] = 30;
        uint16[] memory initSaleBP = new uint16[](1);
        initSaleBP[0] = 100;

        s.feeSchedules[LibConstants.DEFAULT_FEE_SCHEDULE][LibConstants.FEE_TYPE_PREMIUM] = FeeSchedule({ receiver: receiver, basisPoints: premiumBP });
        s.feeSchedules[LibConstants.DEFAULT_FEE_SCHEDULE][LibConstants.FEE_TYPE_TRADING] = FeeSchedule({ receiver: receiver, basisPoints: tradingBP });
        s.feeSchedules[LibConstants.DEFAULT_FEE_SCHEDULE][LibConstants.FEE_TYPE_INITIAL_SALE] = FeeSchedule({ receiver: receiver, basisPoints: initSaleBP });

        s.naymsTokenId = LibHelpers._getIdForAddress(address(this));
        s.naymsToken = address(this);
        s.maxDividendDenominations = 1;

        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC20).interfaceId] = true;

        ds.supportedInterfaces[type(IACLFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IAdminFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IEntityFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IMarketFacet).interfaceId] = true;
        ds.supportedInterfaces[type(INaymsTokenFacet).interfaceId] = true;
        ds.supportedInterfaces[type(ISimplePolicyFacet).interfaceId] = true;
        ds.supportedInterfaces[type(ISystemFacet).interfaceId] = true;
        ds.supportedInterfaces[type(ITokenizedVaultFacet).interfaceId] = true;
        ds.supportedInterfaces[type(ITokenizedVaultIOFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IUserFacet).interfaceId] = true;
        ds.supportedInterfaces[type(IGovernanceFacet).interfaceId] = true;

        s.diamondInitialized = true;
        emit InitializeDiamond(msg.sender);
    }
}
