import { expect, assert } from "chai";
import hre from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { AccessControl } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";

describe('Auth', () => {
    let accessControl : (AccessControl & { deploymentTransaction(): ContractTransactionResponse });
    let accounts : HardhatEthersSigner[];
    let owner: HardhatEthersSigner;

    const deployFixture = async () => {
        const AccessControl = await hre.ethers.getContractFactory('AccessControl')
        const _accessControl = await AccessControl.deploy()

        const _accounts = await hre.ethers.getSigners()
        return {_accessControl, _accounts}
    }
    beforeEach(async () => {
        const {_accessControl, _accounts} = await loadFixture(deployFixture)

        accessControl = _accessControl
        accounts  =_accounts
        owner     = accounts[0]
    });

    it("Deployer is the owner",async ()=>{ 
        assert(await accessControl._owner() == owner.address, "Owner is not the first signer")
    })

    it("Owner can change ownership",async ()=>{ 
        await expect(accessControl.connect(accounts[5]).authOwnershipTransfer(accounts[4]), "NOT RESTRICTED ACCESS").to.reverted
        await accessControl.authOwnershipTransfer(accounts[5].address)
        expect(await accessControl._owner()).to.equal(accounts[5].address, "Owner is not changed to acc 5")
    })

    it("CRUD on admins",async ()=>{ 
        // there is no admin
        await expect(accessControl._admins(0)).to.reverted
        // the addAdmin function returns true
        await expect(accessControl.authAdminAdd(accounts[2].address)).to.not.be.reverted
        // admin is added
        expect(await accessControl._admins(0)).to.equal(accounts[2].address, "admin is not added")
        // same for second admin
        expect(await accessControl.authAdminAdd(accounts[5].address)).to.not.be.reverted
        expect(await accessControl._admins(1)).to.equal(accounts[5].address, "2nd admin is not added")
        // drop the first admin
        expect(await accessControl.authAdminRem(accounts[2].address)).to.not.be.reverted
        // check if dropped
        expect(await accessControl._admins(0)).to.equal(accounts[5].address)
    })

    it("CRUD on proposers",async ()=>{ 
        // there is no admin
        await expect(accessControl._proposers(0)).to.reverted
        // the addAdmin function returns true
        await expect(accessControl.authProposerAdd(accounts[2].address)).to.not.be.reverted
        // admin is added
        expect(await accessControl._proposers(0)).to.equal(accounts[2].address, "proposer is not added")
        // same for second admin
        expect(await accessControl.authProposerAdd(accounts[5].address)).to.not.be.reverted
        expect(await accessControl._proposers(1)).to.equal(accounts[5].address, "2nd proposer is not added")
        // drop the first admin
        expect(await accessControl.authProposerRem(accounts[2].address)).to.not.be.reverted
        // check if dropped
        expect(await accessControl._proposers(0)).to.equal(accounts[5].address)
    })

    it("CRUD on credible NFT collections",async ()=>{ 
        // there is no admin
        await expect(accessControl._nftList(0)).to.reverted
        // the addAdmin function returns true
        await expect(accessControl.authNftAdd(accounts[2].address)).to.not.be.reverted
        // admin is added
        expect(await accessControl._nftList(0)).to.equal(accounts[2].address, "nft is not added")
        // same for second admin
        expect(await accessControl.authNftAdd(accounts[5].address)).to.not.be.reverted
        expect(await accessControl._nftList(1)).to.equal(accounts[5].address, "2nd nft is not added")
        // drop the first admin
        expect(await accessControl.authNftRem(accounts[2].address)).to.not.be.reverted
        // check if dropped
        expect(await accessControl._nftList(0)).to.equal(accounts[5].address)
    })

    it("auth_is_owner",async ()=>{ 
        expect(await accessControl.authWhoami(accounts[2].address)).to.equal("user")
        expect(await accessControl.authWhoami(accounts[6].address)).to.equal("user")
        expect(await accessControl.authWhoami(owner.address)).to.equal("owner", "owner couldnt pass")
    })

    it("auth_is_admin",async ()=>{ 
        expect(await accessControl.authWhoami(accounts[2].address)).to.equal("user")
        // !!! This line depends on authAdminAdd !!!
        await expect(accessControl.authAdminAdd(accounts[2].address)).to.not.be.reverted
        expect(await accessControl.authWhoami(accounts[2].address)).to.equal("admin")
    })

    it("auth_is_proposer",async ()=>{ 
        expect(await accessControl.authWhoami(accounts[2].address)).to.equal("user")
        // !!! This line depends on authProposerAdd !!!
        await expect(accessControl.authProposerAdd(accounts[2].address)).to.not.be.reverted
        expect(await accessControl.authWhoami(accounts[2].address)).to.equal("proposer")
    })

    it("auth_is_nftholder",async ()=>{ 
        expect(await accessControl.authWhoami(accounts[2].address)).to.equal("user")
        
        const NFT = await hre.ethers.getContractFactory('TiQetNFT')
        const nft = await NFT.deploy(owner.address)
        const nft_address = await nft.getAddress()
        await nft.safeMint(accounts[2].address, 0)
        
        // !!! This line depends on authNftAdd !!!
        await expect(accessControl.authNftAdd(nft_address)).to.not.be.reverted
        expect(await accessControl._nftList(0)).to.equal(nft_address)

        expect(await accessControl.authWhoami(accounts[2].address)).to.equal("proposer")
        expect(await accessControl.authWhoami(accounts[6].address)).to.equal("user")
    })
})