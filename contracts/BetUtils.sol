// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library BetUtils {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    uint256 public constant DECIMALS = 10_000;

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
        Wager storage wager,
        uint256 option, 
        uint256 stake
    ) internal {
        require(bet.state==BetUtils.EventState.Opened, "423");
        require(option<bet.options_count , "400");
        require(stake>0 && stake<=bet.max_per_one_bet, "403");
        // update weights ...
        int128 fixed_stake = stake.fromUInt();
        bet.m[option] = bet.m[option].add(fixed_stake);
        int128 current_product=(uint256 (1)).fromUInt();
        for (uint256 i = 0; i < bet.options_count; i++) {
            if(i == option) continue;
            current_product = current_product.mul(bet.m[i]);
        }
        int128 target_product = bet.k.div(bet.m[option]);
        
        int128 logC = current_product.ln();
        int128 logT = target_product.ln();
        int128 logg = logT.div(logC);

        for (uint256 i = 0; i < bet.options_count; i++) {
            if (i == option) continue;
            bet.m[i] = safe_pow(bet.m[i], logg);
        }
        // calc prize ...
        uint256 prize = (fixed_stake.mul(get_odd(bet, option))).toUInt();
        // fill wager instance ...
        bet.handle    = bet.handle + stake;
        wager.eventId = bet.id;
        wager.is_paid = false;
        wager.option  = option;
        wager.stake   = stake;
        wager.prize   = prize;
    }
    function get_chance(
        Event storage bet,
        uint256 option
    ) internal view returns (int128) {
        int128 total = sum_array(bet.m);
        return bet.m[option].div(total);
    }
    function get_odd(
        Event storage bet,
        uint256 option
    ) internal view returns(int128) {
        int128 chance = get_chance(bet, option);
        int128 percent = chance.mul(ABDKMath64x64.fromUInt(100)); 

        int128 exponent = map(
            ABDKMath64x64.fromUInt(0),
            ABDKMath64x64.fromUInt(100),
            percent,
            ABDKMath64x64.divu(9000, 10000), // 0.9000
            ABDKMath64x64.divu(9999, 10000)  // 0.9999
        );

        int128 odd = safe_pow(ABDKMath64x64.fromUInt(1).div(chance), exponent);
        return odd;
    }
    function sum_array(
        int128[] storage arr
    ) internal view returns (int128 sum) {
        sum = (uint256 (0)).fromUInt();
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