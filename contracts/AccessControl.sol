// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title AccessControl
/// @notice The main contract to access control all contracts
/// @author [KAYT33N](https://github.com/KAYT33N)
/// @dev Will be driven in the main contract
contract AccessControl {
    
    //-----------------------==-----------------------//
    uint256 NOT_FOUND = type(uint256).max;
    //----------------------Vars----------------------//
    address public   _owner;
    address[] public _admins;
    address[] public _proposers;
    address[]  public _nftList;

    //-------------------Constructor------------------//
    constructor() {
        _owner   = msg.sender;
    }

    //--------------------Modifiers------------------//

    /// @notice Modifier to check if user is owner
    /// @dev is_authorized is created for more consistency
    /// @dev reverts if not authorized
    modifier eq_owner {
        bool is_authorized = auth_is_owner(msg.sender);
        require(is_authorized, "403");
        _;
    }

    /// @notice Modifier to check if user is graterthan or equal to admins
    /// @dev is_authorized is created for more consistency
    /// @dev reverts if not authorized
    modifier eqgt_admin {
        bool is_authorized = auth_is_owner(msg.sender);
        require(is_authorized, "403");
        _;
    }

    /// @notice Modifier to check if user is graterthan or equal to proposers
    /// @dev is_authorized is created for more consistency
    /// @dev reverts if not authorized
    modifier eqgt_proposer {
        bool is_authorized = auth_is_owner(msg.sender);
        require(is_authorized, "403");
        _;
    }

    /// @notice Modifier to check if user is graterthan or equal to holders
    /// @dev is_authorized is created for more consistency
    /// @dev reverts if not authorized
    modifier eqgt_holder {
        bool is_authorized = auth_is_owner(msg.sender);
        require(is_authorized, "403");
        _;
    }
    
    //--------------------Functions------------------//

    /// @notice Transfers owner to the desired address
    /// @dev Only current owner can call this function
    /// @param to The address of new owner
    /// @return bool true if not reverted
    function transferOwnership(address to) external eq_owner returns(bool) {
        _owner = to;
        return true;
    }

    /// @notice Adds an admin to the admins list
    /// @dev Accessible by the owner, checks for duplicates
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authAdminAdd(address operand) external eq_owner returns(bool){
        return true;
    }

    /// @notice Removes an admin from admins
    /// @dev Accessible by the owner, checks for existence
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authAdminRem(address operand) external eq_owner returns(bool){
        return true;
    }

    /// @notice Adds an proposer to the proposers list
    /// @dev Accessible by the owner, checks for duplicates
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authProposerAdd(address operand) external eq_owner returns(bool){
        return true;
    }

    /// @notice Removes an proposer from proposers
    /// @dev Accessible by the owner, checks for existence
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authProposerRem(address operand) external eq_owner returns(bool){
        return true;
    }

    /// @notice Adds an NFT to the NFTs list
    /// @dev Accessible by the owner, checks for duplicates
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authNftAdd(address operand) external eq_owner returns(bool){
        return true;
    }

    /// @notice Removes an NFT from NFTs
    /// @dev Accessible by the owner, checks for existence
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authNftRem(address operand) external eq_owner returns(bool){
        return true;
    }

    //----------------------Utils---------------------//

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` is owner, and false otherwise
    function auth_is_owner(address check) public view returns(bool){
        return _owner == check;
    }

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` is admin, and false otherwise
    function auth_is_admin(address check) public view returns(bool){
        return false;
    }

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` is proposer, and false otherwise
    function auth_is_proposer(address check) public view returns(bool){
        return false;
    }

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` has nft, and false otherwise
    function auth_is_nftholder(address check) public view returns(bool){
        return false;
    }

    
}
