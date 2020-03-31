var Web3 = require('web3');
var readline = require('readline');
var web3 = new Web3(Web3.givenProvider || "ws://192.168.191.4:8545");

var accAbi = [
	{
		"constant": false,
		"inputs": [
			{
				"name": "_resource",
				"type": "string"
			},
			{
				"name": "_action",
				"type": "string"
			}
		],
		"name": "accessControl",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "rc",
		"outputs": [
			{
				"name": "",
				"type": "address"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "s",
				"type": "string"
			}
		],
		"name": "stringToUint",
		"outputs": [
			{
				"name": "result",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "pure",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_minInterval",
				"type": "uint256"
			},
			{
				"name": "_threshold",
				"type": "uint256"
			}
		],
		"name": "enAttiUpdate",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "jc",
		"outputs": [
			{
				"name": "",
				"type": "address"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "_subject",
				"type": "address"
			}
		],
		"name": "getTimeofUnblock",
		"outputs": [
			{
				"name": "_penalty",
				"type": "uint256"
			},
			{
				"name": "_timeOfUnblock",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_resource",
				"type": "string"
			},
			{
				"name": "_action",
				"type": "string"
			},
			{
				"name": "_attrOwner",
				"type": "string"
			},
			{
				"name": "_attrName",
				"type": "string"
			},
			{
				"name": "_operator",
				"type": "string"
			},
			{
				"name": "_attrValue",
				"type": "string"
			}
		],
		"name": "policyAdd",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "_resource",
				"type": "string"
			},
			{
				"name": "_action",
				"type": "string"
			},
			{
				"name": "_attrName",
				"type": "string"
			}
		],
		"name": "getPolicy",
		"outputs": [
			{
				"name": "_attrOwner",
				"type": "string"
			},
			{
				"name": "_attrName_",
				"type": "string"
			},
			{
				"name": "_operator",
				"type": "string"
			},
			{
				"name": "_attrValue",
				"type": "string"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_resource",
				"type": "string"
			},
			{
				"name": "_attrName",
				"type": "string"
			},
			{
				"name": "_attrValue",
				"type": "string"
			}
		],
		"name": "resourceAttrUpdate",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_resource",
				"type": "string"
			},
			{
				"name": "_action",
				"type": "string"
			}
		],
		"name": "policyDelete",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "subject",
				"type": "address"
			}
		],
		"name": "emitError",
		"outputs": [
			{
				"name": "penalty",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "_resource",
				"type": "string"
			},
			{
				"name": "_attrName",
				"type": "string"
			}
		],
		"name": "getResourceAttr",
		"outputs": [
			{
				"name": "_attrValue",
				"type": "string"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "owner",
		"outputs": [
			{
				"name": "",
				"type": "address"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_resource",
				"type": "string"
			},
			{
				"name": "_attrName",
				"type": "string"
			}
		],
		"name": "deleteResourceAttr",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_resource",
				"type": "string"
			},
			{
				"name": "_attrName",
				"type": "string"
			},
			{
				"name": "_attrValue",
				"type": "string"
			}
		],
		"name": "resourceAttrAdd",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [],
		"name": "deleteACC",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "evAttr",
		"outputs": [
			{
				"name": "minInterval",
				"type": "uint256"
			},
			{
				"name": "threshold",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"name": "_rc",
				"type": "address"
			},
			{
				"name": "_jc",
				"type": "address"
			}
		],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "_from",
				"type": "address"
			},
			{
				"indexed": false,
				"name": "_errmsg",
				"type": "string"
			},
			{
				"indexed": false,
				"name": "_result",
				"type": "bool"
			},
			{
				"indexed": false,
				"name": "_time",
				"type": "uint256"
			},
			{
				"indexed": false,
				"name": "_penalty",
				"type": "uint256"
			}
		],
		"name": "ReturnAccessResult",
		"type": "event"
	}
];

var accAddr = "0xb29094a4DE9c2E22b598b39fE38860b9117340A6"
var myACC = new web3.eth.Contract(accAbi, accAddr);


var previousTxHash = 0;
var currentTxHash = 0;

var rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout,
	prompt: 'Send access request?(y/n)'
});

rl.prompt();
rl.on('line',(answer) => {
	if('y' == answer) {
	myACC.methods.accessControl("data", "read").send({
			from: "0xbd93271c5d2ccacdc307d1825614d5557ad6e0fd",
			gas: 10000000,
			gasPrice: 0
		},function(error,result){
			if(!error){
				currentTxHash = result
				console.log("currentTxHash: ", result)
			}
		})

	myACC.events.ReturnAccessResult({
			fromBlock: 0
		}, function(error, result){
		if(!error) {
			if(previousTxHash != result.transactionHash && currentTxHash == result.transactionHash) {
				console.log("Contract: "+result.address);
				console.log("Block Number: "+result.blockNumber);
				console.log("Tx Hash: "+result.transactionHash);
				console.log("Block Hash: "+result.blockHash);
				console.log("Time: "+result.returnValues._time);
				console.log("Message: "+result.returnValues._errmsg);
				console.log("Result: "+result.returnValues._result);
				if (result.returnValues._penalty > 0) {
					console.log("Requests are blocked for " + result.returnValues._penalty +"seconds!")
				}
				console.log('\n');
				previousTxHash = result.transactionHash;
				rl.prompt();
			}
		}
	})
	}
	else{
	console.log("access request doesn't send!")
	rl.prompt();
	}
}).on('close',() =>{
	console.log('All actions had executed!');
	process.exit(0);
});





