 pragma solidity >=0.4.22 <0.6.0;

contract Judge {
    uint public base;
    uint public inteval;
    address public owner;
    
    event isCalled(address _from, uint _time, uint _penalty);
    
    struct Misbehavior{
        address subject;   //subject who performed the misbehavior 
        address device;
        string resource;
        string action;   //action (e.g., "read","write","execute") of the misbehavior
        string misbehavior;
        uint time;   //block timestamp of the Misbehavior ocured
        uint penalty;   //penalty (number of minitues blocked)
    }
    
    mapping (address => Misbehavior[]) public MisbehaviorList;
    
    constructor(uint  _base, uint  _inteval) public {
        require(_inteval != 0);
        base = _base;
        inteval = _inteval;
        owner = msg.sender;
    }
    
    function misbehaviorJudge(
        address _subject, 
        address  _device, 
        string memory _resource,
        string memory _action,
        string memory _misbehavior,
        uint  _time) 
        public returns (uint  penalty) 
    {
        uint length = MisbehaviorList[_subject].length + 1;
        uint n = length/inteval;
        penalty = base**n;
        MisbehaviorList[_subject].push(Misbehavior(_subject, _device, _resource, _action, _misbehavior, _time, penalty));
        emit isCalled(msg.sender, _time, penalty);
    }
    
    function getLatestMisbehavior(address _requester) public view 
        returns (address _subject, address _device, string memory _resource, string memory _action, string memory _misbehavior, uint _time)
    {
        uint latest = MisbehaviorList[_requester].length  - 1;
        _subject = MisbehaviorList[_requester][latest].subject;
        _device = MisbehaviorList[_requester][latest].device;
        _resource = MisbehaviorList[_requester][latest].resource;
        _action = MisbehaviorList[_requester][latest].action;
        _misbehavior = MisbehaviorList[_requester][latest].misbehavior;
        _time = MisbehaviorList[_requester][latest].time;
    }
}