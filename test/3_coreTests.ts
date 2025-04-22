import hre from "hardhat";
import { expect, assert } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { Core, TestERC721Token, TestERC20Token } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

type Cntrct<T> = T & { deploymentTransaction(): ContractTransactionResponse }

const M = 1000;
const MAX_PER_BET = 20;
const VIG = 100;
const END_TIME = 325546864;
enum EventState {
    "Pending",
    "Opened",
    "Paused",
    "Resolved",
    "Rejected",
    "Disqualified"
}

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
    let users : HardhatEthersSigner[];
    const fee = 100

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
        // Build some state
        // owner = acc 0
        await core.authAdminAdd(_accounts[1])
        await core.authProposerAdd(_accounts[2])
        await nft.safeMint(_accounts[3],0)
        // add fee
        core.configProposalFee(fee)
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
        [owner, admin, proposer, holder, ...users] = accounts
    });

    const propose = async (by : HardhatEthersSigner = owner ) => {
        await qusdt.mint(by, fee)
        await expect(core.connect(by).eventPropose("holders's event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
    }

    const accept = async (index: number) => {
        await core.eventAccept(index, MAX_PER_BET, M, VIG, END_TIME, "Sad betting")
    }

    const buy = async (wallet: HardhatEthersSigner = owner, event_id: number, option: number, amount: number) => {
        await token.mint(wallet,  amount)
        await token.approve(core, amount)
        await core.connect(wallet).wagerPlace(event_id, option, amount)
    }
    
    it("Read and write fee amount", async ()=>{
        await expect(core.configProposalFee(100)).to.not.be.reverted
        expect(await core._proposal_fee()).to.equal(100)
    })

    describe('Events (Privileged users) :', () => {
        it("Propose", async () => {
            // Every non user should be able to propose with enough qusdt
            // user
            await qusdt.mint(accounts[5], fee)
            await qusdt.connect(accounts[5]).approve(core, fee)
            await expect(core.connect(accounts[5]).eventPropose("admin's event", "desc\r\ndesc",["1: one", "2: two"])).to.be.reverted
            // admin
            await qusdt.mint(admin, fee)
            await qusdt.connect(admin).approve(core, fee)
            await expect(core.connect(admin).eventPropose("admin's event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
            // proposer
            await qusdt.mint(proposer, fee)
            await qusdt.connect(proposer).approve(core, fee)
            await expect(core.connect(proposer).eventPropose("proposers's event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
            // holder
            await qusdt.mint(holder, fee)
            await qusdt.connect(holder).approve(core, fee)
            await expect(core.connect(holder).eventPropose("holders's event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
            // owner
            await qusdt.mint(owner, fee)
            // not enough fund
            await qusdt.approve(core, fee-1)
            await expect(core.eventPropose("Failed event", "desc\r\ndesc",["1: one", "2: two"])).to.be.reverted
            // ok
            await qusdt.approve(core, fee)
            await expect(core.eventPropose("owners event", "desc\r\ndesc",["1: one", "2: two"])).to.not.be.reverted
        })

        it("Accept", async () => {
            // Depends on propose !!!!!
            await core.eventPropose("1st event", "desc\r\ndesc",["1: one", "2: two"])
            await core.eventPropose("2nd event", "desc\r\ndesc",["1: one", "2: two"])
            //proposers shouldnt be able
            await expect(core.connect(proposer).eventAccept(0, MAX_PER_BET, M, VIG, END_TIME, "Sad betting")).to.be.reverted
            //admins ok
            await expect(core.connect(admin).eventAccept(0, MAX_PER_BET, M, VIG, END_TIME, "Happy betting")).to.not.be.reverted
            const bet = await core._events(0)
            await expect(bet.fee_paid).to.be.equal(fee)
            await expect(bet.vig).to.be.equal(VIG)
            await expect(bet.end_time).to.be.equal(END_TIME)
            await expect(bet.max_per_one_bet).to.be.equal(MAX_PER_BET)
            await expect(bet.k).to.be.equal(M**2)
            //owner ok
            await expect(core.eventAccept(0, MAX_PER_BET, M, VIG, END_TIME, "Happy betting")).to.not.be.reverted
            //TODO possible only in Pending state
        })

        it("Reject", async () => {
            await core.eventPropose("1st event", "desc\r\ndesc",["1: one", "2: two"])
            await core.eventPropose("1st event", "desc\r\ndesc",["1: one", "2: two"])
            await expect(core.connect(holder).eventReject(0, "Such a shame")).to.be.reverted
            await expect(core.connect(admin).eventReject(0, "Such a shame")).to.not.be.reverted
            await expect(core.eventReject(0, "Such a shame")).to.not.be.reverted
            //TODO possible only in Pernding state
        })

        it("Toggle pause", async () => {
            await propose()
            await accept(0)
            await expect(core.connect(holder).eventTogglePause(0, "Temporory")).to.be.reverted
            await expect(core.connect(admin).eventTogglePause(0, "Temporory")).to.not.be.reverted
            //TODO possible only in running state
        })

        it("Resolve", async () => {
            await propose()
            await propose()
            await accept(0)
            await accept(1)
            await core.eventTogglePause(1, "test") // should be ok either way
            await expect(core.connect(holder).eventResolve(1, 1, "Won")).to.be.reverted
            await expect(core.connect(admin).eventResolve(0, 1, "Won")).to.not.be.reverted
            await expect(core.connect(owner).eventResolve(1, 1, "Won")).to.not.be.reverted
            //TODO possible only in running/paused state
        })

        it("Disq", async () => {
            await propose()
            await propose()
            await accept(0)
            await accept(1)
            await core.eventTogglePause(1, "test") // should be ok either way
            await expect(core.connect(holder).eventDisq(1, "Won")).to.be.reverted
            await expect(core.connect(admin).eventDisq(0, "Won")).to.not.be.reverted
            await expect(core.connect(owner).eventDisq(1, "Won")).to.not.be.reverted
            //TODO possible only in running/paused state
        })
    })
    
    describe('Normal users :', () => {
        it("Place wager", async () => {
            propose()
            accept(0)
            const user = accounts[4];
            token.mint(user, MAX_PER_BET*10)
            token.connect(user).approve(core, MAX_PER_BET*10)
            //over the limit per bet
            await expect(core.connect(user).wagerPlace(0, 1, MAX_PER_BET+1)).to.be.reverted
            //zero amount error
            await expect(core.connect(user).wagerPlace(0, 1, 0)).to.be.reverted
            //option not valid
            await expect(core.connect(user).wagerPlace(0, 2, MAX_PER_BET))
            //not possible when bet on pause
            await core.eventTogglePause(0, "") // This pauses
            await expect(core.connect(user).wagerPlace(0, 1, MAX_PER_BET)).to.be.reverted
            //ok
            await core.eventTogglePause(0, "") // This opens
            await expect(core.connect(user).wagerPlace(0, 1, MAX_PER_BET))
                .to.changeTokenBalances(token, [core, user], [+MAX_PER_BET,-MAX_PER_BET])
            await expect(core.connect(user).wagerPlace(0, 1, MAX_PER_BET-1))
                .to.changeTokenBalances(token, [core, user], [+MAX_PER_BET-1,-MAX_PER_BET+1])
            await expect(core.connect(user).wagerPlace(0, 0, MAX_PER_BET/2))
                .to.changeTokenBalances(token, [core, user], [+MAX_PER_BET/2,-MAX_PER_BET/2])
        })

        it("Claim on win", async () => {
            propose()
            accept(0)
            buy(users[0],0,1, MAX_PER_BET/1)
            buy(users[0],0,0, MAX_PER_BET/2)
            buy(users[1],0,0, MAX_PER_BET/3)
            buy(users[2],0,1, MAX_PER_BET/4)
            const bef = users.slice(0, 2).map((user)=> token.balanceOf(user))
            const before = await Promise.all(bef)
            // not ended
            await expect(core.connect(users[0]).wagerClaim(0)).to.be.reverted
            await core.eventResolve(0, 1, "2nd option won")
            await expect(core.connect(users[0]).wagerClaim(0)).to.not.be.reverted
            await expect(core.connect(users[1]).wagerClaim(0)).to.not.be.reverted
            await expect(core.connect(users[2]).wagerClaim(0)).to.not.be.reverted
            expect(await token.balanceOf(users[0])).to.not.be.equal(before[0]) // won some
            expect(await token.balanceOf(users[1])).to.be.equal(before[1])     // not won
            expect(await token.balanceOf(users[2])).to.not.be.equal(before[2]) // won all
        })
        
        it("Refund on DisQ", async () => {
            propose()
            accept(0)
            buy(users[0], 0,0 ,MAX_PER_BET)
            buy(users[0], 0,0 ,MAX_PER_BET)
            await core.eventDisq(0, "Wasnt cool")
            const amount = 
                (await core._wagers(0,users[0],0)).amount 
                + (await core._wagers(0,users[0],1)).amount
            await expect(core.wagerRefund).to.changeTokenBalances(token, [core, users[0]], [-amount, amount])
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