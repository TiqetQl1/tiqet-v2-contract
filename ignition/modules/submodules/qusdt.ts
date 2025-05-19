import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { Wallet } from "ethers";
import PRIVATE_KEYS from "../../accounts";

export default buildModule("qusdt", (m) => {
    const signers = PRIVATE_KEYS.map(key=>new Wallet(key))
    const owner   = signers[0]
    const qusdt = m.contract("TestERC20Token", [owner.address]);

    return { qusdt };
});