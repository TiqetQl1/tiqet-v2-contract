// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Treasury.sol";
import "./BetUtils.sol";

contract Core is AccessControl, Treasury{
    using BetUtils for BetUtils.Event;

    constructor (address token, address qusdt) Treasury(token, qusdt) {}

    /// @notice will hold all proposals, accepted or not
    BetUtils.Proposal[] _proposals;

    /// @notice holds states and data thats needed contract side
    BetUtils.Event[] public  _events;
    /// @notice Holds title, desciptions, options and other frontend infos
    BetUtils.Metas[]  public _events_metas;
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
        string calldata metas
    ) external eqgt_proposer {
        treasury_qusdt_collect(msg.sender, _proposal_fee);
        uint256 index = _proposals.length;
        _proposals.push(BetUtils.Proposal(
            index,
            msg.sender,
            _proposal_fee,
            BetUtils.ProposalState.Pending
        ));
        emit BetUtils.EventProposed(
            index,
            msg.sender,
            metas,
            _proposal_fee
        );
    }
    function eventAccept(
        uint256 proposal_id,
        uint256 max_per_one_bet,
        uint256 fake_liq_per_option,
        uint256 options_count,
        uint256 vig,
        string calldata metas
    ) external eqgt_admin {
        require(_proposals[proposal_id].state==BetUtils.ProposalState.Pending, "208");
        _proposals[proposal_id].state = BetUtils.ProposalState.Accepted;
        uint256 index = _events.length;
        BetUtils.Event storage bet = _events.push();
        bet.build(index, max_per_one_bet, options_count, fake_liq_per_option, vig);
        _events_metas.push(BetUtils.Metas(index, metas));
        emit BetUtils.EventReviewed(proposal_id, index, true, metas);
    }
    function eventReject(
        uint256 proposal_id,
        string calldata metas
    ) external eqgt_admin {
        require(_proposals[proposal_id].state==BetUtils.ProposalState.Pending, "208");
        _proposals[proposal_id].state = BetUtils.ProposalState.Rejected;
        emit BetUtils.EventReviewed(proposal_id, 0, false, metas);
    }
    function eventTogglePause(
        uint256 event_id,
        string calldata description
    ) external eqgt_admin {
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)<2, "405");
        BetUtils.EventState to_be;
        if (bet.state == BetUtils.EventState.Opened) to_be = BetUtils.EventState.Paused;
        if (bet.state == BetUtils.EventState.Paused) to_be = BetUtils.EventState.Opened;
        bet.change_state(to_be, description);
    }
    function eventDisq(
        uint256 event_id,
        string calldata description
    ) external eqgt_admin {
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)<2, "405");
        bet.change_state(BetUtils.EventState.Disqualified, description);
    }
    function eventResolve(
        uint256 event_id,
        uint256 winner,
        string calldata description
    ) external eqgt_admin {
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)<2, "405");
        bet.winner = winner;
        bet.change_state(BetUtils.EventState.Disqualified, description);
    }

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