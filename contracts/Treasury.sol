// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AccessControl.sol";

/// @title Treasury
/// @notice The main contract to handle TXs of $TiQet coin
/// @author [KAYT33N](https://github.com/KAYT33N)
/// @dev Will be driven in the main contract
contract Treasury is AccessControl {

    /// @notice Address of the currency token 
    ERC20 immutable public _treasury_token;
    /// @notice Used to limit owners from withdrawing whole fund
    /// @dev 1 means %0.01 of the total supply
    uint256 constant public _treasury_withdraw_threshold = 3000;

    /// @notice Constructor function
    /// @param token Address of the currency token
    constructor(address token){
        _treasury_token = ERC20(token);
    }

    function treasury_collect(address from, uint256 amount) internal returns(bool) {
        return true;
    }

    function treasury_give(address to, uint256 amount) internal returns(bool) {
        return true;
    }

    function treasuryFund() public view returns(uint256){
        return _token.balanceOf(address(this));
    }

    function treasuryWithdraw() public returns(bool){
        return true;
    }
}