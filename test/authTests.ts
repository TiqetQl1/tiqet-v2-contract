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
        await expect(accessControl.connect(accounts[5]).transferOwnership(accounts[4]), "NOT RESTRICTED ACCESS").to.reverted
        await accessControl.transferOwnership(accounts[5].address)
        expect(await accessControl._owner()).to.equal(accounts[5].address, "Owner is not changed to acc 5")
    })

    it("CRUD on admins",async ()=>{ 
        //TODO...
    })

    it("CRUD on proposers",async ()=>{ 
        //TODO...
    })

    it("CRUD on credible NFT collections",async ()=>{ 
        //TODO...
    })

    it("is_owner",async ()=>{ 
        //TODO...
    })

    it("is_admin",async ()=>{ 
        //TODO...
    })

    it("is_proposer",async ()=>{ 
        //TODO...
    })

    it("has_nft",async ()=>{ 
        //TODO...
    })

    it("modifier: eq_owner", async ()=>{
        //TODO...
    })

    it("modifier: gteq_admin",async ()=>{ 
        //TODO...
    })

    it("modifier: gteq_proposer",async ()=>{ 
        //TODO...
    })

    it("modifier: gteq_holder",async ()=>{ 
        //TODO...
    })
})