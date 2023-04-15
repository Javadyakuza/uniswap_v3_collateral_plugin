require('@nomicfoundation/hardhat-toolbox')

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      { version: '0.8.17' },
      { version: '0.7.6' },
      { version: '>=0.7.0' },
      { version: '>=0.6.8 <0.8.0' },
      { version: '0.8.18' },
      { version: '>=0.6.8 <=0.8.18' },
      { version: '0.6.8', settings: {} },
    ],
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 500,
      viaIR: true,
    },
  },
}
