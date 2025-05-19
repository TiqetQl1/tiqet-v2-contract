import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import { Wallet } from "ethers";
import PRIVATE_KEYS from "../accounts";

import _nft from "./submodules/nft"
import _qusdt from "./submodules/qusdt";
import _token from "./submodules/token";

const FEE = 100

export default buildModule("bootstrap", (m) => {
    const signers = PRIVATE_KEYS.map(key=>new Wallet(key))
    const { nft } = m.useModule(_nft)
    const { qusdt } = m.useModule(_qusdt)
    const { token } = m.useModule(_token)

    const core = m.contract("Core", [token, qusdt])

    // add admin
    m.call(core, "authAdminAdd", [signers[1].address])
    // add proposer
    m.call(core, "authProposerAdd", [signers[2].address]) 
    // add holder
    m.call(core, "authNftAdd", [nft]) 
    m.call(nft, "safeMint", [signers[4].address, 0])
    // change fee
    m.call(core, "configProposalFee", [FEE])
  
    return { core, qusdt, token, nft }
  });