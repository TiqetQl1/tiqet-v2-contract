// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library BetUtils {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    uint256 public constant DECIMALS = 100_000_000;

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
        int128 [] m;
        int128  k;
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
        uint256 stake;
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
        uint256 stake,
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
        uint256 stake
    );

    // Bets
    function build(
        Event storage bet,
        uint256 id,
        uint256 max_per_one_bet,
        uint256 options_count,
        uint256 fake_liq_per_option,
        uint256 vig
    ) internal {
        int128 init_value = fake_liq_per_option.fromUInt();
        bet.id = id;
        bet.options_count = options_count;
        bet.max_per_one_bet = max_per_one_bet;
        bet.k=1;
        for (uint256 i = 0; i < options_count; i++) {
            bet.m.push(init_value);
        }
        bet.k = init_value.pow(options_count);
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
        emit EventChanged(bet.id, state, to_string(state), description);
    }

    // Wagers
    function make_wager(
        Event storage bet,
        address wallet, 
        uint256 outcome, 
        uint256 stake
    ) internal {}
    function get_chance_int(
        Event storage bet,
        uint256 option
    ) internal view returns (int128) {
        int128 total = sum_array(bet.m);
        return bet.m[option].div(total);
    }
    function get_chance_uint(
        Event storage bet,
        uint256 option
    ) internal view returns (uint256) {
        int128 chance = get_chance_int(bet, option);
        return chance.mul(ABDKMath64x64.fromUInt(DECIMALS)).toUInt();
    }
    function get_odd(
        Event storage bet,
        uint256 option
    ) internal view returns(uint256) {
        int128 chance = get_chance_int(bet, option);
        int128 percent = chance.mul(ABDKMath64x64.fromUInt(100)); 

        int128 exponent = map(
            ABDKMath64x64.fromUInt(0),
            ABDKMath64x64.fromUInt(100),
            percent,
            ABDKMath64x64.divu(9000, 10000), // 0.9000
            ABDKMath64x64.divu(9999, 10000)  // 0.9999
        );

        int128 odd = safe_pow(ABDKMath64x64.fromUInt(1).div(chance), exponent);
        return odd.mul(ABDKMath64x64.fromUInt(DECIMALS)).toUInt();
    }
    function sum_array(
        int128[] storage arr
    ) internal view returns (int128 sum) {
        for (uint256 i = 0; i < arr.length; i++) {
            sum = sum.add(arr[i]);
        }
    }

    // Helpers
    function safe_pow(
        int128 base, 
        int128 exp
    ) internal pure returns (int128) {
        require(base > 0, "Pow base must be > 0");
        int128 lnBase = base.ln();
        int128 scaled = lnBase.mul(exp);
        return scaled.exp(); // base^exp
    }
    function map(
        int128 inMin,
        int128 inMax,
        int128 value,
        int128 outMin,
        int128 outMax
    ) internal pure returns (int128) {
        int128 inRange = inMax.sub(inMin);
        require(inRange > 0, "Invalid in range");
        int128 outRange = outMax.sub(outMin);
        int128 norm = value.sub(inMin).div(inRange);
        return norm.mul(outRange).add(outMin);
    }
    function to_string(
        EventState state
    ) internal pure returns (string memory) {
        if (state == EventState.Opened) return "Opened";
        if (state == EventState.Paused) return "Paused";
        if (state == EventState.Resolved) return "Resolved";
        if (state == EventState.Disqualified) return "Disqualified";
        return "undefined";
    }

}