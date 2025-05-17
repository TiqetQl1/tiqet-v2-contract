// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

import "./AccessControl.sol";
import "./Treasury.sol";
import "./BetUtils.sol";

contract Core is AccessControl, Treasury{
    using BetUtils for BetUtils.Event;
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

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
        require(event_id<_events.length, "404");
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
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)<2, "405");
        bet.change_state(BetUtils.EventState.Disqualified, description);
    }
    function eventResolve(
        uint256 event_id,
        uint256 winner,
        string calldata description
    ) external eqgt_admin {
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        require(uint8(bet.state)<2, "405");
        bet.winner = winner;
        bet.change_state(BetUtils.EventState.Disqualified, description);
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

    function wagerPlace(
        uint256 event_id,
        uint256 option, 
        uint256 stake
    ) external {
        require(event_id<_events.length, "404");
        BetUtils.Event storage bet = _events[event_id];
        address wallet = msg.sender;
        BetUtils.Wager storage raw_wager = _wagers[event_id][wallet].push();
        bet.make_wager(raw_wager, option, stake);
    }
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
        require(wager.option==bet.winner, "417");
        treasury_token_give(wallet, wager.prize);
        wager.is_paid = true;
    }
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