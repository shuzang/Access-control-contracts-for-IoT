pragma solidity >=0.4.22 <0.6.0;

contract Register {
    struct Contract{
        bool isValued;       //for duplicate check
        string scType;       //smart contract type
        address creator;     //the peer(account) who created and deployed ACC or JC contract
        address scAddress;   //the address of the smart contract
    }
    
    struct Subject {
        bool isValued;                      //for duplicate check
        address manager;                    //the address of gateway which device belong to,for the gateway ,this filed is itself
        string  deviceType;                 //device type,e.g. Loudness Sensor
        string  deviceRole;                 //device role,e.g. validator, manager or device 
        mapping (string => string) customed;   //other attribute self customed,can have no element
    }
    
    /*
    Mapping is marked internal, and write own getter function
    */
    mapping(string => Contract) internal lookupTable;
    mapping(address => Subject)  internal subjectAttr;
    
    /*
     register a smart contract(ACC or JC)
    */
    function contractRegister(
        string memory _deviceID, 
        string memory _scType, 
        address _creator, 
        address  _scAddress) 
        public 
    {
        //duplicate unchecked
        require(
            !lookupTable[_deviceID].isValued,
            "Method already registered!"
        );
        
        lookupTable[_deviceID].scType = _scType;
        lookupTable[_deviceID].creator = _creator;
        lookupTable[_deviceID].scAddress = _scAddress;
        lookupTable[_deviceID].isValued = true;
    }
    
    /*
    update the information (i.e., scAddress) of a registered contract specified by the deviceName
    */
    function updateContractinf(string memory _deviceID, string memory _key, address _value) public {
        require (
            lookupTable[_deviceID].isValued && msg.sender == lookupTable[_deviceID].creator,
            "Only oldcreator can modify the right of belonging!"
        );
        if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("creator"))) {
            lookupTable[_deviceID].creator = _value;
        }
        if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("scAddress"))) {
            lookupTable[_deviceID].scAddress = _value;
        }
    }
    
    function deleteContract(string memory _deviceID) public {
        require(lookupTable[_deviceID].isValued && msg.sender == lookupTable[_deviceID].creator);
        delete lookupTable[_deviceID];
    }
    
    function getContractAddr(string memory _deviceID) public view returns (address _scAddress){
        require(lookupTable[_deviceID].isValued, "Contract not exist!");
        _scAddress = lookupTable[_deviceID].scAddress;
    }
    
    function subjectRegister(
        address _device,
        address _manager,
        string memory _deviceType,
        string memory _deviceRole)
        public
    {
        require (
            !subjectAttr[_device].isValued,
            "Subject already registered"
        );
        subjectAttr[_device].manager = _manager;
        subjectAttr[_device].deviceType = _deviceType;
        subjectAttr[_device].deviceRole = _deviceRole;
        subjectAttr[_device].isValued = true;
    }
    
    function addAttribute (
        address _device,
        string memory _attrName,
        string memory _attrValue)
        public
    {
        require (
            subjectAttr[_device].isValued && msg.sender == subjectAttr[_device].manager,
            "Only owner can add Attribute!"
        );
        subjectAttr[_device].customed[_attrName] = _attrValue;
    }
    
    function deleteDevice(address _device) public {
        require (
            subjectAttr[_device].isValued && msg.sender == subjectAttr[_device].manager,
            "Only owner can update manager!"
        );
        delete subjectAttr[_device];
    }
    
    function deleteAttribute(address _device, string memory _attrName) public {
        require (
            subjectAttr[_device].isValued && msg.sender == subjectAttr[_device].manager,
            "Only owner can update manager!"
        );
        delete subjectAttr[_device].customed[_attrName];
    }
    
    function updateManager (address _device, address _newManager) public {
        require (
            subjectAttr[_device].isValued && msg.sender == subjectAttr[_device].manager,
            "Only owner can update manager!"
        );
        subjectAttr[_device].manager = _newManager;
    }
    
    function updateAttrValue (
        address _device,
        string memory _attrName,
        string memory _attrValue)
        public
    {
        require (
            subjectAttr[_device].isValued && msg.sender == subjectAttr[_device].manager,
            "Only owner can update Attribute!"
        );
        if (keccak256(abi.encodePacked(_attrName)) == keccak256(abi.encodePacked("deviceType"))) {
            subjectAttr[_device].deviceType = _attrValue;
        } 
        if (keccak256(abi.encodePacked(_attrName)) == keccak256(abi.encodePacked("deviceRole"))) {
            subjectAttr[_device].deviceRole = _attrValue;
        }
        require(
            bytes(subjectAttr[_device].customed[_attrName]).length != 0,
            "Attribute not exist!"
        );
        subjectAttr[_device].customed[_attrName] = _attrValue;
    }
    
    function getAttribute (address _device, string memory _attrName) public view returns (string memory _attrValue) {
        if (keccak256(abi.encodePacked(_attrName)) == keccak256(abi.encodePacked("deviceType"))) {
            return subjectAttr[_device].deviceType;
        } 
        if (keccak256(abi.encodePacked(_attrName)) == keccak256(abi.encodePacked("deviceRole"))) {
            return subjectAttr[_device].deviceRole;
        }
        require(
            bytes(subjectAttr[_device].customed[_attrName]).length != 0,
            "Attribute not exist!"
        );
        return subjectAttr[_device].customed[_attrName];
    }
}