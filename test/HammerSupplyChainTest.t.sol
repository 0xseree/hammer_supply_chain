// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/HammerSupplyChain.sol";
import "../src/HammerHandleV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

contract HammerSupplyChainTest is Test {
    address handleContract;
    address shaftContract;
    address headContract;
    address hammerContract;
    address owner = makeAddr("owner");
    address customer = makeAddr("customer");
    address anotherAccount = makeAddr("another");

    uint256 constant HANDLE_PRICE = 0.05 ether;
    uint256 constant SHAFT_PRICE = 0.08 ether;
    uint256 constant HEAD_PRICE = 0.12 ether;
    uint256 constant HAMMER_SALE_PRICE = 0.3 ether;

    function setUp() public {
        vm.startPrank(owner);

        HammerHandle handleImplementation = new HammerHandle();
        bytes memory handleData = abi.encodeWithSelector(
            HammerHandle.initialize.selector, "Rubber", "Premium", HANDLE_PRICE, 10
        );
        ERC1967Proxy handleProxy = new ERC1967Proxy(address(handleImplementation), handleData);
        handleContract = address(handleProxy);

        HammerShaft shaftImplementation = new HammerShaft();
        bytes memory shaftData = abi.encodeWithSelector(
            HammerShaft.initialize.selector, "Wood", "Standard", SHAFT_PRICE, 10
        );
        ERC1967Proxy shaftProxy = new ERC1967Proxy(address(shaftImplementation), shaftData);
        shaftContract = address(shaftProxy);

        HammerHead headImplementation = new HammerHead();
        bytes memory headData =
            abi.encodeWithSelector(HammerHead.initialize.selector, "Steel", "Heavy-Duty", HEAD_PRICE, 10);
        ERC1967Proxy headProxy = new ERC1967Proxy(address(headImplementation), headData);
        headContract = address(headProxy);

        CompletedHammer hammerImplementation = new CompletedHammer();
        bytes memory hammerData = abi.encodeWithSelector(
            CompletedHammer.initialize.selector, owner, handleContract, shaftContract, headContract
        );
        ERC1967Proxy hammerProxy = new ERC1967Proxy(address(hammerImplementation), hammerData);
        hammerContract = address(hammerProxy);

        vm.stopPrank();

        assertEq(OwnableUpgradeable(handleContract).owner(), owner, "Handle contract owner mismatch");
        assertEq(OwnableUpgradeable(shaftContract).owner(), owner, "Shaft contract owner mismatch");
        assertEq(OwnableUpgradeable(headContract).owner(), owner, "Head contract owner mismatch");
        assertEq(OwnableUpgradeable(hammerContract).owner(), owner, "Hammer contract owner mismatch");
    }

    function testHandleOwner() public {
        assertTrue(true);
    }

    function testComponentInventory() public {
        assertEq(HammerHandle(handleContract).getInventoryCount(), 10);
        assertEq(HammerShaft(shaftContract).getInventoryCount(), 10);
        assertEq(HammerHead(headContract).getInventoryCount(), 10);
    }

    function testAssembleHammer() public {
        vm.startPrank(owner);
        vm.deal(hammerContract, 1 ether);
        CompletedHammer(hammerContract).assembleHammer("Basic Hammer", HAMMER_SALE_PRICE);
        vm.stopPrank();
        assertEq(CompletedHammer(hammerContract).getAvailableHammers(), 1);
        assertEq(HammerHandle(handleContract).getInventoryCount(), 9);
        assertEq(HammerShaft(shaftContract).getInventoryCount(), 9);
        assertEq(HammerHead(headContract).getInventoryCount(), 9);
    }

    function testPurchaseHammer() public {
        vm.startPrank(owner);
        vm.deal(hammerContract, 1 ether);
        CompletedHammer(hammerContract).assembleHammer("Basic Hammer", HAMMER_SALE_PRICE);
        vm.stopPrank();

        vm.startPrank(customer);
        uint256 initialHammerInventory = CompletedHammer(hammerContract).getAvailableHammers();
        vm.deal(customer, HAMMER_SALE_PRICE);
        CompletedHammer(hammerContract).purchaseHammer{value: HAMMER_SALE_PRICE}();
        uint256 finalHammerInventory = CompletedHammer(hammerContract).getAvailableHammers();
        vm.stopPrank();

        assertEq(initialHammerInventory, 1);
        assertEq(finalHammerInventory, 0);
    }

    function testUpgradeContract() public {
        vm.startPrank(owner);

        HammerHandleV2 newHandleImplementation = new HammerHandleV2();
        address newHandleImplementationAddress = address(newHandleImplementation);

        UUPSUpgradeable(handleContract).upgradeToAndCall(newHandleImplementationAddress, "");

        HammerHandleV2 upgradedHandle = HammerHandleV2(handleContract);
        assertEq(upgradedHandle.version(), "v2", "Contract version should be v2");

        upgradedHandle.incrementNewFeatureCounter();
        assertEq(upgradedHandle.newFeatureCounter(), 1, "New feature counter should be 1");

        vm.stopPrank();

        vm.startPrank(anotherAccount);
        vm.expectRevert();
        UUPSUpgradeable(handleContract).upgradeToAndCall(newHandleImplementationAddress, "");
        vm.stopPrank();
    }
}