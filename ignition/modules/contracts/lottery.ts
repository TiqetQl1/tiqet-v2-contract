import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { Wallet } from "ethers";
import PRIVATE_KEYS from "../../accounts";

import _nft from "./nft"
import _qusdt from "./qusdt"

export default buildModule("lottery", (m) => {
    const { nft } = m.useModule(_nft)
    const { qusdt } = m.useModule(_qusdt)

    const signers = PRIVATE_KEYS.map(key=>new Wallet(key))
    const owner   = signers[0]

    const lottery = m.contract("TiQetV2_Lottery")
    return { lottery };
});