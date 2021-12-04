import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  const ReflectionaryERC721 = await ethers.getContractFactory(
    "ReflectionaryERC721"
  );
  const master = await ReflectionaryERC721.deploy(
    "Token Name",
    "TOKENSYM",
    await owner.getAddress(),
    "ipfs://uri/",
    30,
    "1000000000000000000"
  );

  await master.deployed();

  console.log("Contract deployed to:", master.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
