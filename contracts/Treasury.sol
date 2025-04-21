// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AccessControl.sol";

/// @title Treasury
/// @notice The main contract to handle TXs of $TiQet coin
/// @author [KAYT33N](https://github.com/KAYT33N)
/// @dev Will be driven in the main contract
contract Treasury is AccessControl {

    ERC20 immutable public _treasury_qusdt;
    /// @notice Address of the currency token 
    ERC20 immutable public _treasury_token;
    /// @notice Used to limit owners from withdrawing whole fund
    /// @dev 1 means %0.01 of the total supply in circulation
    uint256 constant public _treasury_withdraw_threshold = 3000;

    /// @notice Constructor function
    /// @param token Address of the currency token
    constructor(address token, address qusdt){
        _treasury_token = ERC20(token);
        _treasury_qusdt = ERC20(qusdt);
    }

    /// @notice Fucntion to take money from buyers wallets
    /// @dev The contract should be approved for the ttransfer
    /// @param from the address to collect tokens from
    /// @param amount amount of tokens to be transfered
    /// @return bool true if not reverted
    function treasury_token_collect(address from, uint256 amount) internal returns(bool) {
        require(_treasury_token.allowance(from, address(this)) >= amount, "412");
        require(_treasury_token.balanceOf(from) >= amount, "417");
        _treasury_token.transferFrom(from, address(this), amount);
        return true;
    }

    /// @notice Function to transfer money to addresses
    /// @param to The address to transfer tokens to
    /// @param amount amount of tokens to be transfered
    /// @return bool true if not reverted
    function treasury_token_give(address to, uint256 amount) internal returns(bool) {
        require(treasuryFund() >= amount, "507");
        _treasury_token.transfer(to, amount);
        return true;
    }

    /// @notice To get current balance of this contract
    /// @return uint256 amount of tokens owned by this contract
    function treasuryFund() public view returns(uint256){
        return _treasury_token.balanceOf(address(this));
    }

    /// @notice To withdraw overflowing tokens
    /// @dev Will be reverted if totalSupply is below threshold
    /// Only accesible by owner
    /// Wont let tokens to go below threshold by withdrawing
    /// @param amount The amount of tokens to be withdrawed
    /// @return bool true if not reverted
    function treasuryTokenWithdraw(uint256 amount) external eq_owner returns(bool){
        uint256 burned_tokens = _treasury_token.balanceOf(address(0));
        uint256 total_supply  = _treasury_token.totalSupply() - burned_tokens;
        uint256 threshold     = (total_supply / 10_000) * _treasury_withdraw_threshold;
        require(treasuryFund()-amount >= threshold, "412"); // below threshold
        _treasury_token.transfer(msg.sender, amount);
        return true;
    }

    /// @notice Fucntion to take money from buyers wallets
    /// @dev The contract should be approved for the ttransfer
    /// @param from the address to collect tokens from
    /// @param amount amount of tokens to be transfered
    /// @return bool true if not reverted
    function treasury_qusdt_collect(address from, uint256 amount) internal returns(bool) {
        require(_treasury_qusdt.allowance(from, address(this)) >= amount, "412");
        require(_treasury_qusdt.balanceOf(from) >= amount, "417");
        _treasury_qusdt.transferFrom(from, address(this), amount);
        return true;
    }

    /// @notice Function to transfer money to addresses
    /// @param to The address to transfer tokens to
    /// @param amount amount of tokens to be transfered
    /// @return bool true if not reverted
    function treasury_qusdt_give(address to, uint256 amount) internal returns(bool) {
        require(_treasury_qusdt.balanceOf(address(this)) >= amount, "507");
        _treasury_qusdt.transfer(to, amount);
        return true;
    }

    /// @notice to collect fees by the owner
    /// @param amount amount of qusdt to be collected
    function treasuryQUSDTWithdraw(uint256 amount) external eq_owner returns(bool){
        treasury_qusdt_give(msg.sender, amount);
        return true;
    }
}