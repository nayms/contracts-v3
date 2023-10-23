// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondLoupe.sol";
import { LibDiamond } from "lib/diamond-2-hardhat/contracts/libraries/LibDiamond.sol";
import { AppStorage, LibAppStorage } from "../shared/AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibACL } from "../libs/LibACL.sol";
import { LibInitDiamond } from "../libs/LibInitDiamond.sol";
import { LibEIP712 } from "../libs/LibEIP712.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { FeeSchedule } from "../shared/FreeStructs.sol";

error DiamondAlreadyInitialized();

contract InitDiamond {
    event InitializeDiamond(address sender);

    function init(address _systemAdmin) external {
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

        LibInitDiamond.setRoleGroupsAndAssigners();
        LibInitDiamond.setUpgradeExpiration();
        LibInitDiamond.setSystemAdmin(_systemAdmin);

        s.diamondInitialized = true;

        emit InitializeDiamond(msg.sender);
    }
}
