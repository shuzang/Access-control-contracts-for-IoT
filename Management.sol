pragma solidity >=0.4.22 <0.7.0;

/* @title: Manage smart contracts and device attributes
   @author: shuzang
*/
contract Management {
    address public owner;
    Reputation public rc;
    
    struct RContract{
        bool isValued;       //for duplicate check
        address creator;     //the peer(account) who created and deployed reputation contract
        address scAddress;   //the address of the smart contract
    }
    
    struct attrValue{
        bool isValued;
        string value;
    }
    
    struct Device {
        bool isValued;                      //for duplicate check
        address manager;                    //the address of gateway which device belong to, for the gateway ,this filed is itself
        address scAddress;                  //the address of access control contract associate with device
        string  deviceID;                   //the unique ID of device
        string  deviceType;                 //device type,e.g. Loudness Sensor
        string  deviceRole;                 //device role,e.g. validator, manager or device 
        uint256 TimeofUnblock;              //time when the resource is unblocked (0 if unblocked, otherwise, blocked)
        mapping (string => attrValue) customed;   //other attribute self customed,can have no element
    }
    
    /*
    Mapping is marked internal, and write own getter function
    */
    RContract public rct;
    mapping(address => Device)  internal LookupTable;
    mapping(address => bool) internal isACCAddress; // judge if a address is a access control contract address, used by Reputation contract
    
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    
    /* @dev stringCompare determine whether the strings are equal, using length + hash comparson to reduce gas consumption
    */
    function stringCompare(string memory a, string memory b) internal pure returns (bool) {
        bytes memory _a = bytes(a);
        bytes memory _b = bytes(b);
        if (_a.length != _b.length) {
            return false;
        }else{
            if (_a.length == 1) {
                return _a[0] == _b[0];
            }else{
                return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
            }
            
        }
    }
    
    /* @dev: setRC
    */
    function setRC(address  _rc, address _creator) public 
    {
        //duplicate unchecked
        require(
            !rct.isValued,
            "setRC error: Reputation contract already exist!"
        );
        
        require(
            msg.sender == owner || msg.sender == _creator,
            "setRC error: Only mc owner or rc creator can register!"
        );
        
        // register
        rct.creator = _creator;
        rct.scAddress = _rc;
        rct.isValued = true;
        
        // setting for contract calls
        rc = Reputation(_rc);
    }
    
    /* @dev update the information (i.e., scAddress) of a registered reputation contract
    */
    function updateRC(address _rc) public {
        require(rct.isValued, "Reputation contract not exist!");
        require(
            msg.sender == owner || msg.sender == rct.creator,
            "updateRC error: Only mc owner or rc creator can update RC!"
        );

        rct.scAddress = _rc;
        rc = Reputation(_rc);
    }
    
    /* @dev deviceRegister register device attributes
    */
    function deviceRegister(
        address _device,
        address _manager,
        address _scAddress,
        string memory _deviceID,
        string memory _deviceType,
        string memory _deviceRole)
        public
    {
        require (
            !LookupTable[_device].isValued,
            "deviceRegister error: device already registered"
        );
        
        require(
            msg.sender == _manager,
            "deviceRegister error: Only manager of device can register!"
        );
        
        LookupTable[_device].manager = _manager;
        LookupTable[_device].scAddress = _scAddress;
        LookupTable[_device].deviceID = _deviceID;
        LookupTable[_device].deviceType = _deviceType;
        LookupTable[_device].deviceRole = _deviceRole;
        LookupTable[_device].TimeofUnblock = 0;
        LookupTable[_device].isValued = true;
        //rc.reputationCompute(msg.sender, false, 1, "Device register", now ); //设备注册事件提交会触发阻塞时间更新的的回调，回调时设备未注册陷入死循环 
        isACCAddress[_scAddress] = true;
    }
    
    /* @dev addAttribute add additional attribute to the device
    */
    function addAttribute (
        address _device,
        string memory _attrName,
        string memory _attrValue)
        public
    {
        require(LookupTable[_device].isValued, "addAttribute error: Device not registered!");
        require (
            msg.sender == LookupTable[_device].manager,
            "add Attribute error: Only manager can add attribute!"
        );
        require(
            !LookupTable[_device].customed[_attrName].isValued,
            "add Attribute error: Attribute already exist!"
        );
        
        LookupTable[_device].customed[_attrName].value = _attrValue;
        LookupTable[_device].customed[_attrName].isValued = true;
        rc.reputationCompute(msg.sender, false, 1, "Attribute add", now);
    }
    
     /* @dev updateManager update the manager of device
    */
    function updateManager (address _device, address _newManager) public {
        require(LookupTable[_device].isValued, "updateManager error: Device not registered!");
        require (
            msg.sender == owner || msg.sender == LookupTable[_device].manager,
            "updateManager error: Only mc owner or device manager can update device manager!"
        );
        LookupTable[_device].manager = _newManager;
        rc.reputationCompute(msg.sender, false, 2, "Device manager update", now);
    }
    
    /* @dev updateAttribute update attribute of device
    */
    function updateAttribute (
        address _device,
        string memory _attrName,
        string memory _attrValue)
        public
    {
        require(LookupTable[_device].isValued, "updateAttribute error: Device not registered!");
        require (
            msg.sender == LookupTable[_device].manager,
            "updateAttribute error: Only manager can update Attribute!"
        );
        require(
            LookupTable[_device].customed[_attrName].isValued,
            "updateAttribute error: Attribute not exist!"
        );
        LookupTable[_device].customed[_attrName].value = _attrValue;
        rc.reputationCompute(msg.sender, false, 2, "Device customed attribute update", now);
    }
    
    /* @dev updateTimeofUnblock update the time of unblocked, 
       @notice this fucntion only can be call by reputation contract
    */
    function updateTimeofUnblock(address _device, uint256 _TimeofUnblock) public {
        require(LookupTable[_device].isValued, "updateTimeofUnblock error: Device not registered!");
        require(msg.sender == rct.scAddress, "updateTimeofUnblock error: Only reputation contract can update time of unblock!");
        LookupTable[_device].TimeofUnblock = _TimeofUnblock;
    }
    
    /* @getFixedAttribute get the fixed device attribute(type is string)
    */
    function getFixedAttribute (address _device, string memory _attrName) public view returns (string memory _attrValue) {
        require(LookupTable[_device].isValued, "getFixedAttribute error: Device not registered!");
        require(
            stringCompare(_attrName, "deviceID") || stringCompare(_attrName,"deviceType") || stringCompare(_attrName,"deviceRole"),
            "getFixedAttribute error: The attribute passed in is not a device fixed attribute, please check the spelling or call getCustomedAttribute()."
        );
        if (stringCompare(_attrName, "deviceID")) {
            return LookupTable[_device].deviceID;
        }
        if (stringCompare(_attrName,"deviceType")) {
            return LookupTable[_device].deviceType;
        } 
        if (stringCompare(_attrName,"deviceRole")) {
            return LookupTable[_device].deviceRole;
        }
    }
    
    /* @getDeviceRelatedAddress get the fixed device attribute(type is address)
    */
    function getDeviceRelatedAddress(address _device, string memory _attrName) public view returns (address _attrValue) {
        require(LookupTable[_device].isValued, "getDeviceRelatedAddress error: Device not registered!");
        if (stringCompare(_attrName, "manager")) {
            return LookupTable[_device].manager;
        }
        if (stringCompare(_attrName, "scAddress")) {
            return LookupTable[_device].scAddress;
        }
    }
    
    /* @getCustomedAttribute get the customed attribute
    */
    function getCustomedAttribute(address _device, string memory _attrName) public view returns (string memory _attrValue) {
        require(LookupTable[_device].isValued, "getCustomedAttribute error: Device not registered!");
        require(
            LookupTable[_device].customed[_attrName].isValued,
            "getCustomedAttribute error: Attribute not exist!"
        );
        return LookupTable[_device].customed[_attrName].value;
    }
    
    function getTimeofUnblock(address _device) public view returns (uint256) {
        require(LookupTable[_device].isValued, "getTimeofUnblock error: Device not registered!");
        return LookupTable[_device].TimeofUnblock;
    }
    
    function isContractAddress(address _scAddress) public view returns (bool) {
        return isACCAddress[_scAddress];
    }
    
    /* @dev deleteDevice remove device from registered list
    */
    function deleteDevice(address _device) public {
        require(LookupTable[_device].isValued, "deleteDevice error: Device not registered!");
        require (
            msg.sender == LookupTable[_device].manager,
            "deleteDevice error: Only manager can remove device!"
        );
        delete LookupTable[_device];
        delete isACCAddress[LookupTable[_device].scAddress];
        rc.reputationCompute(msg.sender, false, 3, "Device delete", now);
    }
    
    /* @dev deleteAttribute delete customed attribute
    */
    function deleteAttribute(address _device, string memory _attrName) public {
        require(LookupTable[_device].isValued, "deleteAttribute error: device not exist!");
        require (
            msg.sender == LookupTable[_device].manager,
            "deleteAttribute error: Only owner can delete attribute!"
        );
        require (
            LookupTable[_device].customed[_attrName].isValued,
            "deleteAttribute error: Attribute not exist!"
        );
        delete LookupTable[_device].customed[_attrName];
        rc.reputationCompute(msg.sender, false, 3, "Attribute delete", now);
    }
}    

contract Reputation {
    function reputationCompute(
        address _subject, 
        bool _ismisbehavior,
        uint8 _behaviorID,
        string memory _behavior,
        uint256  _time
    ) public;
}