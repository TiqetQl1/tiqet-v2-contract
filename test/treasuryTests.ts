import { expect, assert } from "chai";
import hre from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ContractTransactionResponse } from "ethers";
import { TiQetCoin, Treasury } from "../typechain-types";

describe('Finance', () => {
    let token    : TiQetCoin & { deploymentTransaction(): ContractTransactionResponse };
    let treasury : Treasury  & { deploymentTransaction(): ContractTransactionResponse };
    let accounts : HardhatEthersSigner[];
    let owner    : HardhatEthersSigner;

    const deployFixture = async () => {
        // Get accounts
        const _accounts = await hre.ethers.getSigners()
        // Deploy token contract
        const Token = await hre.ethers.getContractFactory('TiQetCoin')
        const _token = await Token.deploy(_accounts[0].address)
        // Deploy treasury contract
        const Treasury = await hre.ethers.getContractFactory('Treasury')
        const _treasury = await Treasury.deploy()
        // Disturbute tokens
        _token.mint(await _treasury.getAddress(), 10_000)
        _token.mint(accounts[2].address, 10_000)
        _token.mint(accounts[6].address, 10_000)
        return {_token, _treasury, _accounts}
    }
    beforeEach(async () => {
        const {_token, _treasury, _accounts} = await loadFixture(deployFixture)

        token    = _token
        treasury = _treasury
        accounts =_accounts
        owner    = accounts[0]
    });

    it("Collect from addresses",async ()=>{ 
        assert(false)
        //TODO...
    })

    it("Collect from addresses",async ()=>{ 
        assert(false)
        //TODO...
    })

    it("Collect from addresses",async ()=>{ 
        assert(false)
        //TODO...
    })
})
