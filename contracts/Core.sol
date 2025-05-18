// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

import "./AccessControl.sol";
import "./Treasury.sol";
import "./BetUtils.sol";

/// @title Core
/// @author [KAYT33N](https://github.com/KAYT33N)
/// @notice Core contract and logics of the Betting system
contract Core is AccessControl, Treasury{
    using BetUtils for BetUtils.Event;
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    /// @notice deploys contract
    /// @param token address of the token contract
    /// @param qusdt address of the qusdt contract
    constructor (address token, address qusdt) Treasury(token, qusdt) {}

    /// @notice will hold all proposals, accepted or not
    BetUtils.Proposal[] _proposals;

    /// @notice holds states and data thats needed contract side
    BetUtils.Event[] public  _events;
    /// @notice Holds title, desciptions, options and other frontend infos
    BetUtils.Metas[]  public _events_metas;
    /// @notice array of wagers made by a wallet on an event
    /// @dev Wager[] res = _wagers[${event_id}][${wallet}]
    mapping(uint256=>mapping(address => BetUtils.Wager[])) public _wagers;

    /// @notice fee needed to make new proposal
    /// @dev in qusdt
    uint256 public _proposal_fee;

    /// @notice Changes fee to make proposal
    /// @param amount_in_qusdt to make proposal
    function configProposalFee(
        uint256 amount_in_qusdt
    ) external eqgt_admin {
        emit BetUtils.FeeChanged(
            _proposal_fee, 
            amount_in_qusdt
            );
        _proposal_fee = amount_in_qusdt;
    }
    /// @notice Used to make a new proposal
    /// - Contract should have been approved for the amount of fee
    /// - needs admins previlege
    /// @param metas holds the proposal's info
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
    /// @notice Accepts proposal and makes a new event out of it
    /// @param proposal_id -
    /// @param max_per_one_bet maximum amount of the stake in one wager
    /// @param fake_liq_per_option default weight of options
    /// @param options_count number of the outcomes
    /// @param vig the tax percent that goes to the creator
    /// (1 means 0.01%)
    /// @param metas info of the event provided by admin
    function eventAccept(
        uint256 proposal_id,
        uint256 max_per_one_bet,
        uint256 fake_liq_per_option,
        uint256 options_count,
        uint256 vig,
        string calldata metas
    ) external eqgt_admin {
        require(_proposals.length>proposal_id, "404");
        BetUtils.Proposal storage proposal = _proposals[proposal_id];
        require(proposal.state==BetUtils.ProposalState.Pending, "208");
        treasury_qusdt_give(_owner, proposal.fee_paid);
        proposal.state = BetUtils.ProposalState.Accepted;
        uint256 index = _events.length;
        BetUtils.Event storage bet = _events.push();
        bet.build(proposal, index, max_per_one_bet, options_count, fake_liq_per_option, vig);
        _events_metas.push(BetUtils.Metas(index, metas));
        emit BetUtils.EventReviewed(proposal_id, index, true, metas);
    }
    /// @notice Rejects proposals and refunds fee
    /// @param proposal_id -
    /// @param description Reason
    function eventReject(
        uint256 proposal_id,
        string calldata description
    ) external eqgt_admin {
        require(_proposals.length>proposal_id, "404");
        BetUtils.Proposal storage proposal = _proposals[proposal_id];
        require(proposal.state==BetUtils.ProposalState.Pending, "208");
        treasury_qusdt_give(proposal.creator, proposal.fee_paid);
        proposal.state = BetUtils.ProposalState.Rejected;
        emit BetUtils.EventReviewed(proposal_id, type(uint256).max, false, description);
    }
    /// @notice To (Un)Pause events
    /// @param event_id -
    /// @param description Reason
    function eventTogglePause(
        uint256 event_id,
        string calldata description
    ) external eqgt_admin {
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)<2, "405");
        BetUtils.EventState to_be;
        if (bet.state == BetUtils.EventState.Opened) to_be = BetUtils.EventState.Paused;
        if (bet.state == BetUtils.EventState.Paused) to_be = BetUtils.EventState.Opened;
        bet.change_state(to_be, description);
    }
    /// @notice Ends and disqualifies an event without a winner outcome 
    /// to make them able to collect their original stakes
    /// @param event_id -
    /// @param description Reason
    function eventDisq(
        uint256 event_id,
        string calldata description
    ) external eqgt_admin {
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)<2, "405");
        bet.change_state(BetUtils.EventState.Disqualified, description);
    }
    /// @notice Ends and makes winners able to collect prizes
    /// @param event_id -
    /// @param description Reason
    function eventResolve(
        uint256 event_id,
        uint256 winner,
        string calldata description
    ) external eqgt_admin {
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)<2, "405");
        bet.winner = winner;
        bet.change_state(BetUtils.EventState.Resolved, description);
    }

    function getOdd(
        uint256 event_id,
        uint256 option
    ) external view returns(uint256) {
        return _events[event_id]
            .get_odd(option)
            .mul(ABDKMath64x64.fromUInt(BetUtils.DECIMALS))
            .toUInt();
    }
    function getChance(
        uint256 event_id,
        uint256 option
    ) external view returns(uint256) {
        return _events[event_id]
            .get_chance(option)
            .mul(ABDKMath64x64.fromUInt(BetUtils.DECIMALS))
            .toUInt();
    }

    struct Debug{
        uint id;
        uint[] m;
        uint k;
    }
    function debug(
        uint256 event_id
    ) external view returns(Debug memory str) {
        BetUtils.Event storage bet = _events[event_id];
        str.id = event_id;
        str.m = new uint[](bet.options_count);
        for (uint256 i = 0; i < bet.m.length; i++) {
            str.m[i] = (bet.m[i].mul(BetUtils.DECIMALS.fromUInt()).toUInt());
        }
        str.k = bet.k.toUInt();
    }

    /// @notice Bets on an bet's outcome
    /// @param event_id -
    /// @param option The outcome to bet on
    /// @param stake Amount of money to bet
    function wagerPlace(
        uint256 event_id,
        uint256 option, 
        uint256 stake
    ) external {
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        require(bet.state==BetUtils.EventState.Opened, "423");
        require(option<bet.options_count , "400");
        require(stake>0 && stake<=bet.max_per_one_bet, "403");
        address wallet = msg.sender;
        treasury_token_collect(wallet, stake);
        BetUtils.Wager storage raw_wager = _wagers[event_id][wallet].push();
        bet.make_wager(raw_wager, option, stake);
    }
    /// @notice Claims prize and gives creator the vig if bet is resolved
    /// @param event_id -
    /// @param wager_id -
    function wagerClaim(
        uint256 event_id,
        uint256 wager_id
    ) external {
        address wallet = msg.sender;
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)>1, "425");
        require(bet.state==BetUtils.EventState.Resolved, "405");
        require(_wagers[event_id][wallet].length>wager_id, "400");
        BetUtils.Wager storage wager = _wagers[event_id][wallet][wager_id];
        require(wager.is_paid==false,"208");
        require(wager.option==bet.winner, "417");
        uint256 vig = (wager.prize*bet.vig)/1_000;
        treasury_token_give(bet.creator, vig);
        treasury_token_give(wallet, (wager.prize)-vig);
        wager.is_paid = true;
    }
    /// @notice Refunds original stake if bet is disqualified
    /// @param event_id -
    /// @param wager_id -
    function wagerRefund(
        uint256 event_id,
        uint256 wager_id
    ) external {
        address wallet = msg.sender;
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)>1, "425");
        require(bet.state==BetUtils.EventState.Disqualified, "405");
        require(_wagers[event_id][wallet].length>wager_id, "400");
        BetUtils.Wager storage wager = _wagers[event_id][wallet][wager_id];
        treasury_token_give(wallet, wager.stake);
        wager.is_paid = true;
    }

    function clientPagination(
        uint256 per_page,
        uint256 start_index
    ) external {}
}