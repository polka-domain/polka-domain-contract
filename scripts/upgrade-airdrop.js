const {ethers, upgrades} = require("hardhat");

async function main() {
    const Airdrop = await ethers.getContractFactory("Airdrop");
    const airdrop = await upgrades.upgradeProxy('0x1f023A6b25dD1729F69C001Bef2c0cd7Dc354124', Airdrop);
    console.log("Airdrop upgraded at: ", airdrop.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
