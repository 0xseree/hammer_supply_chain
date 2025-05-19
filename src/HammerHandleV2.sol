// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "./HammerSupplyChain.sol";

contract HammerHandleV2 is ComponentBase {
    uint256 public newFeatureCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _material,
        string memory _quality,
        uint256 _price,
        uint256 initialInventory
    ) public initializer {
        __ComponentBase_init("Handle", _material, _quality, _price, initialInventory);
    }

    function incrementNewFeatureCounter() public onlyOwner {
        newFeatureCounter++;
    }

    function version() public pure override returns (string memory) {
        return "v2";
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}