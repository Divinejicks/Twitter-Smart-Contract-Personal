const hre = require("hardhat");

const main = async () => {
    const Twitter = await hre.ethers.getContractFactory("Twitter");
    const twitter = await Twitter.deploy();

    await twitter.deployed();
    console.log("Twitter deployed on ", twitter.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    })