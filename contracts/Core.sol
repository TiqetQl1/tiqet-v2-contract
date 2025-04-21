// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Treasury.sol";
import "./BetUtils.sol";

contract Core is AccessControl, Treasury{
    using BetUtils for BetUtils.Event;

    constructor (address token, address qusdt) Treasury(token, qusdt) {}

    BetUtils.Event[] events;
    mapping(address => BetUtils.Wager[]) wagers;
    uint256 _proposal_fee;

    function configProposalFee(
        uint256 amount_in_qusdt
    ) external {}

    function eventPropose(
        string calldata title,
        string calldata description,
        string[] calldata outcomes
    ) external {}
    function eventAccept(
        uint256 event_id,
        uint256 max_per_one_bet,
        uint256 fake_liq_per_outcome,
        string calldata description
    ) external {}
    function eventTogglePause(
        uint256 event_id,
        string calldata description
    ) external {}
    function eventReject(
        uint256 event_id,
        string calldata description
    ) external {}
    function eventDisq(
        uint256 event_id,
        string calldata description
    ) external {}
    function eventResolve(
        uint256 winner,
        string calldata description
    ) external {}

    function wagerPlace(
        uint256 event_id,
        uint256 outcome, 
        uint256 amount
    ) external {}
    function wagerClaim(
        uint256 wager_id
    ) external {}
    function wagerRefund(
        uint256 wager_id
    ) external {}
}