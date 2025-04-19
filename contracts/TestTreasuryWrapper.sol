// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Treasury.sol";

/// @title TreasuryTestWrapper
/// @notice to test the internal functions of the main contract
/// @dev WONT be in production
contract TestTreasuryWrapper is Treasury{
    
    constructor(address token) 
        Treasury(token)
        {}

    function treasury_collect_wrapper(address from, uint256 amount) public returns(bool){
        return treasury_collect(from, amount);
    }

    function treasury_give_wrapper(address to, uint256 amount) public returns(bool){
        return treasury_give(to, amount);
    }
}