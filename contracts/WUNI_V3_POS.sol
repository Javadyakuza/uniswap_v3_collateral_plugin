//SPDX-License-Identifier: MIT

import "./IwUNI_V3_POS.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.18;

contract WUNI_V3_POS is ERC20, ERC20Burnable, Ownable{

    constructor() ERC20("WUNI_V3_POS", "WUVP") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _burnFrom(address account, uint256 amount) external onlyOwner{
        burnFrom(account, amount);
    }
}