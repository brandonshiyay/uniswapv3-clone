// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/tokens/ERC20.sol";
import "forge-std/console.sol";

contract ERC20Mintable is ERC20{
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address to, uint256 amount) public{
        _mint(to, amount);
    }


    function transferFrom(
        address payer, 
        address recipient, 
        uint256 amount) public override returns (bool) {
        console.log("ERC20 transfer event: from %s to %s, caller %s", payer, recipient, msg.sender);
        return super.transferFrom(payer, recipient, amount);
    }

}