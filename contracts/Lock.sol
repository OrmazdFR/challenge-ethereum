// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

//Access Control imports
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
// Avant d'appeler la fonction buy, il faut approuver la transaction ?

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Ownable est un contrat de la bibliothèque OpenZeppelin qui implémente la notion de propriétaire. 
// Par défaut, le compte qui déploie le contrat est défini comme le propriétaire.

abstract contract ArbiPool is AccessControl, ERC20 {
    uint public unlockTime;
    address payable public owner;
    IERC20 public usdt;
    uint256 public constant LOCK_PERIOD = 6 * 30 days;
    mapping(address => uint256) public lastPurchase;

    bytes32 public constant BANNED_ROLE = keccak256("BANNED");
    bytes32 public constant CUSTOM_ADMIN = keccak256("ADMIN");
    event Buy(uint amount);

    constructor(address _usdt, uint _unlockTime, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
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
        lastPurchase[msg.sender] = block.timestamp;
    }

    function sell(uint256 _amount) external {
        require(block.timestamp - lastPurchase[msg.sender] >= LOCK_PERIOD, "Tokens are locked");
        // Vérifie la balance de l'utilisateur
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        // Burn les tokens ARP
        _burn(msg.sender, _amount);
        // Transfert des USDT à l'utilisateur
        require(usdt.transfer(msg.sender, _amount), "USDT transfer failed");
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
