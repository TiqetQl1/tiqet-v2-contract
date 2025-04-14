import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import TiQetCoinModule from "./TiQetCoinModule";
import TiQetNFTModule from "./TiQetNFTModule";

export default buildModule("Bootstrap chain", (m) => {
    const { tiqetCoin } = m.useModule(TiQetCoinModule);
    const { tiqetNFT }  = m.useModule(TiQetNFTModule);
  
    return { tiqetCoin, tiqetNFT };
  });