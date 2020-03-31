pragma solidity >=0.4.22 <0.6.0;

contract AccessControl {
    address public owner;
    Judge public jc;
    Register public rc;

    event ReturnAccessResult(
        address indexed _from,
        string _errmsg,
        bool _result,
        uint256 _time,
        uint256 _penalty
    );

    struct attriValue {
        bool isValued;
        string value;
    }

    struct Environment {
        uint256 minInterval; //minimum allowable interval (in seconds) between two successive requests
        uint256 threshold; //threshold on NoFR, above which a misbehavior is suspected
    }

    Environment public evAttr = Environment(100, 2);

    struct PolicyItem {
        //for one (resource, action) pair;
        string attrOwner; //attribute of this policyItem belong to, subject or resources
        string attrName; //attribute name
        string operator; //Conditions operator that policyItem used
        string attrValue; //Conditions that policyItem should meet
    }

    struct Misbehavior {
        string res; //resource on which the misbehavior is conducted
        string action; //action (e.g., "read", "write", "execute") of the misbehavior
        string misbehavior; //misbehavior
        uint256 time; //time of the misbehavior occured
        uint256 penalty; //penalty opposed to the subject (number of minutes blocked)
    }

    struct BehaviorItem {
        //for one resource
        Misbehavior[] mbs; //misbehavior list of the subject on a particular resource
        uint256 ToLR; //Time of Last Request
        uint256 NoFR; //Number of frequent Requests in a short period of time
        bool result; //last access result
        uint8 err; //last err code
        uint256 TimeofUnblock; //time when the resource is unblocked (0 if unblocked, otherwise, blocked)
    }

    //mapping subjcetAddress => BehaviorCriteria for behavior check
    mapping(address => BehaviorItem) internal behaviors;
    //mapping (resource, attributeName) => attributeValue for define and search resource attribute
    mapping(string => mapping(string => attriValue)) internal resources;
    //mapping (resource, action) =>PolicyCriteria for policy check
    mapping(string => mapping(string => PolicyItem[])) internal policies;

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can modify!");
        _;
    }

    constructor(address _rc, address _jc) public {
        owner = msg.sender;
        rc = Register(_rc);
        jc = Judge(_jc);
    }

    function resourceAttrAdd(
        string memory _resource,
        string memory _attrName,
        string memory _attrValue
    ) public onlyOwner {
        require(
            !resources[_resource][_attrName].isValued,
            "Resource attribute had been setted, pleased call resourceAttrUpdate!"
        );
        resources[_resource][_attrName].value = _attrValue;
        resources[_resource][_attrName].isValued = true;
    }

    function resourceAttrUpdate(
        string memory _resource,
        string memory _attrName,
        string memory _attrValue
    ) public onlyOwner {
        require(
            resources[_resource][_attrName].isValued,
            "Resource attribute not exist, pleased first call resourceAttrAdd!"
        );
        resources[_resource][_attrName].value = _attrValue;
    }

    function getResourceAttr(string memory _resource, string memory _attrName)
        public
        view
        returns (string memory _attrValue)
    {
        require(
            resources[_resource][_attrName].isValued,
            "Resource attribute not exist!"
        );
        _attrValue = resources[_resource][_attrName].value;
    }

    function deleteResourceAttr(
        string memory _resource,
        string memory _attrName
    ) public onlyOwner {
        require(
            resources[_resource][_attrName].isValued,
            "Resource attribute not exist, don't need delete!"
        );
        delete resources[_resource][_attrName];
    }

    function enAttiUpdate(uint256 _minInterval, uint256 _threshold)
        public
        onlyOwner
    {
        evAttr.minInterval = _minInterval;
        evAttr.threshold = _threshold;
    }
    function policyAdd(
        string memory _resource,
        string memory _action,
        string memory _attrOwner,
        string memory _attrName,
        string memory _operator,
        string memory _attrValue
    ) public onlyOwner {
        policies[_resource][_action].push(
            PolicyItem(_attrOwner, _attrName, _operator, _attrValue)
        );
    }

    function getPolicy(
        string memory _resource,
        string memory _action,
        string memory _attrName
    )
        public
        view
        returns (
            string memory _attrOwner,
            string memory _attrName_,
            string memory _operator,
            string memory _attrValue
        )
    {
        require(policies[_resource][_action].length != 0, "policy not exist!");
        _attrName_ = _attrName;
        for (uint256 i = 0; i < policies[_resource][_action].length; i++) {
            if (
                keccak256(
                    abi.encodePacked(policies[_resource][_action][i].attrName)
                ) ==
                keccak256(abi.encodePacked(_attrName))
            ) {
                _attrOwner = policies[_resource][_action][i].attrOwner;
                _operator = policies[_resource][_action][i].operator;
                _attrValue = policies[_resource][_action][i].attrValue;
            }
        }
    }

    function policyDelete(string memory _resource, string memory _action)
        public
        onlyOwner
    {
        require(policies[_resource][_action].length != 0, "policy not exist!");
        delete policies[_resource][_action];
    }

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

    function emitError(address subject) public returns (uint256 penalty) {
        penalty = jc.misbehaviorJudge(
            subject,
            owner,
            "data",
            "read",
            "Too frequent access!",
             now
        );
    }

    //Use event
    function accessControl(string memory _resource, string memory _action)
        public
    {
        address subject = msg.sender;
        string memory _newValue;
        string memory _newOperator;
        string memory _newOwner;
        string memory _newName;
        string memory _attrValue;

        bool behaviorcheck = true;
        bool policycheck = true;
        uint8 errcode = 0;
        uint256 penalty = 0;

        if (behaviors[subject].TimeofUnblock >= now) {
            //still blocked state
            errcode = 1; //"Requests are blocked!"
        } else {
            //unblocked state
            if (behaviors[subject].TimeofUnblock > 0) {
                behaviors[subject].TimeofUnblock = 0;
                behaviors[subject].NoFR = 0;
                behaviors[subject].ToLR = 0;
            }
            //behavior check
            if ((now - behaviors[subject].ToLR) <= evAttr.minInterval) {
                behaviors[subject].NoFR++;
                if (behaviors[subject].NoFR >= evAttr.threshold) {
                    penalty = jc.misbehaviorJudge(
                        subject,
                        owner,
                        _resource,
                        _action,
                        "Too frequent access!",
                        now
                    );
                    behaviorcheck = false;
                    behaviors[subject].TimeofUnblock = now + penalty * 60;
                    behaviors[subject].mbs.push(
                        Misbehavior(
                            _resource,
                            _action,
                            "Too frequent access!",
                            now,
                            penalty
                        )
                    );
                }
            } else {
                behaviors[subject].NoFR = 0;
            }
        }

        for (uint256 i = 0; i < policies[_resource][_action].length; i++) {
            _newName = policies[_resource][_action][i].attrName;
            _newOwner = policies[_resource][_action][i].attrOwner;
            _newOperator = policies[_resource][_action][i].operator;
            _newValue = policies[_resource][_action][i].attrValue;

            if (
                keccak256(abi.encodePacked(_newOwner)) ==
                keccak256(abi.encodePacked("subject"))
            ) {
                _attrValue = rc.getAttribute(subject, _newName);
            } else {
                _attrValue = resources[_resource][_newName].value;
            }

            if (
                keccak256(abi.encodePacked(_newOperator)) ==
                keccak256(abi.encodePacked(">"))
            ) {
                if (stringToUint(_attrValue) <= stringToUint(_newValue)) {
                    policycheck = false;
                }
            }
            if (
                keccak256(abi.encodePacked(_newOperator)) ==
                keccak256(abi.encodePacked("<"))
            ) {
                if (stringToUint(_attrValue) >= stringToUint(_newValue)) {
                    policycheck = false;
                }
            }
            if (
                keccak256(abi.encodePacked(_newOperator)) ==
                keccak256(abi.encodePacked("="))
            ) {
                if (
                    keccak256(abi.encodePacked(_attrValue)) !=
                    keccak256(abi.encodePacked(_newValue))
                ) {
                    policycheck = false;
                }
            }
        }

        if (!policycheck && behaviorcheck) errcode = 2; //Static check failed!
        if (policycheck && !behaviorcheck) errcode = 3; //Misbehavior detected!
        if (!policycheck && !behaviorcheck) errcode = 4; //Static check failed and Misbehavior detected

        behaviors[subject].ToLR = now;
        behaviors[subject].result = policycheck && behaviorcheck;
        behaviors[subject].err = errcode;
        if (0 == errcode)
            emit ReturnAccessResult(
                subject,
                "Access authorized!",
                true,
                now,
                penalty
            );
        if (1 == errcode)
            emit ReturnAccessResult(
                subject,
                "Requests are blocked!",
                false,
                now,
                penalty
            );
        if (2 == errcode)
            emit ReturnAccessResult(
                subject,
                "Static Check failed!",
                false,
                now,
                penalty
            );
        if (3 == errcode)
            emit ReturnAccessResult(
                subject,
                "Misbehavior detected!",
                false,
                now,
                penalty
            );
        if (4 == errcode)
            emit ReturnAccessResult(
                subject,
                "Static check failed! & Misbehavior detected!",
                false,
                now,
                penalty
            );
    }

    function getTimeofUnblock(address _subject)
        public
        view
        returns (uint256 _penalty, uint256 _timeOfUnblock)
    {
        uint256 l = behaviors[_subject].mbs.length;
        _timeOfUnblock = behaviors[_subject].TimeofUnblock;
        _penalty = behaviors[_subject].mbs[l - 1].penalty;
    }

    function deleteACC() public onlyOwner {
        selfdestruct(msg.sender);
    }
}

contract Judge {
    function misbehaviorJudge(
        address _subject,
        address _object,
        string memory _resource,
        string memory _action,
        string memory _misbehavior,
        uint256 _time
    ) public returns (uint256);
}

contract Register {
    function getAttribute(address _device, string memory _attrName)
        public
        view
        returns (string memory _attrValue);
}
