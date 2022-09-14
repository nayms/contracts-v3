

- Comments in the code should be in Natspec format. (https://www.w3schools.io/blockchain/solidity-comments/)

- As the interfaces are automatically generated from the facets, comments should be put in the relevant facet and not the interface.

- All low-level functionality involving state change should be implemented in libraries. AppStorage should only be accessed via library.

- Events are used to share low-level technical data with off-chain applications. As such, events generally should be emitted in libraries where the state is changed.

- Facets should be used to expose public functionality and control access (apply moderators).

- Functionality is logically separated into facets. 


