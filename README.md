## Hammer Supply Chain Workshop Demo

**This repository was made for the Enterprise Blockchain Bootcamp in Kigali, Rwanda in May 2025**

**⚠️WARNING: The factory contract in this example exceeds the EVM's 24k byte size. However, it partially works for demonstration purposes. We ignore the 5574 error code. Note that this will not work for production-level smart contracts.**

## The Project

The project includes a simple implementation of a supply chain dapp for hammers. The components are made up of ERC1967 upgradeable contracts. One example of updating the handle is included in `src/HammerHandleV2.sol`. In the dapp, the `assembleHammer` function is called after an initial supply of components are made. 

This project is simply a demonstration of how upgradeable contracts work, not to be used in real-life supply chain applications.
### Build

```shell
$ forge build --via-ir --sizes --ignored-error-codes 5574
```

### Test

```shell
$ forge test --via-ir
```

### Run
```shell
cd hammer-dapp
npm install
npm start
```
