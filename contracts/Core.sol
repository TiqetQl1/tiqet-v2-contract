// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Treasury.sol";

contract Core is AccessControl, Treasury{
    constructor (address token) Treasury(token) {}
}