// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

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
    address[] public _nftList;

    //-------------------Constructor------------------//
    constructor() {
        _owner   = msg.sender;
    }

    //--------------------Modifiers------------------//

    /// @notice Modifier to check if user is owner
    /// @dev is_authorized is created for more consistency
    /// , reverts if not authorized
    modifier eq_owner {
        bool is_authorized = auth_is_owner(msg.sender);
        require(is_authorized, "403");
        _;
    }

    /// @notice Modifier to check if user is graterthan or equal to admins
    /// @dev is_authorized is created for more consistency
    /// , reverts if not authorized
    modifier eqgt_admin {
        bool is_authorized = 
            auth_is_owner(msg.sender)
            || auth_is_admin(msg.sender);
        require(is_authorized, "403");
        _;
    }

    /// @notice Modifier to check if user is graterthan or equal to proposers
    /// @dev is_authorized is created for more consistency
    /// , reverts if not authorized
    modifier eqgt_proposer {
        bool is_authorized = 
            auth_is_owner(msg.sender)
            || auth_is_admin(msg.sender)
            || auth_is_proposer(msg.sender)
            || auth_is_nftholder(msg.sender);
        require(is_authorized, "403");
        _;
    }
    
    //--------------------Functions------------------//

    /// @notice Transfers owner to the desired address
    /// @dev Only current owner can call this function
    /// @param to The address of new owner
    /// @return bool true if not reverted
    function authOwnershipTransfer(address to) external eq_owner returns(bool) {
        _owner = to;
        return true;
    }

    /// @notice Adds an admin to the admins list
    /// @dev Accessible by the owner, checks for duplicates
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authAdminAdd(address operand) external eq_owner returns(bool){
        uint256 index = array_find(operand, _admins);
        require(index==NOT_FOUND, "409");
        array_add(operand, _admins);
        return true;
    }

    /// @notice Removes an admin from admins
    /// @dev Accessible by the owner, checks for existence
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authAdminRem(address operand) external eq_owner returns(bool){
        uint256 index = array_find(operand, _admins);
        require(index!=NOT_FOUND, "404");
        array_rem(index, _admins);
        return true;
    }

    /// @notice Adds an proposer to the proposers list
    /// @dev Accessible by the owner, checks for duplicates
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authProposerAdd(address operand) external eq_owner returns(bool){
        uint256 index = array_find(operand, _proposers);
        require(index==NOT_FOUND, "409");
        array_add(operand, _proposers);
        return true;
    }

    /// @notice Removes an proposer from proposers
    /// @dev Accessible by the owner, checks for existence
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authProposerRem(address operand) external eq_owner returns(bool){
        uint256 index = array_find(operand, _proposers);
        require(index!=NOT_FOUND, "404");
        array_rem(index, _proposers);
        return true;
    }

    /// @notice Adds an NFT to the NFTs list
    /// @dev Accessible by the owner, checks for duplicates
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authNftAdd(address operand) external eq_owner returns(bool){
        uint256 index = array_find(operand, _nftList);
        require(index==NOT_FOUND, "409");
        array_add(operand, _nftList);
        return true;
    }

    /// @notice Removes an NFT from NFTs
    /// @dev Accessible by the owner, checks for existence
    /// @param operand address of the target user
    /// @return bool true if not reverted
    function authNftRem(address operand) external eq_owner returns(bool){
        uint256 index = array_find(operand, _nftList);
        require(index!=NOT_FOUND, "404");
        array_rem(index, _nftList);
        return true;
    }

    /// @notice Returns access level of `check`
    /// @param check The address to check
    /// @return string "owner"|"admin"|"proposer"|"user"
    function authWhoami(address check) external view returns(string memory){
        if(auth_is_owner(check)) return "owner";
        if(auth_is_admin(check)) return "admin";
        if(auth_is_proposer(check) || auth_is_nftholder(check)) return "proposer";
        return "user";
    }

    //----------------------Utils---------------------//

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` is owner, and false otherwise
    function auth_is_owner(address check) internal view returns(bool){
        return _owner == check;
    }

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` is admin, and false otherwise
    function auth_is_admin(address check) internal view returns(bool){
        return array_find(check, _admins)!=NOT_FOUND;
    }

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` is proposer, and false otherwise
    function auth_is_proposer(address check) internal view returns(bool){
        return array_find(check, _proposers)!=NOT_FOUND;
    }

    /// @notice Will be used in modifiers
    /// @param check The address to be checked
    /// @return bool true if `check` has nft, and false otherwise
    function auth_is_nftholder(address check) internal view returns(bool){
        uint256 len = _nftList.length;
        for (uint256 i = 0; i < len; i++) {
            ERC721 nft_contract = ERC721(_nftList[i]);
            if (nft_contract.balanceOf(check) > 0){
                return true;
            }
        }
        return false;
    }

    /// @notice Helper function for crud operations
    /// @dev Finds a value's index in an array
    /// @param needle address to find
    /// @param heystack the array to be searched
    /// @return uint256 `2^256-1` if not found, the index of value otherwise
    function array_find(address needle, address[] storage heystack) internal view returns(uint256){
        uint256 len = heystack.length;
        for (uint256 i = 0; i < len; i++) {
            if(heystack[i]==needle){
                return i;
            }
        }
        return NOT_FOUND;
    }
    /// @notice Helper function for crud operations
    /// @dev Adds a value to the end of an array
    /// @param value address to add
    /// @param arr the operand array
    /// @return bool true if done
    function array_add(address value, address[] storage arr) internal returns(bool){
        arr.push(value);
        return true;
    }
    /// @notice Helper function for crud operations
    /// @dev Removes an index from an array, shifts back other values
    /// @param index index to be removed
    /// @param arr the operand array
    /// @return bool true if done
    function array_rem(uint256 index, address[] storage arr) internal returns(bool){
        uint256 len = arr.length;
        require(index < len, "409");
        for (uint256 i = index; i < len-1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
        return true;
    }
}
