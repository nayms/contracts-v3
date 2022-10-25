// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract Constants {
    //Reserved IDs
    string public constant EMPTY_IDENTIFIER = "";
    string public constant SYSTEM_IDENTIFIER = "System";
    string public constant NDF_IDENTIFIER = "NDF";
    string public constant STM_IDENTIFIER = "Staking Mechanism";
    string public constant SSF_IDENTIFIER = "SSF";
    string public constant NAYM_TOKEN_IDENTIFIER = "NAYM"; //This is the ID in the system as well as the token ID
    string public constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank"; //This will hold all the dividends
    string public constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";
    // These should go directly to the receivers
    string public constant FEE_BANK_IDENTIFIER = "Deprecated!!!";
    string public constant BROKER_FEE_BANK_IDENTIFIER = "Also Deprecated!!!";

    //Roles
    string public constant ROLE_SYSTEM_ADMIN = "System Admin";
    string public constant ROLE_SYSTEM_MANAGER = "System Manager";
    string public constant ROLE_ENTITY_ADMIN = "Entity Admin";
    string public constant ROLE_ENTITY_MANAGER = "Entity Manager";
    string public constant ROLE_BROKER = "Broker";
    string public constant ROLE_INSURED_PARTY = "Insured";
    string public constant ROLE_UNDERWRITER = "Underwriter";
    string public constant ROLE_CAPITAL_PROVIDER = "Capital Provider";
    string public constant ROLE_CLAIMS_ADMIN = "Claims Admin";
    string public constant ROLE_TRADER = "Trader";
    string public constant ROLE_SEGREGATED_ACCOUNT = "Segregated Account";

    //Groups
    string public constant GROUP_SYSTEM_ADMINS = "System Admins";
    string public constant GROUP_SYSTEM_MANAGERS = "System Managers";
    string public constant GROUP_ENTITY_ADMINS = "Entity Admins";
    string public constant GROUP_ENTITY_MANAGERS = "Entity Managers";
    string public constant GROUP_APPROVED_USERS = "Approved Users";
    string public constant GROUP_BROKERS = "Brokers";
    string public constant GROUP_INSURED_PARTIES = "Insured Parties";
    string public constant GROUP_UNDERWRITERS = "Underwriters";
    string public constant GROUP_CAPITAL_PROVIDERS = "Capital Providers";
    string public constant GROUP_CLAIMS_ADMINS = "Claims Admins";
    string public constant GROUP_TRADERS = "Traders";
    string public constant GROUP_SEGREGATED_ACCOUNTS = "Segregated Accounts";

    /*///////////////////////////////////////////////////////////////////////////
                        Market Fee Schedules
    ///////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Standard fee is charged.
     */
    uint256 public constant FEE_SCHEDULE_STANDARD = 1;
    /**
     * @dev Platform-initiated trade, e.g. token sale or buyback.
     */
    uint256 public constant FEE_SCHEDULE_PLATFORM_ACTION = 2;

    /*///////////////////////////////////////////////////////////////////////////
                        MARKET OFFER STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 public constant OFFER_STATE_ACTIVE = 1;
    uint256 public constant OFFER_STATE_CANCELLED = 2;
    uint256 public constant OFFER_STATE_FULFILLED = 3;

    uint256 public constant DUST = 1;
    uint256 public constant BP_FACTOR = 1000;

    /*///////////////////////////////////////////////////////////////////////////
                        SIMPLE POLICY STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 public constant SIMPLE_POLICY_STATE_CREATED = 0;
    uint256 public constant SIMPLE_POLICY_STATE_APPROVED = 1;
    uint256 public constant SIMPLE_POLICY_STATE_ACTIVE = 2;
    uint256 public constant SIMPLE_POLICY_STATE_MATURED = 3;
    uint256 public constant SIMPLE_POLICY_STATE_CANCELLED = 4;
}
