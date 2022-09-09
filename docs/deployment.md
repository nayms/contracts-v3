## Nayms v3 Smart Contract Deployment, Initialization, and Upgradability Pattern

Todo: Elaborate on diamond setup/deployment

### Deployment

Deploy deployer contract. Allows for counterfactual deployments.

Deploy all facets

Deploy Nayms diamond

Diamond cut all facets and initialize. Initialization steps coming soon.

### Initialization

Initialization will setup the desired initial state of the Nayms platform.

Relevant roles will be mapped to their respective role groups.

### Upgradability

At deployment, the "owner" of the diamond is assigned to be the Nayms EOA or Nayms multisig contract address.
Only the owner can upgrade (add, remove, replace) functionality of the Nayms platform.
Only the owner can change the owner address.
