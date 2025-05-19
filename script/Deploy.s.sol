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
        (
            address handleContract,
            address shaftContract,
            address headContract,
            address hammerContract
        ) = factory.deploySupplyChain(
            deployer,      // This will be passed to CompletedHammer
            "Rubber",      // handle material
            "Premium",     // handle quality
            0.05 ether,    // handle price
            50,           // handle inventory
            "Wood",       // shaft material
            "Standard",   // shaft quality
            0.08 ether,   // shaft price
            50,           // shaft inventory
            "Steel",      // head material
            "Heavy-Duty", // head quality
            0.12 ether,   // head price
            50            // head inventory
        );

        console.log("Handle contract deployed at:", handleContract);
        console.log("Shaft contract deployed at:", shaftContract);
        console.log("Head contract deployed at:", headContract);
        console.log("Hammer contract deployed at:", hammerContract);

        // Transfer ownership of component contracts to deployer
        // Since they were initialized with factory as owner
        HammerHandle(handleContract).transferOwnership(deployer);
        HammerShaft(shaftContract).transferOwnership(deployer);
        HammerHead(headContract).transferOwnership(deployer);

        console.log("Ownership transferred to deployer");

        // Now upgrade the handle to V2
        HammerHandleV2 handleV2Implementation = new HammerHandleV2();
        console.log("HammerHandleV2 implementation deployed at:", address(handleV2Implementation));

        // Upgrade the handle proxy to V2
        HammerHandle(handleContract).upgradeToAndCall(
            address(handleV2Implementation),
            ""
        );

        console.log("Handle contract upgraded to V2");

        // Test the V2 functionality
        HammerHandleV2 upgradedHandle = HammerHandleV2(handleContract);
        console.log("Handle version after upgrade:", upgradedHandle.version());

        // Test the new feature
        upgradedHandle.incrementNewFeatureCounter();
        console.log("New feature counter:", upgradedHandle.newFeatureCounter());

        vm.stopBroadcast();

        // Save deployment addresses to a file for the frontend
        string memory json = string(abi.encodePacked(
            '{\n',
            '  "factory": "', vm.toString(address(factory)), '",\n',
            '  "handleContract": "', vm.toString(handleContract), '",\n',
            '  "shaftContract": "', vm.toString(shaftContract), '",\n',
            '  "headContract": "', vm.toString(headContract), '",\n',
            '  "hammerContract": "', vm.toString(hammerContract), '",\n',
            '  "handleV2Implementation": "', vm.toString(address(handleV2Implementation)), '",\n',
            '  "deployer": "', vm.toString(deployer), '"\n',
            '}'
        ));

        vm.writeFile("./deployments.json", json);
        console.log("Deployment addresses saved to deployments.json");
    }
}