const medical = artifacts.require("medical");

module.exports = function(deployer) {
  deployer.deploy(medical);
};
