// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

abstract contract ComponentBase is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public price;
    uint256 public inventoryCount;
    string public componentType;
    string public material;
    string public quality;
    mapping(uint256 => bool) public availableComponents;
    uint256 public nextComponentId;

    event ComponentCreated(uint256 indexed componentId, string componentType);
    event ComponentSold(uint256 indexed componentId, address buyer);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __ComponentBase_init(
        string memory _componentType,
        string memory _material,
        string memory _quality,
        uint256 _price,
        uint256 initialInventory
    ) internal onlyInitializing {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        componentType = _componentType;
        material = _material;
        quality = _quality;
        price = _price;
        for (uint256 i = 0; i < initialInventory; i++) {
            createComponent();
        }
    }

    function createComponent() public onlyOwner {
        uint256 componentId = nextComponentId++;
        availableComponents[componentId] = true;
        inventoryCount++;
        emit ComponentCreated(componentId, componentType);
    }

    function purchaseComponent() public payable returns (uint256) {
        require(inventoryCount > 0, "No components available");
        require(msg.value >= price, "Insufficient funds");
        uint256 componentId;
        for (uint256 i = 0; i < nextComponentId; i++) {
            if (availableComponents[i]) {
                componentId = i;
                break;
            }
        }
        availableComponents[componentId] = false;
        inventoryCount--;
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        emit ComponentSold(componentId, msg.sender);
        return componentId;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getInventoryCount() public view returns (uint256) {
        return inventoryCount;
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function version() public pure virtual returns (string memory) {
        return "v1";
    }
}

contract HammerHandle is ComponentBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _material, string memory _quality, uint256 _price, uint256 initialInventory)
        public
        initializer
    {
        __ComponentBase_init("Handle", _material, _quality, _price, initialInventory);
    }
}

contract HammerShaft is ComponentBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _material, string memory _quality, uint256 _price, uint256 initialInventory)
        public
        initializer
    {
        __ComponentBase_init("Shaft", _material, _quality, _price, initialInventory);
    }
}

contract HammerHead is ComponentBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _material, string memory _quality, uint256 _price, uint256 initialInventory)
        public
        initializer
    {
        __ComponentBase_init("Head", _material, _quality, _price, initialInventory);
    }
}

contract CompletedHammer is Initializable, OwnableUpgradeable {
    address public handleContract;
    address public shaftContract;
    address public headContract;
    uint256 public availableHammers = 0;
    mapping(uint256 => uint256) public hammerSalePrices;
    uint256 public nextHammerId = 0;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, address _handleContract, address _shaftContract, address _headContract)
        public
        initializer
    {
        __Ownable_init(initialOwner);
        handleContract = _handleContract;
        shaftContract = _shaftContract;
        headContract = _headContract;
    }

    function assembleHammer(string memory, /*hammerType*/ uint256 hammerSalePrice) public onlyOwner {
        uint256 _handlePrice = ComponentBase(handleContract).price();
        uint256 _shaftPrice = ComponentBase(shaftContract).price();
        uint256 _headPrice = ComponentBase(headContract).price();

        HammerHandle(handleContract).purchaseComponent{value: _handlePrice}();
        HammerShaft(shaftContract).purchaseComponent{value: _shaftPrice}();
        HammerHead(headContract).purchaseComponent{value: _headPrice}();

        uint256 hammerId = nextHammerId++;
        availableHammers++;
        hammerSalePrices[hammerId] = hammerSalePrice;
    }

    function purchaseHammer() public payable {
        require(availableHammers > 0, "No hammers available");
        uint256 currentHammerId = nextHammerId - 1;
        require(msg.value >= hammerSalePrices[currentHammerId], "Insufficient funds");
        availableHammers--;
        delete hammerSalePrices[currentHammerId];
    }

    function getAvailableHammers() public view returns (uint256) {
        return availableHammers;
    }
}

/**
 * @title HammerSupplyChainFactory
 * @dev Factory contract to deploy the entire hammer supply chain
 */
contract HammerSupplyChainFactory {
    event ComponentContractDeployed(address contractAddress, string componentType);
    event CompletedHammerContractDeployed(address contractAddress);

    function deploySupplyChain(
        address deployingOwner,
        string memory handleMaterial,
        string memory handleQuality,
        uint256 handlePrice,
        uint256 handleInventory,
        string memory shaftMaterial,
        string memory shaftQuality,
        uint256 shaftPrice,
        uint256 shaftInventory,
        string memory headMaterial,
        string memory headQuality,
        uint256 headPrice,
        uint256 headInventory
    )
        public
        returns (
            address handleContractAddress,
            address shaftContractAddress,
            address headContractAddress,
            address hammerContractAddress
        )
    {
        // Deploy handle implementation and proxy
        HammerHandle handleImplementation = new HammerHandle();
        bytes memory handleData = abi.encodeWithSelector(
            HammerHandle.initialize.selector, handleMaterial, handleQuality, handlePrice, handleInventory
        );
        ERC1967Proxy handleProxy = new ERC1967Proxy(address(handleImplementation), handleData);
        handleContractAddress = address(handleProxy);
        emit ComponentContractDeployed(handleContractAddress, "Handle");

        // Deploy shaft implementation and proxy
        HammerShaft shaftImplementation = new HammerShaft();
        bytes memory shaftData = abi.encodeWithSelector(
            HammerShaft.initialize.selector, shaftMaterial, shaftQuality, shaftPrice, shaftInventory
        );
        ERC1967Proxy shaftProxy = new ERC1967Proxy(address(shaftImplementation), shaftData);
        shaftContractAddress = address(shaftProxy);
        emit ComponentContractDeployed(shaftContractAddress, "Shaft");

        // Deploy head implementation and proxy
        HammerHead headImplementation = new HammerHead();
        bytes memory headData =
            abi.encodeWithSelector(HammerHead.initialize.selector, headMaterial, headQuality, headPrice, headInventory);
        ERC1967Proxy headProxy = new ERC1967Proxy(address(headImplementation), headData);
        headContractAddress = address(headProxy);
        emit ComponentContractDeployed(headContractAddress, "Head");

        // Deploy completed hammer implementation and proxy
        CompletedHammer hammerImplementation = new CompletedHammer();
        bytes memory hammerData = abi.encodeWithSelector(
            CompletedHammer.initialize.selector,
            deployingOwner,
            handleContractAddress,
            shaftContractAddress,
            headContractAddress
        );
        ERC1967Proxy hammerProxy = new ERC1967Proxy(address(hammerImplementation), hammerData);
        hammerContractAddress = address(hammerProxy);
        emit CompletedHammerContractDeployed(hammerContractAddress);

        return (handleContractAddress, shaftContractAddress, headContractAddress, hammerContractAddress);
    }
}
