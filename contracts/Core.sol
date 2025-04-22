// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Treasury.sol";
import "./BetUtils.sol";

contract Core is AccessControl, Treasury{
    using BetUtils for BetUtils.Event;

    constructor (address token, address qusdt) Treasury(token, qusdt) {}

    /// @notice will hold all proposals, accepted or not
    BetUtils.Proposal[] proposals;

    /// @notice holds states and data thats needed contract side
    BetUtils.Event[] public _events;
    /// @notice Holds title, desciptions, options and other frontend infos
    string  public          _events_metas;
    /// @notice array of wagers made by a wallet on an event
    mapping(uint256=>mapping(address => BetUtils.Wager[])) public _wagers;

    /// @notice fee needed to make new proposal
    /// @dev in qusdt
    uint256 public _proposal_fee;

    function configProposalFee(
        uint256 amount_in_qusdt
    ) external eqgt_admin {
        emit BetUtils.FeeChanged(
            _proposal_fee, 
            amount_in_qusdt
            );
        _proposal_fee = amount_in_qusdt;
    }

    function eventPropose(
        string calldata description
    ) external eqgt_proposer {
        treasury_qusdt_collect(msg.sender, _proposal_fee);
        uint256 index = proposals.length;
        proposals.push(BetUtils.Proposal(
            index,
            msg.sender,
            description,
            _proposal_fee,
            BetUtils.PoposalState.Pending
        ));
        emit BetUtils.EventProposed(
            index,
            msg.sender,
            description,
            _proposal_fee
        );
    }
    function eventAccept(
        uint256 event_id,
        uint256 max_per_one_bet,
        uint256 fake_liq_per_option,
        uint256 vig,
        uint256 end_time,
        string calldata metas
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
        uint256 event_id,
        uint256 winner,
        string calldata description
    ) external {}

    function wagerPlace(
        uint256 event_id,
        uint256 option, 
        uint256 amount
    ) external {}
    function wagerClaim(
        uint256 event_id
    ) external {}
    function wagerRefund(
        uint256 wager_id
    ) external {}

    function clientPagination(
        uint256 per_page,
        uint256 start_index
    ) external {}
}