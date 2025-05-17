// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title ComponentBase
 * @dev Base contract for hammer components
 */
abstract contract ComponentBase is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // Component properties
    uint256 public price;
    uint256 public inventoryCount;
    string public componentType;
    string public material;
    string public quality;

    // Mapping of component IDs to their status (true if available)
    mapping(uint256 => bool) public availableComponents;
    uint256 public nextComponentId;

    // Events
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
        
        // Initialize inventory
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
        
        // Find an available component
        uint256 componentId;
        for (uint256 i = 0; i < nextComponentId; i++) {
            if (availableComponents[i]) {
                componentId = i;
                break;
            }
        }
        
        // Update availability
        availableComponents[componentId] = false;
        inventoryCount--;
        
        // Refund excess payment
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
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

/**
 * @title HammerHandle
 * @dev Contract for hammer handles
 */
contract HammerHandle is ComponentBase {
    function initialize(
        string memory _material,
        string memory _quality,
        uint256 _price,
        uint256 initialInventory
    ) public initializer {
        __ComponentBase_init("Handle", _material, _quality, _price, initialInventory);
    }
}

/**
 * @title HammerShaft
 * @dev Contract for hammer shafts
 */
contract HammerShaft is ComponentBase {
    function initialize(
        string memory _material,
        string memory _quality,
        uint256 _price,
        uint256 initialInventory
    ) public initializer {
        __ComponentBase_init("Shaft", _material, _quality, _price, initialInventory);
    }
}

/**
 * @title HammerHead
 * @dev Contract for hammer heads
 */
contract HammerHead is ComponentBase {
    function initialize(
        string memory _material,
        string memory _quality,
        uint256 _price,
        uint256 initialInventory
    ) public initializer {
        __ComponentBase_init("Head", _material, _quality, _price, initialInventory);
    }
}

/**
 * @title CompletedHammer
 * @dev Contract for completed hammers
 */
contract CompletedHammer is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct Hammer {
        uint256 handleId;
        uint256 shaftId;
        uint256 headId;
        string hammerType;
        uint256 price;
        bool isAvailable;
    }

    // Contract addresses for components
    address public handleContract;
    address public shaftContract;
    address public headContract;
    
    // Hammer inventory
    mapping(uint256 => Hammer) public hammers;
    uint256 public nextHammerId;
    uint256 public availableHammers;
    
    // Events
    event HammerAssembled(uint256 indexed hammerId, string hammerType);
    event HammerSold(uint256 indexed hammerId, address buyer);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _handleContract,
        address _shaftContract,
        address _headContract
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        
        handleContract = _handleContract;
        shaftContract = _shaftContract;
        headContract = _headContract;
    }
    
    function assembleHammer(
        string memory hammerType,
        uint256 price
    ) public onlyOwner {
        // Purchase components
        uint256 handleId = HammerHandle(handleContract).purchaseComponent();
        uint256 shaftId = HammerShaft(shaftContract).purchaseComponent();
        uint256 headId = HammerHead(headContract).purchaseComponent();
        
        // Create new hammer
        uint256 hammerId = nextHammerId++;
        hammers[hammerId] = Hammer({
            handleId: handleId,
            shaftId: shaftId,
            headId: headId,
            hammerType: hammerType,
            price: price,
            isAvailable: true
        });
        
        availableHammers++;
        emit HammerAssembled(hammerId, hammerType);
    }
    
    function purchaseHammer() public payable returns (uint256) {
        require(availableHammers > 0, "No hammers available");
        
        // Find an available hammer
        uint256 hammerId;
        for (uint256 i = 0; i < nextHammerId; i++) {
            if (hammers[i].isAvailable) {
                hammerId = i;
                break;
            }
        }
        
        Hammer storage hammer = hammers[hammerId];
        require(msg.value >= hammer.price, "Insufficient funds");
        
        // Update availability
        hammer.isAvailable = false;
        availableHammers--;
        
        // Refund excess payment
        if (msg.value > hammer.price) {
            payable(msg.sender).transfer(msg.value - hammer.price);
        }
        
        emit HammerSold(hammerId, msg.sender);
        return hammerId;
    }
    
    function getHammerDetails(uint256 hammerId) public view returns (
        uint256 handleId,
        uint256 shaftId,
        uint256 headId,
        string memory hammerType,
        uint256 price,
        bool isAvailable
    ) {
        Hammer storage hammer = hammers[hammerId];
        return (
            hammer.handleId,
            hammer.shaftId,
            hammer.headId,
            hammer.hammerType,
            hammer.price,
            hammer.isAvailable
        );
    }
    
    function setComponentContracts(
        address _handleContract,
        address _shaftContract,
        address _headContract
    ) public onlyOwner {
        handleContract = _handleContract;
        shaftContract = _shaftContract;
        headContract = _headContract;
    }
    
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function getAvailableHammers() public view returns (uint256) {
        return availableHammers;
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

/**
 * @title HammerSupplyChainFactory
 * @dev Factory contract to deploy the entire hammer supply chain
 */
contract HammerSupplyChainFactory {
    event ComponentContractDeployed(address contractAddress, string componentType);
    event CompletedHammerContractDeployed(address contractAddress);
    
    function deploySupplyChain(
        // Handle parameters
        string memory handleMaterial,
        string memory handleQuality,
        uint256 handlePrice,
        uint256 handleInventory,
        
        // Shaft parameters
        string memory shaftMaterial,
        string memory shaftQuality,
        uint256 shaftPrice,
        uint256 shaftInventory,
        
        // Head parameters
        string memory headMaterial,
        string memory headQuality,
        uint256 headPrice,
        uint256 headInventory
    ) public returns (
        address handleContractAddress,
        address shaftContractAddress,
        address headContractAddress,
        address hammerContractAddress
    ) {
        // Deploy handle implementation and proxy
        HammerHandle handleImplementation = new HammerHandle();
        bytes memory handleData = abi.encodeWithSelector(
            HammerHandle.initialize.selector,
            handleMaterial,
            handleQuality,
            handlePrice,
            handleInventory
        );
        ERC1967Proxy handleProxy = new ERC1967Proxy(address(handleImplementation), handleData);
        handleContractAddress = address(handleProxy);
        emit ComponentContractDeployed(handleContractAddress, "Handle");
        
        // Deploy shaft implementation and proxy
        HammerShaft shaftImplementation = new HammerShaft();
        bytes memory shaftData = abi.encodeWithSelector(
            HammerShaft.initialize.selector,
            shaftMaterial,
            shaftQuality,
            shaftPrice,
            shaftInventory
        );
        ERC1967Proxy shaftProxy = new ERC1967Proxy(address(shaftImplementation), shaftData);
        shaftContractAddress = address(shaftProxy);
        emit ComponentContractDeployed(shaftContractAddress, "Shaft");
        
        // Deploy head implementation and proxy
        HammerHead headImplementation = new HammerHead();
        bytes memory headData = abi.encodeWithSelector(
            HammerHead.initialize.selector,
            headMaterial,
            headQuality,
            headPrice,
            headInventory
        );
        ERC1967Proxy headProxy = new ERC1967Proxy(address(headImplementation), headData);
        headContractAddress = address(headProxy);
        emit ComponentContractDeployed(headContractAddress, "Head");
        
        // Deploy completed hammer implementation and proxy
        CompletedHammer hammerImplementation = new CompletedHammer();
        bytes memory hammerData = abi.encodeWithSelector(
            CompletedHammer.initialize.selector,
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