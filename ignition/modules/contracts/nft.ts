import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { Wallet } from "ethers";
import PRIVATE_KEYS from "../../accounts";

export default buildModule("nft", (m) => {
    const signers = PRIVATE_KEYS.map(key=>new Wallet(key))
    const owner   = signers[0]
    const nft = m.contract("TestERC721Token", [owner.address]);

    return { nft };
});