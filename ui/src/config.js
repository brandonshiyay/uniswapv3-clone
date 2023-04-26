const config = {
  token0Address: '0x38AEa5f740A3865507a6C021EA69d0970a5269fC',
  token1Address: '0xbDc533eFC51dB6fa5A1a175770ec2566A114D998',
  poolAddress: '0x1C934f1fc91a44EA99a43B63aF6B72B6F9f32334',
  managerAddress: '0x24C7466Ab15d52b3C75011B62F2aD9D20246fdC2',
  quoterAddress: '0xD7314A78282Eb07106d572E63A002d58BF729f3c',
  ABIs: {
    'ERC20': require('./abi/ERC20.json'),
    'Pool': require('./abi/Pool.json'),
    'Manager': require('./abi/Manager.json'),
    'Quoter': require('./abi/Quoter.json')
  }
};

export default config;