import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"
import { Wallet } from "ethers";
import PRIVATE_KEYS from "../accounts";
import proposalJson from "./assets/proposal.json"
import EventJson    from "./assets/event.json"
import LotteryJSON  from  "./assets/lottery.json"

import _nft from "./contracts/nft"
import _qusdt from "./contracts/qusdt";
import _token from "./contracts/token";
import _core from "./contracts/core";
import _lottery from "./contracts/lottery"

const FEE = 100
const QUSDT_BALANCE_SIGNERS   = 1000
const QUSDT_BALANCE_TREASURY  = 0
const TOKEN_BALANCE_SIGNERS   = 1000
const TOKEN_BALANCE_TREASURY   = 6000

const mask_address = (addr: string) => `${addr.slice(0,6)}___${addr.slice(-4)}` 

export default buildModule("bootstrap", (m) => {
  const signers = PRIVATE_KEYS.map(key=>new Wallet(key))
  const { nft } = m.useModule(_nft)
  const { qusdt } = m.useModule(_qusdt)
  const { token } = m.useModule(_token)

  const { core } = m.useModule(_core)

  const { lottery } = m.useModule(_lottery)

  // add admin
  m.call(core, "authAdminAdd", [signers[1].address])
  // add proposer
  m.call(core, "authProposerAdd", [signers[2].address]) 
  // add holder
  m.call(core, "authNftAdd", [nft]) 
  m.call(nft, "safeMint", [signers[3].address, 0])
  // change fee
  m.call(core, "configProposalFee", [FEE])

  for (const signer of signers) {
    // giveaway qusdt
    m.call(qusdt, "mint", [signer.address, QUSDT_BALANCE_SIGNERS], {id:`QUSDT_${mask_address(signer.address)}`})
    // giveaway token
    m.call(token, "mint", [signer.address, TOKEN_BALANCE_SIGNERS], {id:`TOKEN_${mask_address(signer.address)}`})
  }
  m.call(qusdt, "mint", [core, QUSDT_BALANCE_TREASURY])
  m.call(token, "mint", [core, TOKEN_BALANCE_TREASURY])
  const approve = m.call(qusdt, "approve", [core, 2*FEE])

  //
  const p1 = m.call(core, "eventPropose"
    , [JSON.stringify(proposalJson)]
    , {id: "PROPOSAL_1",after:[approve]})
  const p2 = m.call(core, "eventPropose"
    , [JSON.stringify(proposalJson)]
    , {id: "PROPOSAL_2",after:[approve]})

  //
  m.call(core, "eventAccept", [
    0, 100, 1000, 4, 100, JSON.stringify(EventJson)
  ], {id:"ACCEPT_1", after:[p1]})
  m.call(core, "eventAccept", [
    1, 100, 1000, 2, 100, JSON.stringify(EventJson)
  ], {id:"ACCEPT_2",after:[p2]})

  // lottery
  const l1 = m.call(lottery, "setUSDT", [qusdt])
  const l2 = m.call(lottery, "setNFT", [nft])
  const l3 = m.call(lottery, "setNftSupply", [1])
  const payload = [
    LotteryJSON.organizer,
    Math.floor(Date.now()/1000)+7200,
    Math.floor(Date.now()/1000),
    LotteryJSON.ticket_price_usdt,
    LotteryJSON.max_tickets_total,
    LotteryJSON.max_participants,
    LotteryJSON.max_tickets_of_participant,
    LotteryJSON.winners_count,
    LotteryJSON.cut_share,
    LotteryJSON.cut_per_nft,
    LotteryJSON.cut_per_winner,
  ]
  m.call(lottery, "poolNew", payload, {id: "PoolNo1", after:[l1, l2, l3]})
  payload[1] = 0
  m.call(lottery, "poolNew", payload, {id: "PoolNo2", after:[l1, l2, l3]})
  m.call(lottery, "poolNew", payload, {id: "PoolNo3", after:[l1, l2, l3]})

  return { core, qusdt, token, nft, lottery }
});