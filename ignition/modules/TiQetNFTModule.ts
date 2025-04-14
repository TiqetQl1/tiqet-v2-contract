import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { Wallet } from "ethers";
import PRIVATE_KEYS from "../accounts";

export default buildModule("TiQetNFT", (m) => {
    const signers = PRIVATE_KEYS.map(key=>new Wallet(key))
    const owner   = signers[0]
    const tiqetNFT = m.contract("TiQetNFT", []);

    return { tiqetNFT };
});