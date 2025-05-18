// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/HammerSupplyChain.sol";

contract HammerSupplyChainTest is Test {
    HammerSupplyChainFactory factory;
    address handleContract;
    address shaftContract;
    address headContract;
    address hammerContract;

    address owner = address(0x1);
    address customer = address(0x2);

    function setUp() public {
        vm.startPrank(owner);

        factory = new HammerSupplyChainFactory();

        // Deploy the supply chain
        (handleContract, shaftContract, headContract, hammerContract) = factory.deploySupplyChain(
            // Handle parameters
            "Wood",
            "Premium",
            0.05 ether,
            10,
            // Shaft parameters
            "Metal",
            "Standard",
            0.08 ether,
            10,
            // Head parameters
            "Steel",
            "Heavy-Duty",
            0.12 ether,
            10
        );

        vm.stopPrank();
    }

    function testComponentInventory() public {
        assertEq(HammerHandle(handleContract).getInventoryCount(), 10);
        assertEq(HammerShaft(shaftContract).getInventoryCount(), 10);
        assertEq(HammerHead(headContract).getInventoryCount(), 10);
    }

    function testAssembleHammer() public {
        vm.startPrank(owner);

        // Owner must have enough funds to purchase components
        vm.deal(owner, 1 ether);

        CompletedHammer(hammerContract).assembleHammer("Claw Hammer", 0.3 ether);

        assertEq(CompletedHammer(hammerContract).getAvailableHammers(), 1);
        assertEq(HammerHandle(handleContract).getInventoryCount(), 9);
        assertEq(HammerShaft(shaftContract).getInventoryCount(), 9);
        assertEq(HammerHead(headContract).getInventoryCount(), 9);

        vm.stopPrank();
    }

    function testPurchaseHammer() public {
        vm.startPrank(owner);
        vm.deal(owner, 1 ether);

        // Assemble a hammer first
        CompletedHammer(hammerContract).assembleHammer("Claw Hammer", 0.3 ether);

        vm.stopPrank();

        // Customer purchases the hammer
        vm.startPrank(customer);
        vm.deal(customer, 0.5 ether);

        uint256 hammerIdPurchased = CompletedHammer(hammerContract).purchaseHammer{value: 0.3 ether}();

        // Check hammer details
        (,,, string memory hammerType,, bool isAvailable) =
            CompletedHammer(hammerContract).getHammerDetails(hammerIdPurchased);

        assertEq(hammerType, "Claw Hammer");
        assertEq(isAvailable, false);
        assertEq(CompletedHammer(hammerContract).getAvailableHammers(), 0);

        vm.stopPrank();
    }

    function testUpgradeContract() public {
        // ToDo: Implement tests for the upgrade functionality
        // This would involve deploying a new implementation contract and using the upgradeTo function
    }
}
