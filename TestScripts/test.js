var Web3 = require('web3');

if(typeof web3 !=='undefined'){ //检查是否已有web3实例
    web3=new Web3(web3.currentProvider);
}else{
    //否则就连接到给出节点
    web3=new Web3();
    web3.setProvider(new Web3.providers.WebsocketProvider("ws://localhost:8545"));
};

var connect = function() {
    web3.eth.getBlock(0, function(error, result){
        if(!error)
            console.log("connection succeed");
        else
            console.log("something wrong, connection failed");
    });
}


var getAccount = async function() {
    await connect();
    var account0;
    web3.eth.getAccounts(function(error, result){
        if(!error){
            account0=result[0];
            //console.log(account0);
            console.log("accounts:"+result);
        }
        else{
            console.log("failed to get Accoutns");
        }
    });
}


getAccount().then(function() {
    web3.eth.getBalance("0xbffe4ff0cbd0a7590fb71966d1e6bb1a4c2359e0").then(function(balance) {
        console.log('balance:',balance);
        console.log("test passed！");
    })
})

