import { expect, assert } from "chai";
import hre from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { ContractTransactionResponse, ZeroAddress } from "ethers";
import { TestERC20Token, TestTreasuryWrapper } from "../typechain-types";

describe('Finance', () => {
    let token    : TestERC20Token       & { deploymentTransaction(): ContractTransactionResponse };
    let treasury : TestTreasuryWrapper  & { deploymentTransaction(): ContractTransactionResponse };
    let accounts : HardhatEthersSigner[];
    let owner    : HardhatEthersSigner;

    const deployFixture = async () => {
        // Get accounts
        const _accounts = await hre.ethers.getSigners()
        // Deploy token contract
        const Token = await hre.ethers.getContractFactory('TestERC20Token')
        const _token = await Token.deploy(_accounts[0].address)
        // Deploy treasury contract
        const Treasury = await hre.ethers.getContractFactory('TestTreasuryWrapper')
        const _treasury = await Treasury.deploy(await _token.getAddress())
        return {_token, _treasury, _accounts}
    }
    beforeEach(async () => {
        const {_token, _treasury, _accounts} = await loadFixture(deployFixture)

        token    = _token
        treasury = _treasury
        accounts =_accounts
        owner    = accounts[0]
    });

    it("Collect from addresses (treasury_collenct)",async ()=>{ 
        await token.mint(accounts[2], 10_000)
        await token.connect(accounts[2]).approve(treasury, 100)
        await expect(treasury.treasury_collect_wrapper(accounts[2], 100))
            .to.changeTokenBalances(token, [treasury,accounts[2]], [+100, -100])
    })

    it("Give to addresses (treasury_give)",async ()=>{ 
        await token.mint(treasury, 10_000)
        await expect(treasury.treasury_give_wrapper(accounts[2], 100))
            .to.changeTokenBalances(token, [treasury, accounts[2]], [-100, 100])
    })

    it("Total money in the treasury (treasuryFund)",async ()=>{ 
        assert(await treasury.treasuryFund() == await token.balanceOf(treasury))
        await token.mint(treasury, 10_000)
        assert(await treasury.treasuryFund() == await token.balanceOf(treasury))
    })

    /*
     *  fund should be over some percent of the total supply in circulation
     *  only by owner
     *  shouldnt be able to make fund under the percentage
     *  shouldnt count owned by 0x0..0 as in circulation
     *  treasuryWithdraw, treasuryFund, treasury_give
     */
    it("treasuryWithdraw when fund over threshold", async ()=>{
        // Gets withdraw percent
        expect(await treasury._treasury_withdraw_threshold()).to.be.above(0)
        const percent = Number(await treasury._treasury_withdraw_threshold())/100
        // Not possible when even 1 token below percent
        await token.mint(accounts[2], (10_000*(100-percent))+1)
        await token.mint(treasury ,   (10_000*(percent))-1)
        await expect(treasury.treasuryWithdraw(1)).to.be.reverted
        // Fails to withdraw 2 when 1 above percent
        await token.connect(accounts[2]).transfer(treasury, 2)
        await expect(treasury.treasuryWithdraw(2)).to.be.reverted
        // Adding money to zero address wont affect the percentage
        // (Now 90 percent of the total supply is in zero address)
        await token.mint(owner, 90_000_000)
        await token.burn(90_000_000)
        // And normal user dont access this function
        await expect(treasury.connect(accounts[2]).treasuryWithdraw(1)).to.be.reverted
        // But the owner successfully withdraws 1
        await expect(treasury.treasuryWithdraw(1))
            .to.changeTokenBalances(token, [owner, treasury], [1, -1])
    })
})
