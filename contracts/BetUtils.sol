// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

library BetUtils {
    uint256 constant DECIMALS = 1_000;

    enum EventState {
        Pending, 
        Accepted,
        Opened,
        Finished,
        Resolved,
        Rejected,
        Disqualified
    }

    struct Event{
        uint256 id;
        uint256 options_count;
        uint256[] m;
        uint256 k;
        uint256 handle;
        uint256 winner;
        uint256 vig; // 1 means 0.01%
        uint256 end_time;
        address creator;
        EventState state;
        string title;
    }
    struct Option{
        uint256 id;
        string text;
    }
    struct Wager{
        uint256 eventId;
        uint256 option;
        uint256 amount;
        uint256 prize;
        bool is_paid;
    }

    event EventNew(
        uint256 indexed id,
        address indexed creator,
        string title,
        string  question,
        Option[] options,
        uint256 end_time
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
        string calldata title,
        string calldata description,
        string[] calldata outcomes
    ) internal {}
    function change_state(
        Event storage bet,
        EventState state,
        string calldata description
    ) internal {}
    function make_wager(
        Event storage bet,
        address wallet, 
        uint256 outcome, 
        uint256 stake
    ) internal {}

}