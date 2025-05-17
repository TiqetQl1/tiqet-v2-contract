// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Treasury.sol";

/// @title TreasuryTestWrapper
/// @notice to test the internal functions of the main contract
/// @dev WONT be in production
contract TestTreasuryWrapper is Treasury{
    
    constructor(address token, address qusdt) 
        Treasury(token, qusdt)
        {}

    function treasury_token_collect_wrapper(address from, uint256 amount) public returns(bool){
        return treasury_token_collect(from, amount);
    }

    function treasury_token_give_wrapper(address to, uint256 amount) public returns(bool){
        return treasury_token_give(to, amount);
    }

    function treasury_qusdt_collect_wrapper(address from, uint256 amount) public returns(bool){
        return treasury_qusdt_collect(from, amount);
    }

    function treasury_qusdt_give_wrapper(address to, uint256 amount) public returns(bool){
        return treasury_qusdt_give(to, amount);
    }
}