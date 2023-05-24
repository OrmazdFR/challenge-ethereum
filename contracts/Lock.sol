// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//Access Control imports
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

//test

abstract contract ArbiPool is AccessControl, ERC20 {
    uint public unlockTime;
    address payable public owner;
    IERC20 public usdt;

    bytes32 public constant BANNED_ROLE = keccak256("BANNED");
    bytes32 public constant CUSTOM_ADMIN = keccak256("ADMIN");

    constructor(address _usdt, uint _unlockTime) ERC20("ArbiPool", "ARP") {
        require(
            block.timestamp < _unlockTime,
            "Unlock time sould be in the future"
        );
        usdt = IERC20(_usdt);
        unlockTime = _unlockTime;
        owner = payable(msg.sender);
        _setRoleAdmin(CUSTOM_ADMIN, DEFAULT_ADMIN_ROLE);
        _grantRole(CUSTOM_ADMIN, msg.sender);
        _mint(msg.sender, 100000 * (10 ** uint256(decimals())));
    }

    function buy(uint256 _amount) external {
        require(!isBanned(msg.sender), "Can't buy if your address is banned");
        require(usdt.transferFrom(msg.sender, address(this), _amount), "transfer failed");
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp >= unlockTime, "Contract is still locked");
        
        usdt.transfer(owner, _amount);
    }

    function banAddress(address accountToBan) external {
        require(isAdmin(msg.sender), "Restricted to admins");
        grantRole(BANNED_ROLE, accountToBan);
    }

    function isAdmin(address account) public virtual view returns (bool) {
        return hasRole(CUSTOM_ADMIN, account);
    }

    function isBanned(address account) public virtual view returns (bool) {
        return hasRole(BANNED_ROLE, account);
    }
}

