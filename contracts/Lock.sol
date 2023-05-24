// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ArbiPool is ERC20 {
    uint public unlockTime;
    address payable public owner;
    IERC20 public usdt;

    event buy(uint amount);

    constructor(address _usdt, uint _unlockTime) ERC20("ArbiPool", "ARP") {
        require(
            block.timestamp < _unlockTime,
            "Unlock time sould be in the future"
        );
        usdt = IERC20(_usdt);
        unlockTime = _unlockTime;
        owner = payable(msg.sender);
        _mint(msg.sender, 100000 * (10 ** uint256(decimals())));
    }

    function buy(uint256 _amount) external {
        require(usdt.transferFrom(msg.sender, address(this), _amount), "transfer failed");
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(block.timestamp >= unlockTime, "Contract is still locked");
        
        usdt.transfer(owner, _amount);
    }
}

