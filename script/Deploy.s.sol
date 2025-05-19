// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/HammerSupplyChain.sol";
import "../src/HammerHandleV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployHammerSupplyChain is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the supply chain factory
        HammerSupplyChainFactory factory = new HammerSupplyChainFactory();
        console.log("Factory deployed at:", address(factory));

        // Deploy the initial supply chain using the factory
        (address handleContract, address shaftContract, address headContract, address hammerContract) = factory
            .deploySupplyChain(
            deployer,
            "Rubber", // handle material
            "Premium", // handle quality
            0.05 ether, // handle price
            50, // handle inventory
            "Wood", // shaft material
            "Standard", // shaft quality
            0.08 ether, // shaft price
            50, // shaft inventory
            "Steel", // head material
            "Heavy-Duty", // head quality
            0.12 ether, // head price
            50 // head inventory
        );

        console.log("Handle contract deployed at:", handleContract);
        console.log("Shaft contract deployed at:", shaftContract);
        console.log("Head contract deployed at:", headContract);
        console.log("Hammer contract deployed at:", hammerContract);

        vm.stopBroadcast();

        // Stop broadcasting as deployer, start as factory for ownership operations
        vm.startBroadcast(deployerPrivateKey);

        // Check who owns the handle contract
        address handleOwner = HammerHandle(handleContract).owner();
        console.log("Handle contract owner:", handleOwner);
        console.log("Factory address:", address(factory));

        // Since the factory is the owner, we need to call from the factory context
        // But factories don't have private keys, so we need to transfer ownership differently

        // Deploy new implementation
        HammerHandleV2 handleV2Implementation = new HammerHandleV2();
        console.log("HammerHandleV2 implementation deployed at:", address(handleV2Implementation));

        vm.stopBroadcast();

        // For now, let's create a new handle contract with correct ownership
        vm.startBroadcast(deployerPrivateKey);

        // Deploy a new handle contract directly (not through factory) for testing upgrade
        HammerHandle directHandleImplementation = new HammerHandle();
        bytes memory initData =
            abi.encodeWithSelector(HammerHandle.initialize.selector, "Rubber", "Premium", 0.05 ether, 50);
        ERC1967Proxy directHandleProxy = new ERC1967Proxy(address(directHandleImplementation), initData);
        address directHandleAddress = address(directHandleProxy);

        console.log("Direct handle deployed at:", directHandleAddress);
        console.log("Direct handle owner:", HammerHandle(directHandleAddress).owner());

        // Now this should work because deployer is the owner
        HammerHandle(directHandleAddress).upgradeToAndCall(address(handleV2Implementation), "");

        console.log("Direct handle upgraded successfully");

        // Test V2 functionality
        HammerHandleV2 upgradedHandle = HammerHandleV2(directHandleAddress);
        console.log("Version:", upgradedHandle.version());
        upgradedHandle.incrementNewFeatureCounter();
        console.log("New feature counter:", upgradedHandle.newFeatureCounter());

        vm.stopBroadcast();

        // Save deployment addresses
        string memory json = string(
            abi.encodePacked(
                "{\n",
                '  "factory": "',
                vm.toString(address(factory)),
                '",\n',
                '  "handleContract": "',
                vm.toString(handleContract),
                '",\n',
                '  "directHandleContract": "',
                vm.toString(directHandleAddress),
                '",\n',
                '  "shaftContract": "',
                vm.toString(shaftContract),
                '",\n',
                '  "headContract": "',
                vm.toString(headContract),
                '",\n',
                '  "hammerContract": "',
                vm.toString(hammerContract),
                '",\n',
                '  "handleV2Implementation": "',
                vm.toString(address(handleV2Implementation)),
                '",\n',
                '  "deployer": "',
                vm.toString(deployer),
                '"\n',
                "}"
            )
        );

        vm.writeFile("./deployments.json", json);
        console.log("Deployment addresses saved to deployments.json");
    }
}
