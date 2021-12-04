import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();
  const tokenName = "Token Name";
  const tokenSymbol = "TOKENSYMBOL";
  const uri = "ipfs://uri/";
  const reflectionShare = 30;
  const tokenPrice = ethers.utils.parseUnits("1", 18);

  const ReflectionaryERC721 = await ethers.getContractFactory(
    "ReflectionaryERC721"
  );
  const master = await ReflectionaryERC721.deploy(
    tokenName,
    tokenSymbol,
    await owner.getAddress(),
    uri,
    reflectionShare,
    tokenPrice
  );

  await master.deployed();

  console.log("Contract deployed to:", master.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
