// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AccessControl {
    address public owner;

    constructor() payable {
        owner   = msg.sender;
    }

}
