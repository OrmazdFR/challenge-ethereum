// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Avant d'appeler la fonction buy, il faut approuver la transaction ?

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Ownable est un contrat de la bibliothèque OpenZeppelin qui implémente la notion de propriétaire. 
// Par défaut, le compte qui déploie le contrat est défini comme le propriétaire.

contract ArbiPool is ERC20, Ownable {
    IERC20 public usdt;
    uint256 public unlockTime;
    uint256 public constant LOCK_PERIOD = 6 * 30 days;
    mapping(address => uint256) public lastPurchase;

    event Buy(uint amount);

    constructor(address _usdt, uint _unlockTime, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );
        usdt = IERC20(_usdt);
        unlockTime = _unlockTime;
        _mint(msg.sender, 100000 * (10 ** uint256(decimals())));
    }

    function buy(uint256 _amount) external {
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

// OnlyOwner est un modificateur de fonction qui restreint l'accès à la fonction uniquement au propriétaire du contrat.
// Cette fonction permet à l'administrateur de récupérer les fonds du contract

    function withdraw(uint256 _amount) public onlyOwner {
        require(usdt.balanceOf(address(this)) >= _amount, "Contract has insufficient USDT");
        require(usdt.transfer(owner(), _amount), "USDT transfer failed");
    }
}
