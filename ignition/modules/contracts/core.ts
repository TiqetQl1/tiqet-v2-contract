import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { Wallet } from "ethers";
import PRIVATE_KEYS from "../../accounts";

import _qusdt from "./qusdt";
import _token from "./token";

export default buildModule("core", (m) => {
    const signers = PRIVATE_KEYS.map(key=>new Wallet(key))
    const owner   = signers[0]

    const { qusdt } = m.useModule(_qusdt)
    const { token } = m.useModule(_token)

    const core = m.contract("Core", [token, qusdt])
    return { core };
});