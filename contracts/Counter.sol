// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Counter {
    address payable public owner;
    uint256 public counter;

    constructor() payable {
        owner   = payable(msg.sender);
        counter = 0;
    }

    function countUp() public {
        counter = counter + 1;
    }

}
