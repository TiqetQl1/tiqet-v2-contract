import hre from "hardhat";
import { expect, assert } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { Core, TestERC721Token, TestERC20Token } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

type Cntrct<T> = T & { deploymentTransaction(): ContractTransactionResponse }

describe('BettingSystem', () => {
    let qusdt    : Cntrct<TestERC20Token>
    let token    : Cntrct<TestERC20Token>
    let nft      : Cntrct<TestERC721Token>
    let core     : Cntrct<Core>
    let accounts : HardhatEthersSigner[];
    let owner : HardhatEthersSigner;
    let admin : HardhatEthersSigner;
    let proposer : HardhatEthersSigner;
    let holder : HardhatEthersSigner;

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
        const _qusdt = await TestERC20Token.deploy(_accounts[0])
        const _core  = await Core.deploy(await _token.getAddress(), await _qusdt.getAddress())
        // Return
        return {_token, _qusdt, _nft, _core, _accounts}
    }
    beforeEach(async () => {
        // Revert snapshot
        const {_nft, _qusdt, _token, _core, _accounts} = await loadFixture(deployFixture)
        // Ready to use
        nft      = _nft
        qusdt    = _qusdt
        token    = _token
        core     = _core
        accounts =_accounts;
        [owner, admin, proposer, holder] = accounts
    });
    
    it("Read and write fee amount", ()=>{
        await expect(core.configProposalFee(100)).to.not.be.reverted
        expect(await core._proposal_fee()).to.equal(100)
    })

    describe('Events (Privileged users) :', () => {
        it("Propose", async () => {
            // Every non user should be able to propose with enough qusdt
            await expect(core.configProposalFee(100)).to.not.be.reverted
            const fee = await core._proposal_fee()
            expect(fee).to.be.greaterThan(0)
            // admin
            await qusdt.mint(admin, fee)
            await qusdt.connect(admin).approve(core, fee)
            await core.authAdminAdd(admin)
            await expect(core.connect(admin).eventPropose("admin's event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
            // proposer
            await qusdt.mint(proposer, fee)
            await qusdt.connect(proposer).approve(core, fee)
            await core.authProposerAdd(proposer)
            await expect(core.connect(proposer).eventPropose("proposers's event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
            // holder
            await qusdt.mint(holder, fee)
            await qusdt.connect(holder).approve(core, fee)
            await nft.safeMint(holder,0)
            await expect(core.connect(holder).eventPropose("holders's event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
            // owner
            await qusdt.mint(owner, fee)
            // not enough fund
            await qusdt.approve(core, fee-1n)
            await expect(core.eventPropose("admin's event", "desc\r\ndesc",["1: one", "2: two"])).to.be.reverted
            // ok
            await qusdt.approve(core, fee)
            await expect(core.eventPropose("admin's event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
        })

        it("Accept", async () => {
            //admins shouldnt be able to
            const admin = 
            //owner
        })

        it("Reject", async () => {
            assert(false)
            // TODO
        })

        it("Toggle pause", async () => {
            assert(false)
            // TODO
        })

        it("End", async () => {
            assert(false)
            // TODO
        })

        it("Disq", async () => {
            assert(false)
            // TODO
        })
    })
    
    describe('Normal users :', () => {
        it("Place wager", async () => {
            assert(false)
            // TODO
        })

        it("Claim on win", async () => {
            assert(false)
            // TODO
        })
        
        it("Refund on DisQ", async () => {
            assert(false)
            // TODO
        })
    })

    describe('Client app :', () => {
        it("Access bet meta from event", async () => {
            assert(false)
            // TODO
        })
        
        it("Access wager meta", async () => {
            assert(false)
            // TODO
        })
    })
})