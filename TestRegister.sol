pragma solidity >=0.4.22 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Register.sol";


contract TestRegister {
    Register reg;
    address JCcreator = address(0xbfFe4ff0cBd0A7590Fb71966D1E6bb1a4c2359e0);
    address JCaddress = address(0x2C2Fb0DD2440e72318Fb018f923F78Ff86541D08);
    address newJCaddress = address(0xb29094a4DE9c2E22b598b39fE38860b9117340A6);
    address deviceAddress = address(0x016B71d115f1DA36dE58D2B78369fd3228BeF3DD);
    address deviceManager = address(0xA31D40508dA63fb00d7e2F4db57c3774384aa299);
    address newdeviceManager = address(0x27b2e6492929683d6A60838526B942c80ceC1327);

    function beforeAll() public {
       reg = new Register();
    }
    
    function testContractRegister() public {
        reg.contractRegister("Judger", "JC", JCcreator, JCaddress);
        Assert.equal(reg.getContractAddr("Judger"), JCaddress, "Judge contract not register");
    }

    function testUpdateContractinf() public {
        reg.updateContractinf("Judger", "scAddress", newJCaddress);
        Assert.equal(reg.getContractAddr("Judger"), newJCaddress, "Judge contract address aleady changed");
    }

    function testDeleteContract() public {
        reg.deleteContract("Judger");
    }

    function testSubjectRegister() public {
        reg.subjectRegister(deviceAddress, deviceManager, "thermostat", "subject");
        Assert.equal(reg.getAttribute(deviceAddress, "deviceType"), "thermostat", "deviceType should be thermostat");
    }

    function testAddAttribute() public {
        reg.addAttribute(deviceAddress, "currentState", "active");
        Assert.equal(reg.getAttribute(deviceAddress, "currentState"), "active", "device should be active");
    }

    function testUpdateAttrValue() public {
        reg.updateAttrValue(deviceAddress, "deviceType", "camera");
        Assert.equal(reg.getAttribute(deviceAddress, "deviceType"), "camera", "deviceType should be camera");
    }

    function testupdateManager() public {
        reg.updateManager(deviceAddress, newdeviceManager);
    }

    function testDeleteAttribute() public {
        reg.deleteAttribute(deviceAddress, "currentState");
    }

    function testDeleteDevice() public {
        reg.deleteDevice(deviceAddress);
    }
}

