const {ethers, upgrades} = require("hardhat");

async function main() {
    const signer = '0x36f302d5fd122ac9f1dd6d5d2600e28f059b45d9';
    const nameAddress = '0xe1A4c5BBb704a92599FEdB191f451E0d3a1ed842';
    const from = '0x3a5CAd53cA5B80b435dF0C95900A42Ed1bE60eD6';
    const amount = ethers.utils.parseEther('20');
    const startAt = 1618581600; // 2021-04-16 22:00:00
    const Airdrop = await ethers.getContractFactory("Airdrop");
    const airdrop = await upgrades.deployProxy(Airdrop, [signer, nameAddress, from, amount, startAt]);
    await airdrop.deployed();
    console.log("Airdrop deployed to:", airdrop.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
