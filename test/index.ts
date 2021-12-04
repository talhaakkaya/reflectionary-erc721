import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract, Signer, BigNumber } from "ethers";

describe("ReflectionaryERC721", function () {
  let master: Contract;
  let owner: Signer;
  let minters: Array<Signer>;
  const mintPrice = "1000000000000000000";
  const dev = "0xce53Ba105448278C192DD8Dda4273af2A49a6C93";

  beforeEach(async () => {
    [owner, ...minters] = await ethers.getSigners();

    const master_ = await ethers.getContractFactory("ReflectionaryERC721");
    master = await master_.deploy(
      "Test Token",
      "TEST",
      dev,
      "ipfs://testuri/",
      30,
      mintPrice
    );
    await master.deployed();
  });

  it("Should deploy", async () => {
    const tokenName = await master.name();
    const tokenSymbol = await master.symbol();
    const sale = await master.isSaleActive();
    const reflection = await master.reflection();
    const price = await master.price();

    expect(tokenName).to.be.equal("Test Token");
    expect(tokenSymbol).to.be.equal("TEST");
    expect(sale).to.be.equal(false);
    expect(reflection).to.be.equal(BigNumber.from("30"));
    expect(price).to.be.equal(BigNumber.from(mintPrice));
  });

  it("Should mint tokens", async () => {
    await master.switchSaleState();
    const numberOfTokens = 20;
    const price = BigNumber.from(mintPrice).mul(BigNumber.from(numberOfTokens));
    await master.mintTokens(numberOfTokens, { value: price });

    // check dev balance
    const estDevBalance = price.sub(await master.reflectionBalance());
    const devBalance = await ethers.provider.getBalance(dev);
    expect(devBalance).to.be.equal(estDevBalance);

    // check minter balance
    expect(await master.getReflectionBalances()).to.be.equal(
      await master.reflectionBalance()
    );
  });

  it("Should claim rewards before transfer", async () => {
    await master.switchSaleState();

    await master.mintTokens(1, { value: mintPrice });

    await master.transferFrom(
      await owner.getAddress(),
      await minters[0].getAddress(),
      0
    );

    const reflectionBalance = await master.getReflectionBalance(0);
    expect(reflectionBalance).to.be.equal(BigNumber.from("0"));
  });

  it("Should not hold more than 100", async () => {
    await master.switchSaleState();

    for (let i = 0; i < 5; i++) {
      const numberOfTokens = 20;
      const price = BigNumber.from(mintPrice).mul(
        BigNumber.from(numberOfTokens)
      );
      await master.mintTokens(numberOfTokens, { value: price });
    }

    await expect(master.mintTokens(1, { value: mintPrice })).to.be.reverted;
  });
});
