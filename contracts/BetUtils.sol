// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library BetUtils {
    uint256 constant DECIMALS = 1_000;

    enum EventState {
        Opened,
        Paused,
        Resolved,
        Disqualified
    }
    enum ProposalState {
        Pending ,
        Rejected,
        Accepted
    }
    

    struct Proposal{
        uint256 proposal_id;
        address creator;
        uint256 fee_paid;
        ProposalState state;
    }
    struct Event{
        uint256 proposal_id;
        uint256 id;
        uint256 options_count;
        uint256 max_per_one_bet;
        uint256[] m;
        uint256 k;
        uint256 handle;
        uint256 winner;
        uint256 vig; // 1 means 0.01%
        EventState state;
    }
    struct Metas{
        uint256 id;
        string metas;
    }
    struct Wager{
        uint256 eventId;
        uint256 option;
        uint256 amount;
        uint256 prize;
        bool is_paid;
    }

    event FeeChanged(
        uint256 from,
        uint256 to
    );

    event EventProposed(
        uint256 indexed proposal_id,
        address indexed creator,
        string metas,
        uint256 fee_paid
    );
    event EventReviewed(
        uint256 indexed proposal_id,
        uint256 indexed id,
        bool indexed accepted,
        string metas
    );
    event EventChanged(
        uint256 indexed id,
        EventState state,
        string state_text,
        string description
    );
    event WagerMade(
        uint256 indexed wager_id,
        address indexed wallet,
        uint256 indexed event_id,
        uint256 option,
        uint256 amount,
        uint256 prize
    );
    event WagerClaimed(
        uint256 indexed wager_id,
        uint256 indexed event_id,
        address indexed wallet,
        uint256 prize
    );
    event WagerRefunded(
        uint256 indexed wager_id,
        uint256 indexed event_id,
        address indexed wallet,
        uint256 amount
    );

    function build(
        Event storage bet,
        uint256 id,
        uint256 max_per_one_bet,
        uint256 options_count,
        uint256 fake_liq_per_option,
        uint256 vig
    ) internal {
        bet.id = id;
        bet.options_count = options_count;
        bet.max_per_one_bet = max_per_one_bet;
        bet.k=1;
        for (uint256 i = 0; i < options_count; i++) {
            bet.m.push();
            bet.m[i] = fake_liq_per_option;
            bet.k = bet.k * fake_liq_per_option;
        }
        bet.handle=0;
        bet.vig = vig;
        bet.state = EventState.Paused;
    }
    function change_state(
        Event storage bet,
        EventState state,
        string calldata description
    ) internal {
        bet.state = state;
        emit EventChanged(bet.id, state, toString(state), description);
    }
    function make_wager(
        Event storage bet,
        address wallet, 
        uint256 outcome, 
        uint256 stake
    ) internal {}

    function toString(
        EventState state
    ) internal pure returns (string memory) {
        if (state == EventState.Opened) return "Opened";
        if (state == EventState.Paused) return "Paused";
        if (state == EventState.Resolved) return "Resolved";
        if (state == EventState.Disqualified) return "Disqualified";
        return "undefined";
    }

}