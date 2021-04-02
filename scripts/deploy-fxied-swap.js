const { ethers, upgrades } = require("hardhat");

async function main() {
  const TokenFixedSwap = await ethers.getContractFactory("TokenFixedSwap");
  const tokenFixedSwap = await upgrades.deployProxy(TokenFixedSwap);
  await tokenFixedSwap.deployed();
  console.log("TokenFixedSwap deployed to:", tokenFixedSwap.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
