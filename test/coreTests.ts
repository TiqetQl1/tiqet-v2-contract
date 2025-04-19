import { expect, assert } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { Core, TestERC721Token, TestERC20Token } from "../typechain-types";
import { ContractTransactionResponse } from "ethers";

describe('BettingSystem', () => {
    let token    : TestERC20Token   & { deploymentTransaction(): ContractTransactionResponse };
    let nft      : TestERC721Token  & { deploymentTransaction(): ContractTransactionResponse };
    let core     : Core & { deploymentTransaction(): ContractTransactionResponse };
    let accounts : HardhatEthersSigner[];
    let owner    : HardhatEthersSigner;

    it("hi", async () => {
        assert(true)
    })
})