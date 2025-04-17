// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AccessControl.sol";

/// @title Treasury
/// @notice The main contract to handle TXs of $TiQet coin
/// @author [KAYT33N](https://github.com/KAYT33N)
/// @dev Will be driven in the main contract
contract Treasury is AccessControl {

    ERC20 public token;

    function treasurySetTokenAddress(address value) external returns(bool) {
        token = ERC20(value);
    }

    function treasury_collect(address from, uint256 amount) internal returns(bool) {
        return true;
    }

    function treasury_give(address to, uint256 amount) internal returns(bool) {
        return true;
    }

    function treasuryFund() public view returns(uint256){
        return token.balanceOf(address(this));
    }
}