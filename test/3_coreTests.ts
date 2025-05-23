import hre from "hardhat";
import { expect, assert } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { Core, TestERC721Token, TestERC20Token } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

type Cntrct<T> = T & { deploymentTransaction(): ContractTransactionResponse }

const PROPOSAL = {
    "title":"Test",
    "desc" : "ends in this circumstances by this time",
    "options":[
        {
            "id": "1",
            "title":"First",
        },
        {
            "id": "2",
            "title":"Second",
        },
    ]
}
const PROPOSAL_TEXT = JSON.stringify(PROPOSAL)
const M = 500;
const MAX_PER_BET = 20;
const VIG = 100;
const END_TIME = 325546864;

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
    const FEE = 100

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
        await _core.authAdminAdd(_accounts[1])
        await _core.authProposerAdd(_accounts[2])
        await _core.authNftAdd(_nft)
        await _nft.safeMint(_accounts[3],0)
        // add FEE
        await _core.configProposalFee(FEE)
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
        await qusdt.mint(by, FEE)
        await qusdt.approve(core, FEE)
        await expect(core.connect(by).eventPropose(PROPOSAL_TEXT)).to.not.be.reverted
    }

    const togglePause = async (index: number) => {
        await core.eventTogglePause(index, " ");
    }

    const accept = async (index: number) => {
        await core.eventAccept(index, MAX_PER_BET, M, 2, VIG, PROPOSAL_TEXT)
        await togglePause(index)
    }

    const buy = async (wallet: HardhatEthersSigner = owner, event_id: number, option: number, amount: number) => {
        await token.mint(wallet,  amount)
        await token.connect(wallet).approve(core, amount)
        // console.log(amount, await token.balanceOf(wallet), await token.allowance(wallet, core))
        await core.connect(wallet).wagerPlace(event_id, option, amount)
    }
    
    it("Read and write FEE amount", async ()=>{
        await expect(core.configProposalFee(100)).to.not.be.reverted
        expect(await core._proposal_fee()).to.equal(100)
    })

    describe('Events (Privileged users) :', () => {
        it("Propose", async () => {
            // Every non user should be able to propose with enough qusdt
            // user
            await qusdt.mint(accounts[5], FEE)
            await qusdt.connect(accounts[5]).approve(core, FEE)
            await expect(core.connect(accounts[5]).eventPropose(PROPOSAL_TEXT)).to.be.reverted
            // admin
            await qusdt.mint(admin, FEE)
            await qusdt.connect(admin).approve(core, FEE)
            await expect(core.connect(admin).eventPropose(PROPOSAL_TEXT)).to.not.be.reverted
            // proposer
            await qusdt.mint(proposer, FEE)
            await qusdt.connect(proposer).approve(core, FEE)
            await expect(core.connect(proposer).eventPropose(PROPOSAL_TEXT)).to.not.be.reverted
            // holder
            await qusdt.mint(holder, FEE)
            await qusdt.connect(holder).approve(core, FEE)
            await expect(core.connect(holder).eventPropose(PROPOSAL_TEXT)).to.not.be.reverted
            // owner
            await qusdt.mint(owner, FEE)
            // not enough fund
            await qusdt.approve(core, FEE-1)
            await expect(core.eventPropose(PROPOSAL_TEXT)).to.be.reverted
            // ok
            await qusdt.approve(core, FEE)
            await expect(core.eventPropose(PROPOSAL_TEXT))
                .to.changeTokenBalances(qusdt, [core, owner], [FEE, -FEE])
        })

        it("Accept", async () => {
            // Depends on propose !!!!!
            await propose()
            await propose()
            //proposers shouldnt be able
            await expect(core.connect(proposer).eventAccept(0, 1_000_000,1_000,2,10,PROPOSAL_TEXT)).to.be.reverted
            //admins ok
            await expect(core.connect(admin).eventAccept(0, MAX_PER_BET, M, 2, VIG, PROPOSAL_TEXT)).to.not.be.reverted
            const bet = await core._events(0)
            await expect(bet.vig).to.be.equal(VIG)
            await expect(bet.max_per_one_bet).to.be.equal(MAX_PER_BET)
            //owner ok
            await expect(core.eventAccept(1, 1_000_000,1_000,2,10,PROPOSAL_TEXT)).to.not.be.reverted
            // possible only in Pending state
            await expect(core.eventAccept(0, 1_000_000,1_000,2,10,PROPOSAL_TEXT)).to.be.reverted
        })

        it("Reject", async () => {
            await propose()
            await propose()
            await expect(core.connect(holder).eventReject(0, "Such a shame")).to.be.reverted
            await expect(core.connect(admin).eventReject(0, "Such a shame")).to.not.be.reverted
            await expect(core.eventReject(1, "Such a shame")).to.not.be.reverted
            // possible only in Pernding state
            await expect(core.eventReject(1, "Such a shame")).to.be.reverted
        })

        it("Toggle pause", async () => {
            await propose()
            await accept(0)
            await expect(core.connect(holder).eventTogglePause(0, "Temporory")).to.be.reverted
            await expect(core.connect(admin).eventTogglePause(0, "Temporory")).to.not.be.reverted
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
            await propose()
            await accept(0)
            const user = accounts[4];
            await token.mint(user, MAX_PER_BET*10)
            await token.connect(user).approve(core, MAX_PER_BET*10)
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
            await token.mint(core, MAX_PER_BET*10)
            await propose()
            await accept(0)
            const winner_option = 1;
            const loser_option = 0;
            await buy(users[3],0,winner_option, Math.floor(MAX_PER_BET/1)) //0
            await buy(users[3],0,loser_option , Math.floor(MAX_PER_BET/2)) //1
            await buy(users[4],0,loser_option , Math.floor(MAX_PER_BET/3)) //0
            await buy(users[5],0,winner_option, Math.floor(MAX_PER_BET/4)) //0
            const bef = users.slice(2).map((user)=> token.balanceOf(user))
            const before = await Promise.all(bef)
            // not ended
            await expect(core.connect(users[3]).wagerClaim(0,0)).to.be.reverted
            await core.eventResolve(0, winner_option, "2nd option won")
            expect((await core._events(0)).state==0n)
            expect(Number((await core._events(0)).winner) == winner_option)
            await expect(core.connect(users[3]).wagerClaim(0,0)).to.not.be.reverted
            await expect(core.connect(users[3]).wagerClaim(0,1)).to.be.reverted
            await expect(core.connect(users[4]).wagerClaim(0,0)).to.be.reverted
            await expect(core.connect(users[5]).wagerClaim(0,0)).to.not.be.reverted
            expect(await token.balanceOf(users[3])).to.not.be.equal(before[0]) // won some
            expect(await token.balanceOf(users[4])).to.be.equal(before[1])     // not won
            expect(await token.balanceOf(users[5])).to.not.be.equal(before[2]) // won all
        })
        
        it("Refund on DisQ", async () => {
            await propose()
            await accept(0)
            await buy(users[0], 0,0 ,MAX_PER_BET)
            await buy(users[0], 0,1 ,MAX_PER_BET)
            await core.eventDisq(0, "Wasnt cool")
            await expect(core.connect(users[0]).wagerRefund(0, 0)).to.changeTokenBalances(token, [core, users[0]], [-MAX_PER_BET, MAX_PER_BET])
            await expect(core.connect(users[0]).wagerRefund(0, 1)).to.changeTokenBalances(token, [core, users[0]], [-MAX_PER_BET, MAX_PER_BET])
        })
    })

    describe('Client app :', () => {
        it("Access bet meta from event", async () => {
            await propose()
            await expect(core._events_metas(0)).to.be.reverted
            await accept(0)
            expect((await core._events_metas(0)).metas).to.equal(PROPOSAL_TEXT)
        })
        
        it("Access wager meta", async () => {
            await propose()
            await accept(0)
            await expect(core._wagers(0, users[2], 0)).to.be.reverted
            await buy(users[2], 0, 0, MAX_PER_BET)
            await expect(core._wagers(0, users[2], 0)).to.not.be.reverted
        })
    })
})