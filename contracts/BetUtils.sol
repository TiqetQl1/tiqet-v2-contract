// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

/// @title BetUtils
/// @author [KAYT33N](https://github.com/KAYT33N)
/// @notice Holds the codes related to Events and betting
/// @dev Explain to a developer any extra details
library BetUtils {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    
    /// @notice Used for converting float to int and in reverse
    uint256 public constant DECIMALS = 10_000;

    /// @notice States that an event can be in
    enum EventState {
        Opened,
        Paused,
        Resolved,
        Disqualified
    }
    /// @notice States of the proposals
    enum ProposalState {
        Pending ,
        Rejected,
        Accepted
    }
    
    /// @notice Events will be holded in this form before processing
    struct Proposal{
        uint256 id; // to remain consistancy
        address creator;
        uint256 fee_paid; // To payback in case of changing the fee and getting rejected
        ProposalState state;
    }
    /// @notice Final form of events after getting accepted
    struct Event{
        uint256 proposal_id;
        uint256 id;
        address creator;
        uint256 options_count;
        uint256 max_per_one_bet;
        int128 [] m; // Weight of each option, used when getting the chances, changes on each buy
        int128  k; // The total product of all options weightes, wont change over time
        uint256 handle; // Total money raised by this single event
        uint256 winner; // Index of the winner option, only when state==Resolved
        uint256 vig; // 1 means 0.01%, percent that goes to creator
        EventState state;
    }
    /// @notice Holds metas of an event
    struct Metas{
        uint256 id; // To preserve consistancy in front-end
        string metas; // Holds a json string with all key values e.g images and options etc
    }
    /// @notice Holds data related to a bet user made
    struct Wager{
        uint256 event_id;
        uint256 option; // The option they made bet on
        uint256 stake; // The amount of money they've paid 
        uint256 prize; // The outcome if bet wins
        bool is_paid; // If it has been paid
    }

    /// @notice Emitted on change of the fee to make a proposal
    /// @param from Old amount
    /// @param to New amount
    event FeeChanged(
        uint256 from,
        uint256 to
    );
    /// @notice Emitted on making a new proposal
    /// @param proposal_id -
    /// @param creator Wallet address of the proposer
    /// @param metas A json string to hold details of the proposal, Storing it on chain was expensive in gas
    /// @param fee_paid -
    event EventProposed(
        uint256 indexed proposal_id,
        address indexed creator,
        string metas,
        uint256 fee_paid
    );
    /// @notice Emitted on reviewing proposals
    /// @param proposal_id -
    /// @param event_id Has meaning if `accepted` is true
    /// @param accepted If the proposal has been accepted
    /// @param metas Json string of event details
    event EventReviewed(
        uint256 indexed proposal_id,
        uint256 indexed event_id,
        bool indexed accepted,
        string metas
    );
    /// @notice Emitted on chaing of the events state
    /// @param event_id -
    /// @param state Code of the state that event has gotten to (0-3)
    /// @param state_text (Opened|Paused|Resolved|Disqualified)
    /// @param description More info on the desicion by the admin
    event EventChanged(
        uint256 indexed event_id,
        EventState state,
        string state_text,
        string description
    );
    /// @notice e.g. user betted on an option
    /// @param event_id -
    /// @param wager_id -
    /// @param wallet Wallet address of the user
    /// @param option The oucome they've betted on
    /// @param stake Amount of money they've betted
    /// @param prize The money they will collect on win
    event WagerMade(
        uint256 indexed event_id,
        uint256 indexed wager_id,
        address indexed wallet,
        uint256 option,
        uint256 stake,
        uint256 prize
    );
    /// @notice Wager has been claimed on win
    /// @param event_id -
    /// @param wager_id -
    /// @param wallet Wallet address of the user
    /// @param amount Amount they've collected
    event WagerClaimed(
        uint256 indexed event_id,
        uint256 indexed wager_id,
        address indexed wallet,
        uint256 amount
    );
    /// @notice Details of the vig payed
    /// @param event_id -
    /// @param wager_id -
    /// @param wallet Wallet address of the bet proposer
    /// @param amount Amount they've recieved
    event VigPayed(
        uint256 indexed event_id,
        uint256 indexed wager_id,
        address indexed wallet,
        uint256 amount
    );
    /// @notice Wager has been refunded on disQ
    /// @param event_id -
    /// @param wager_id -
    /// @param wallet Wallet address of the user
    /// @param amount Amount they've collected
    event WagerRefunded(
        uint256 indexed event_id,
        uint256 indexed wager_id,
        address indexed wallet,
        uint256 amount
    );

    
    /// @notice Fills an instance of the event with data
    /// @param bet instance of the event to be filled
    /// @param proposal The proposal that leaded to this
    /// @param id id of the event in the _events array
    /// @param max_per_one_bet (refere to `Event` struct)
    /// @param options_count (refere to `Event` struct)
    /// @param fake_liq_per_option (refere to `Event` struct)
    /// @param vig (refere to `Event` struct)
    function build(
        Event storage bet,
        Proposal storage proposal,
        uint256 id,
        uint256 max_per_one_bet,
        uint256 options_count,
        uint256 fake_liq_per_option,
        uint256 vig
    ) internal {
        int128 init_value = fake_liq_per_option.fromUInt();
        bet.id = id;
        bet.creator = proposal.creator;
        bet.proposal_id = proposal.id;
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
    /// @notice Changes an Events state and emits the event 
    /// @param bet Instance to be updated
    /// @param state New state
    /// @param description More description on this change
    function change_state(
        Event storage bet,
        EventState state,
        string calldata description
    ) internal {
        bet.state = state;
        emit EventChanged(bet.id, state, to_string(state), description);
    }

    /// @notice Makes a new wager
    /// @dev Steps are :
    /// - Calculate prize with current odd
    /// - Update weights and odds
    /// - Save wager info
    /// @param bet The event to bet on
    /// @param wager The wager instance to be filled
    /// @param option The outcome to put stake on
    /// @param stake The amount of money to put on that outcome
    function make_wager(
        Event storage bet,
        Wager storage wager,
        uint256 option, 
        uint256 stake
    ) internal {
        // calc prize ...
        int128 fixed_stake = stake.fromUInt();
        uint256 prize = (fixed_stake.mul(get_odd(bet, option))).toUInt();
        // update weights ...
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
        // fill wager instance ...
        bet.handle    = bet.handle + stake;
        wager.event_id = bet.id;
        wager.is_paid = false;
        wager.option  = option;
        wager.stake   = stake;
        wager.prize   = prize;
    }
    /// @notice To find winning chance of an outcome
    /// @param bet -
    /// @param option -
    /// @return int128 This is NOT a normal int, rather is a `float` 
    /// and should be handled with `ABDKMath64x64`
    function get_chance(
        Event storage bet,
        uint256 option
    ) internal view returns (int128) {
        int128 total = sum_array(bet.m);
        return bet.m[option].div(total);
    }
    /// @notice To find odd of an outcome
    /// @param bet -
    /// @param option -
    /// @return int128 This is NOT a normal int, rather is a `float` 
    /// and should be handled with `ABDKMath64x64`
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

    // Helpers

    /// @notice Helper function to sum values of an array
    /// @dev All int128 values are floats and cant be accessed directly
    /// @param arr -
    /// @return sum -
    function sum_array(
        int128[] storage arr
    ) internal view returns (int128 sum) {
        sum = (uint256 (0)).fromUInt();
        for (uint256 i = 0; i < arr.length; i++) {
            sum = sum.add(arr[i]);
        }
    }
    /// @notice Calculates base raised to the power of exp (base^exp) using natural logarithms and exponentials.
    /// @dev Supports fractional and negative exponents. Reverts if base <= 0.
    /// All int128 values are floats and cant be accessed directly
    /// @param base -
    /// @param exp -
    /// @return int128
    function safe_pow(
        int128 base, 
        int128 exp
    ) internal pure returns (int128) {
        require(base > 0, "Pow base must be > 0");
        int128 lnBase = base.ln();
        int128 scaled = lnBase.mul(exp);
        return scaled.exp(); // base^exp
    }
    /// @notice Moves a number from one range to another
    /// @dev e.g (0, 10, 3, 20, 30) -> 23
    /// All int128 values are floats and cant be accessed directly
    /// @param inMin start of first range
    /// @param inMax end of first range
    /// @param value the number to change range
    /// @param outMin start of second range
    /// @param outMax end of second range
    /// @return int128 -
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
    /// @notice returns name string of the states
    /// @param state -
    /// @return string -
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