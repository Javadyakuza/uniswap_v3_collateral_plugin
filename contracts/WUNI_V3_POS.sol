//SPDX-License-Identifier: MIT

pragma solidity >=0.6.8 <=0.8.18;

import "./IwUNI_V3_POS.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract WUNI_V3_POS is IwUNI_V3_POS, ERC20, ERC20Burnable, Ownable{

    constructor() ERC20("WUNI_V3_POS", "WUVP") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _burnFrom(address account, uint256 amount) external onlyOwner{
        burnFrom(account, amount);
    }

    function totalSupply() public view override(ERC20, IwUNI_V3_POS)returns(uint256 _totalSupply){
        return totalSupply();
    }

    function _balanceOf(address account) public view virtual override returns (uint256) {
        return balanceOf(account);
    }
}