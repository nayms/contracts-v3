# Conventions and Coding Standards

- Comments in the code should be in [Natspec Format](https://www.w3schools.io/blockchain/solidity-comments/).

<br>

- Comments in code relevant to business logic should be in the facets. 

<br>

- Comments in the libs should be relevant to aspects of low-level technical implementation and data structures.

<br>

- All low-level functionality involving state change should be implemented in libraries. AppStorage should only be accessed via library.

<br>

- Events are used to share low-level technical data with off-chain applications. As such, events generally should be emitted in libraries where the state is changed.

<br>

- Facets should be used to expose public functionality and control access (apply modifiers).

<br>

- Functionality is logically separated into facets.
