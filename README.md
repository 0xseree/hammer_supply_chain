## Hammer Supply Chain Workshop Demo

**This repository was made for the Enterprise Blockchain Bootcamp in Kigali, Rwanda in May 2025**

## The Project

The project includes a simple implementation of a supply chain dapp for hammers. The components are made up of ERC1967 upgradeable contracts. One example of updating the handle is included in `src/HammerHandleV2.sol`. In the dapp, the `assembleHammer` function is called after an initial supply of components are made. 

This project is simply a demonstration of how upgradeable contracts work, not to be used in real-life supply chain applications.
### Build

```shell
$ forge build --via-ir --sizes --optimize
```

### Test

```shell
$ forge test --via-ir --optimize
```

### Run
```shell
cd hammer-dapp
npm install
npm start
```
