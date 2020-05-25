 pragma solidity >=0.4.22 <0.7.0;

contract Reputation {

    address public owner;
    address public mcAddress;
    Management public mc;
    
    event isCalled(address indexed _from, bool indexed _ismisbehavior, string indexed _behavior, uint _time, uint CrN, uint Tblocked, uint CrP, uint Treward);

    struct BehaviorRecord {
        uint[4] nbs; //Number of normal behaviors specified by behavior ID, ID-1 is array index
        uint[] mbs1; //time of misbehaviors（other） ocured
        uint[] mbs2; //time of misbehaviors（large number of requests in a short time） ocured
        uint[] mbs3;
        uint TimeofUnblock; //End time of blocked (0 if unblocked, otherwise, blocked)
    }
    
    struct Environment {
        uint[4] omega; 
        uint[3] alpha; //penalty factor, index 0 is illegal attribute or policy action, index 1 is access failed, index 2 is large number of requests in a short time
        uint gamma; //used for control misbehavior frequent
        uint N;
    }

    //mapping devie address => Behavior recort for reputation compute
    mapping(address => BehaviorRecord) public behaviors;
    //some environment factors
    Environment public evAttr;
    
    /**
     * @dev Set contract deployer as owner, set management contract address, initial environment variable
     */
    constructor(address _mc) public {
        owner = msg.sender;
        mc = Management(_mc);
        mcAddress = _mc;
        initEnvironment();
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
    
    /* @dev initEnvironment initial parameters of reputation function
    */
    function initEnvironment() internal {
        evAttr.alpha[0] = 5; // can't use float in solidity, set 5 and when we use this number, we use 5/10
        evAttr.alpha[1] = 5;
        evAttr.alpha[2] = 10;
        evAttr.gamma = 5;
        evAttr.omega[0] = 5;
        evAttr.omega[1] = 5;
        evAttr.omega[2] = 5;
        evAttr.omega[3] = 10;
        evAttr.N = 10;
    }
    
    /* @ dev updateEnvironment update parameters of reputation function
    */
    function updateEnvironment(string memory _name, uint index, uint value) public {
        require(
            msg.sender == owner,
            "Only owner can update environment factors!"
        );
        if (stringCompare(_name, "omega")) {
            evAttr.omega[index] = value;
        }
        if (stringCompare(_name, "alpha")) {
            evAttr.alpha[index] = value;
        }
        if (stringCompare(_name, "gamma")) {
            evAttr.gamma = value;
        }
        if (stringCompare(_name, "N")) {
            evAttr.N = value;
        }
    }

    /* @dev reputationCompute compute the positive impact part and negative impact part of credit value,
            and then, compute blocked time and reward time according the credit value and update the device attribute
    */
    function reputationCompute(
        address _subject, 
        bool _ismisbehavior,
        uint _behaviorID,
        string memory _behavior,
        uint  _time) 
        public 
    {
        require(
            msg.sender == mc.getDeviceRelatedAddress(_subject, "scAddress") || msg.sender == mcAddress,
            "only acc or mc can call function!"
        );
        uint CrN = 0;
        uint CrP = 0;
        uint Tblocked;
        uint Treward;
        uint i;
        
        if (_ismisbehavior) {
            if (_behaviorID == 1) {
                behaviors[_subject].mbs1.push(_time);
            }else if (_behaviorID == 2) {
                behaviors[_subject].mbs2.push(_time);
            }else{
                behaviors[_subject].mbs3.push(_time);
            }
            
            for (i=0;i < behaviors[_subject].mbs1.length; i++) {
                CrN = CrN + (evAttr.gamma / (_time - behaviors[_subject].mbs1[i])) * (evAttr.alpha[0]/10);
            }
            for (i=0;i < behaviors[_subject].mbs2.length; i++) {
                CrN = CrN + (evAttr.gamma / (_time - behaviors[_subject].mbs2[i])) * (evAttr.alpha[1]/10);
            }
            for (i=0;i < behaviors[_subject].mbs3.length; i++) {
                CrN = CrN + (evAttr.gamma / (_time - behaviors[_subject].mbs3[i])) * (evAttr.alpha[2]/10);
            }
            Tblocked = 2**CrN;
            if (now > behaviors[_subject].TimeofUnblock) {
                behaviors[_subject].TimeofUnblock = now + Tblocked;
            }else{
                behaviors[_subject].TimeofUnblock = behaviors[_subject].TimeofUnblock + Tblocked;
            }
            mc.updateTimeofUnblock(_subject,behaviors[_subject].TimeofUnblock);
        }else{
            behaviors[_subject].nbs[_behaviorID-1]++; 
            if (now < behaviors[_subject].TimeofUnblock) {
                for (i=0; i < 4; i++) {
                    CrP = CrP + behaviors[_subject].nbs[i] * (evAttr.omega[i]/10);
                }
                //keep CrP less than evAttr.N, because Treward must Less than or equal to Tblocked
                if (CrP > evAttr.N) {
                    CrP = evAttr.N;
                }
                Treward = CrP / evAttr.N * (behaviors[_subject].TimeofUnblock - now);
                behaviors[_subject].TimeofUnblock = behaviors[_subject].TimeofUnblock - Treward;
                mc.updateTimeofUnblock(_subject,behaviors[_subject].TimeofUnblock);
                for (i=0;i < 4; i++) {
                    behaviors[_subject].nbs[i] = 0;
                }
            }
        }
        emit isCalled(_subject, _ismisbehavior, _behavior, _time, CrN, Tblocked, CrP, Treward);
    }
}

contract Management {
    function getDeviceRelatedAddress(address _device, string memory _attrName) public view returns (address _attrValue);
    function updateTimeofUnblock(address _device, uint256 _TimeofUnblock) public;
}