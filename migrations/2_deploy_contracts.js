let ERC20 = artifacts.require('./TestERC20.sol');
let Freelance = artifacts.require('./Freelance.sol');

module.exports = function (deployer) {
  deployer.deploy(ERC20).then(erc20 =>{
    deployer.deploy(Freelance,erc20.address);
  });
  
};
