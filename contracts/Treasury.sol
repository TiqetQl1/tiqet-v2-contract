// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AccessControl.sol";

/// @title Treasury
/// @notice The main contract to handle TXs of $TiQet coin
/// @author [KAYT33N](https://github.com/KAYT33N)
/// @dev Will be driven in the main contract
contract Treasury is AccessControl {

    ERC20 immutable public _token;
    uint256 constant public _withdraw_threshold = 3000; // 1 is %0.01
    constructor(address token){
        _token = ERC20(token);
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