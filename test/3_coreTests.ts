import hre from "hardhat";
import { expect, assert } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { Core, TestERC721Token, TestERC20Token } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe('BettingSystem', () => {
    let token    : TestERC20Token   & { deploymentTransaction(): ContractTransactionResponse };
    let nft      : TestERC721Token  & { deploymentTransaction(): ContractTransactionResponse };
    let core     : Core & { deploymentTransaction(): ContractTransactionResponse };
    let accounts : HardhatEthersSigner[];
    let owner    : HardhatEthersSigner;

    const deployFixture = async () => {
        // Accounts
        const _accounts = await hre.ethers.getSigners()
        // Load factories
        const TestERC721Token = await hre.ethers.getContractFactory('TestERC721Token')
        const TestERC20Token  = await hre.ethers.getContractFactory('TestERC20Token')
        const Core = await hre.ethers.getContractFactory('Core')
        // Make instances
        const _nft   = await TestERC721Token.deploy(_accounts[0])
        const _token = await TestERC20Token.deploy(_accounts[0])
        const _core  = await Core.deploy(await _token.getAddress())
        // Return
        return {_token, _nft, _core, _accounts}
    }
    beforeEach(async () => {
        // Revert snapshot
        const {_nft, _token, _core, _accounts} = await loadFixture(deployFixture)
        // Ready to use
        nft      = _nft
        token    = _token
        core     = _core
        accounts =_accounts
        owner    = accounts[0]
    });

    it("hi", async () => {
        assert(true)
    })
})