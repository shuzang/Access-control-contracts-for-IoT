pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract AccessControl {
    address public manager;
    Reputation public rc;
    Management public mc;

    event ReturnAccessResult(
        address indexed _from,
        bool _result,
        string msg,
        uint256 _time
    );

    struct attriValue {
        bool isValued;
        string value;
    }

    struct PolicyItem {
        //for one (resource, action) pair;
        string attrOwner; //attribute of this policyItem belong to, subject or resources
        string attrName; //attribute name
        string operator; //Conditions operator that policyItem used
        string attrValue; //Conditions that policyItem should meet
    }
    
    struct Environment {
        uint256 minInterval; //minimum allowable interval (in seconds) between two successive requests
        uint256 threshold; //threshold on NoFR, above which a misbehavior is suspected
    }

    Environment public evAttr = Environment(100, 2);
    
    struct BehaviorItem {
        uint256 ToLR; //Time of Last Request
        uint256 NoFR; //Number of frequent Requests in a short period of time
    }

    //mapping subjcetAddress => BehaviorCriteria for behavior check
    mapping(address => BehaviorItem) internal behaviors;
    
    //mapping (resource, attributeName) => attributeValue for define and search resource attribute
    mapping(string => mapping(string => attriValue)) internal resources;
    //mapping (resource, action) =>PolicyCriteria for policy check
    mapping(string => mapping(string => PolicyItem[])) internal policies;

    /**
     * @dev Set contract deployer as manager, set management and reputation contract address
     */
    constructor(address _mc, address _rc, address _manager) public {
        manager = _manager;
        mc = Management(_mc);
        rc = Reputation(_rc);
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
    
    function updateEnviroment(uint256 _minInterval, uint256 _threshold)
        public
    {
        require(
            msg.sender == manager,
            "updateEnviroment error: Only acc manager can update environment value!"
        );
        evAttr.minInterval = _minInterval;
        evAttr.threshold = _threshold;
    }
    
    /* @dev updateSCAddr update management contract or reputation contract address
    */
    function updateSCAddr(string memory scType, address _scAddress) public {
        require(
            msg.sender == manager,
            "updateSCAddr error: Only acc manager can update mc or rc address!"
        );
        require(
            stringCompare(scType, "mc") || stringCompare(scType, "rc"),
            "updateSCAddr error: Updatable contract type can only be rc or mc!"
        );
        if (stringCompare(scType, "mc")) {
            mc = Management(_scAddress);
        }else{
            rc = Reputation(_scAddress);
        }
    }
    
    /* @dev updateManager update device manager, after that only new manager can operate this access control contract
    */
    function updateManager(address _manager) public {
        require(
            msg.sender == manager,
            "updateManager error: Only management contract can update manager address!"
        );
        manager = _manager;
        rc.reputationCompute(msg.sender, false, 2, "device manager update", now);
    }
    

    /* @dev addResourceAttr add resource attribute
    */
    function addResourceAttr(
        string memory _resource,
        string memory _attrName,
        string memory _attrValue
    ) public {
        require(msg.sender == manager, "addResourceAttr error: Caller is not manager!");
        require(
            !resources[_resource][_attrName].isValued,
            "addResourceAttr error: Resource attribute had been setted, pleased call resourceAttrUpdate!"
        );
        resources[_resource][_attrName].value = _attrValue;
        resources[_resource][_attrName].isValued = true;
        rc.reputationCompute(msg.sender, false, 1, "Resource attribute add", now);
    }

    /* @dev updateResourceAttr update resource attribute
    */
    function updateResourceAttr(
        string memory _resource,
        string memory _attrName,
        string memory _attrValue
    ) public {
        require(msg.sender == manager, "updateResourceAttr error: Caller is not manager!");
        require(
            resources[_resource][_attrName].isValued,
            "updateResourceAttr error: Resource attribute not exist, pleased first call addResourceAttr!"
        );
        resources[_resource][_attrName].value = _attrValue;
        rc.reputationCompute(msg.sender, false, 2, "Resource attribute update", now);
    }

    /* @dev getResourceAttr get resource attribute
    */
    function getResourceAttr(string memory _resource, string memory _attrName)
        public
        view
        returns (string memory _attrValue)
    {
        require(
            resources[_resource][_attrName].isValued,
            "getResourceAttr error: Resource attribute not exist!"
        );
        _attrValue = resources[_resource][_attrName].value;
    }

    /* @dev deleteResourceAttr delete the resource attribute
    */
    function deleteResourceAttr(
        string memory _resource,
        string memory _attrName
    ) public {
        require(msg.sender == manager, "deleteResourceAttr error: Caller is not manager!");
        require(
            resources[_resource][_attrName].isValued,
            "deleteResourceAttr error: Resource attribute not exist, don't need delete!"
        );
        delete resources[_resource][_attrName];
        rc.reputationCompute(msg.sender, false, 3, "Resource attribute delete", now);
    }

    /* @dev addPolicy add a policy
       @notice We can't judge whether the added policy is unique, so there are security risks here
    */
    function addPolicy(
        string memory _resource,
        string memory _action,
        string memory _attrOwner,
        string memory _attrName,
        string memory _operator,
        string memory _attrValue
    ) public {
        require(msg.sender == manager, "addPolicy error: Caller is not manager!");
        policies[_resource][_action].push(
            PolicyItem(_attrOwner, _attrName, _operator, _attrValue)
        );
        rc.reputationCompute(msg.sender, false, 1, "policy add", now);
    }

    /* @dev getPolicy get the policy associate with specified resource and action
    */
    function getPolicy(
        string memory _resource,
        string memory _action
    )
        public
        view
        returns (PolicyItem[] memory)
    {
        require(policies[_resource][_action].length != 0, "getPolicy error: There is no policy for this resource and action at this time!");
        PolicyItem[] memory result = new PolicyItem[](policies[_resource][_action].length);
        for (uint256 i = 0; i < policies[_resource][_action].length; i++) {
            result[i] = PolicyItem(
                policies[_resource][_action][i].attrOwner,
                policies[_resource][_action][i].attrName,
                policies[_resource][_action][i].operator,
                policies[_resource][_action][i].attrValue);
        }
        return result;
    }
    
    /* @dev getPolicyItem get the policy item associate with specified attribute name
    */
    function getPolicyItem(
        string memory _resource,
        string memory _action,
        string memory _attrName
    )
        public
        view
        returns (PolicyItem[] memory)
    {
        require(policies[_resource][_action].length != 0, "getPolicyItem error: There is no policy for this resource and action at this time!");
        PolicyItem[] memory result = new PolicyItem[](policies[_resource][_action].length);
        uint num = 0;
        for (uint256 i = 0; i < policies[_resource][_action].length; i++) {
            if (stringCompare(policies[_resource][_action][i].attrName, _attrName)) {
                result[num] = PolicyItem(
                    policies[_resource][_action][i].attrOwner,
                    _attrName,
                    policies[_resource][_action][i].operator,
                    policies[_resource][_action][i].attrValue);
                num++;
            }
        }
        return result;
    }
    
    /* @dev deletePolicy delete the policy associate with resource and specified action
    */
    function deletePolicy(string memory _resource, string memory _action) public {
        require(msg.sender == manager, "deletePolicy error: Caller is not manager!");
        require(policies[_resource][_action].length != 0, "deletePolicy error: There is no policy for this resource and action at this time!");
        delete policies[_resource][_action];
        rc.reputationCompute(msg.sender, false, 3, "Policy delete", now);
    }
    
    /* @dev deletePolicyItem delete the policy item associate with specified attribute name
    */
    function deletePolicyItem(string memory _resource, string memory _action, string memory _attrName) public {
        require(msg.sender == manager, "deletePolicyItem error: Caller is not manager!");
        require(policies[_resource][_action].length != 0, "deletePolicyItem error: There is no policy for this resource and action at this time!");
        for (uint256 i = 0; i < policies[_resource][_action].length; i++) {
            if (stringCompare(policies[_resource][_action][i].attrName, _attrName)) {
                delete policies[_resource][_action][i];
            }
        }
        rc.reputationCompute(msg.sender, false, 3, "Policy item delete", now);
    }

    /* @dev stringToUint is a utility fucntion used for convert number string to uint
    */
    function stringToUint(string memory s)
        public
        pure
        returns (uint256 result)
    {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    /* @dev accessControl is core fucntion
    */
    function accessControl(string memory _resource, string memory _action)
        public
        returns (bool)
    {
        address subject = msg.sender;
        
        string memory _curOwner;
        string memory _curAttrName;
        string memory _curOperator;
        string memory _curAttrValue;
        string memory _attrValue;
        
        bool policycheck = true;
        bool behaviorcheck = true;
        uint8 errcode;
        bool result;
        
        if (mc.getTimeofUnblock(subject) >= now) {
            //still blocked state
            errcode = 1; // Requests are blocked!
        }else{
            //unblocked state
            if ((now - behaviors[subject].ToLR) <= evAttr.minInterval) {
                behaviors[subject].NoFR++;
                if (behaviors[subject].NoFR >= evAttr.threshold) {
                    behaviorcheck = false;
                }
            }else{
                behaviors[subject].NoFR = 0;
            } 
        }

        //check policies
        for (uint256 i = 0; i < policies[_resource][_action].length; i++) {
            _curOwner = policies[_resource][_action][i].attrOwner;
            _curAttrName = policies[_resource][_action][i].attrName;
            _curOperator = policies[_resource][_action][i].operator;
            _curAttrValue = policies[_resource][_action][i].attrValue;

            if (stringCompare(_curOwner,"subject")) {
                if (stringCompare(_curAttrName, "deviceID") || stringCompare(_curAttrName, "deviceType") || stringCompare(_curAttrName, "deviceRole")) {
                    _attrValue = mc.getFixedAttribute(subject, _curAttrName);
                }else{
                    _attrValue = mc.getCustomedAttribute(subject, _curAttrName);
                }
            } else {
                _attrValue = resources[_resource][_curAttrName].value;
            }

            if (stringCompare(_curOperator,">") && (stringToUint(_attrValue) <= stringToUint(_curAttrValue))) {
                policycheck = false;
            }
            if (stringCompare(_curOperator,"<") && (stringToUint(_attrValue) >= stringToUint(_curAttrValue))) {
                policycheck = false;
            }
            if (stringCompare(_curOperator,"=") && (!stringCompare(_attrValue,_curAttrValue))) {
                policycheck = false;
            }
        }
        
        if (policycheck && !behaviorcheck) errcode = 2; //Static check failed!
        if (!policycheck && behaviorcheck) errcode = 3; //Misbehavior detected!
        if (!policycheck && !behaviorcheck) errcode = 4; //Static check failed and Misbehavior detected
        
        behaviors[subject].ToLR = now;
        result = policycheck && behaviorcheck;
        
        if (errcode == 0) {
            rc.reputationCompute(subject, false, 3, "Access authorized", now);
            emit ReturnAccessResult(subject, true, "Access authorized", now);
        }
        
        if (errcode == 1) {
            rc.reputationCompute(subject, true, 0, "Blocked end time not reached", now);
            emit ReturnAccessResult(subject, false, "Blocked end time not reached", now);
        }
        
        if (errcode == 2) {
            rc.reputationCompute(subject, true, 1, "Too frequent access", now);
            emit ReturnAccessResult(subject, false, "Too frequent access", now);
        }
        
        if (errcode == 3) {
            rc.reputationCompute(subject, true, 0, "Policy check failed", now);
            emit ReturnAccessResult(subject, false, "Policy check failed", now);
        }
        
        if (errcode == 4) {
            rc.reputationCompute(subject, true, 1, "Policy check failed and Too frequent access", now);
            emit ReturnAccessResult(subject, false, "Policy check failed and Too frequent access", now);
        }
        return result;
    }

    function deleteACC() public {
        require(msg.sender == manager, "Caller is not manager!");
        selfdestruct(msg.sender);
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

contract Management {
    function getTimeofUnblock(address _device) public returns (uint256);
    function getFixedAttribute (address _device, string memory _attrName) public view returns (string memory _attrValue);
    function getCustomedAttribute(address _device, string memory _attrName) public view returns (string memory _attrValue);
}
