## Peers and Accounts

RC(deployed by node0) address: 0x8980FC2bBD25958d0c72F5ba5fa3e5faF1A48c05

JC(deployed by node0) address: 0x2C2Fb0DD2440e72318Fb018f923F78Ff86541D08

ACC(deployed by lightnode1) address: 0xb29094a4DE9c2E22b598b39fE38860b9117340A6



node0 account address：0xbffe4ff0cbd0a7590fb71966d1e6bb1a4c2359e0

lightnode1 gateway account address：0x27b2e6492929683d6a60838526b942c80cec1327
lightnode1 sensor account address：0x878866354d3d4ec38eed508a1bc6f8f2fd9d2211

lightnode2 gateway account address：0xddc2f6498688fec01e170cd4423f9171294758b9
lightnode2 thermostat account address：0xbd93271c5d2ccacdc307d1825614d5557ad6e0fd
lightnode2 camera account address： 0x4185f786eb34e052823528c78ea13c937fe05ab2

rpc port：22000
websocket port：8545



## Deploy Result

We deploy smart contracts using Truffle console. There is the result of the RC and JC.

```js
Compiling your contracts...
===========================
> Everything is up to date, there is nothing to compile.



Starting migrations...
======================
> Network name:    'development'
> Network id:      10
> Block gas limit: 0xc454588d


1_initial_migration.js
======================

   Deploying 'Migrations'
   ----------------------
   > transaction hash:    0x5cbd3d61a95febd541079066f92ebabdafb03d707c6fef08ab01fc3303f23712
   > Blocks: 0            Seconds: 4
   > contract address:    0x4EC4F8BA5aEcA93955f67CFA58dbe4C57b21b37c
   > block number:        542
   > block timestamp:     0x5e09b9f0
   > account:             0xbfFe4ff0cBd0A7590Fb71966D1E6bb1a4c2359e0
   > balance:             99999999999999999999999999999998
   > gas used:            263741
   > gas price:           0 gwei
   > value sent:          0 ETH
   > total cost:          0 ETH


   > Saving migration to chain.
   > Saving artifacts
   -------------------------------------
   > Total cost:                   0 ETH


2_deploy_contracts.js
=====================

   Deploying 'Register'
   --------------------
   > transaction hash:    0x427e37c5af7aae563bee7049e303b2040964d0860ebed1d10b5afbf997388506
   > Blocks: 0            Seconds: 4
   > contract address:    0x8980FC2bBD25958d0c72F5ba5fa3e5faF1A48c05
   > block number:        544
   > block timestamp:     0x5e09b9fa
   > account:             0xbfFe4ff0cBd0A7590Fb71966D1E6bb1a4c2359e0
   > balance:             99999999999999999999999999999998
   > gas used:            3227930
   > gas price:           0 gwei
   > value sent:          0 ETH
   > total cost:          0 ETH


   Deploying 'Judge'
   -----------------
   > transaction hash:    0xd24c7912d95032da9a91e9711b1ae39dd90fcd1f03ac74eaf3d78d8723af7a65
   > Blocks: 0            Seconds: 4
   > contract address:    0x2C2Fb0DD2440e72318Fb018f923F78Ff86541D08
   > block number:        545
   > block timestamp:     0x5e09b9ff
   > account:             0xbfFe4ff0cBd0A7590Fb71966D1E6bb1a4c2359e0
   > balance:             99999999999999999999999999999998
   > gas used:            1349320
   > gas price:           0 gwei
   > value sent:          0 ETH
   > total cost:          0 ETH


   > Saving migration to chain.
   > Saving artifacts
   -------------------------------------
   > Total cost:                   0 ETH


Summary
=======
> Total deployments:   3
> Final cost:          0 ETH
```

## Command Reference

admin.peers: 查看已连接节点
eth.getBalance(eth.accounts[1]): 查看账户余额
personal.unlockAccount(eth.accounts[0]): 解锁账户
eth.pendingtranstraction：查看交易池中交易的详细信息
txpool.content：查看交易池中交易的详细信息
eth.blockNumber：查看当前区块号
txpool.inspect：查看交易池简单信息
txpool.status：查看交易池当前状态



