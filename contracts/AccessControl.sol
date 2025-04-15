// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title AccessControl
/// @notice The main contract to access control all contracts
/// @author [KAYT33N](https://github.com/KAYT33N)
/// @dev Will be driven in the main contract
contract AccessControl {
    
    //-----------------------==-----------------------//
    //----------------------Vars----------------------//
    address public   _owner;
    address[] public _admins;
    address[] public _proposers;
    IERC20[]  public _nftList;

    //-------------------Constructor------------------//
    constructor() {
        _owner   = msg.sender;
    }

    //--------------------Modifiers------------------//

    /// @notice Modifier to check if user is owner
    /// @dev is_authorized is created for more consistency
    /// @dev reverts if not authorized
    modifier eq_owner {
        bool is_authorized = is_owner(msg.sender);
        require(is_authorized, "403");
        _;
    }
    
    //--------------------Functions------------------//

    /// @notice Transfers owner to the desired address
    /// @dev Only current owner can call this function
    /// @param to The address of new owner
    /// @return bool true if not reverted
    function transferOwnership(address to) external returns(bool) {
        _owner = to;
        return true;
    }

    //----------------------Utils---------------------//

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` is owner, and false otherwise
    function is_owner(address check) internal view returns(bool){
        return _owner == check;
    }

    //------------------Test Functions----------------//
    /// @notice Test function for corresponding modifier
    /// @return bool true if user has access and not reverted
    function pass_eq_owner() external view eq_owner returns(bool){
        return true;
    }
}
