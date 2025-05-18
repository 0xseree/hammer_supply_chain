// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/HammerSupplyChain.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        HammerSupplyChainFactory factory = new HammerSupplyChainFactory();

        // Deploy the supply chain with initial values
        factory.deploySupplyChain(
            // Handle parameters
            "Wood",
            "Premium",
            0.05 ether,
            20,
            // Shaft parameters
            "Metal",
            "Standard",
            0.08 ether,
            20,
            // Head parameters
            "Steel",
            "Heavy-Duty",
            0.12 ether,
            20
        );

        vm.stopBroadcast();
    }
}
