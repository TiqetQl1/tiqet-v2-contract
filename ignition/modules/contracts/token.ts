import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { Wallet } from "ethers";
import PRIVATE_KEYS from "../../accounts";

export default buildModule("token", (m) => {
    const signers = PRIVATE_KEYS.map(key=>new Wallet(key))
    const owner   = signers[0]
    const token = m.contract("TestERC20Token", [owner.address]);

    return { token };
});