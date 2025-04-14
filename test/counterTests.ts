import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { Counter } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe('Counter', () => {
  let counter: (Counter & { deploymentTransaction(): ContractTransactionResponse; });
  let accounts : HardhatEthersSigner[];
  let owner: HardhatEthersSigner;

  const deployFixture = async () => {
    const Counter = await hre.ethers.getContractFactory('Counter')
    const _counter = await Counter.deploy()

    const _accounts = await hre.ethers.getSigners()
    return {_counter, _accounts}
  }
  beforeEach(async () => {
    const {_counter, _accounts} = await loadFixture(deployFixture)

    counter    =_counter
    accounts  =_accounts
    owner     = accounts[0]
  });

  it('Should deploy and set the owner correctly', async () => {
    expect(await counter.owner()).to.equal(owner.address);
  })
  
  it('Test is stateless', async () => {
    await counter.countUp()
    expect(await counter.counter()).to.equal(1);
  })
  
  it('Test is stateless 2', async () => {
    await counter.countUp()
    await counter.countUp()
    expect(await counter.counter()).to.equal(2);
  })
  
  it('Test is stateless 3', async () => {
    await counter.countUp()
    expect(await counter.counter()).to.equal(1);
  })
})
