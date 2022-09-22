# Nayms Smart Contracts Test Plan

Setup defaults for testing in `test/defaults`.
Defaults follow a hierarchy:

#### D00: Global configuration

#### D01: Nayms protocol deployment

#### D02: Testing defaults such as deploying test tokens and giving addresses starting balances

#### D03: Protocol level defaults such as setting Nayms internal IDs

Tests follow a hierarchy:

#### T01: Test defaults, deployment

#### T02: ACL, Admin functions

#### T03: Token transfers, creating entities

#### T04: Creating policies, marketplace functionality

Tests should be fixed in order of the hierarchy (T01 first).

Unit tests on all library methods. These functions can be tested by inheriting the library into a contract.

Unit tests on all facet methods.

We will also run a separate set of tests on our live goerli deployment. The forked state will be controlled in each test file.

Tests should cover happy paths. Fuzz and invariant testing will be added after the above is completed.

Once invariant testing is complete, we can be confident that unhappy and "nontraditional" logic paths are tested and will not affect our system.

Code coverage should be close to 100%.
