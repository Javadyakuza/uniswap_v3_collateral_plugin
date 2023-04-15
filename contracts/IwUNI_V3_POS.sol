//SPDX-License-Identifier: MIT

pragma solidity >=0.6.8 <=0.8.18;

interface IwUNI_V3_POS {
    /**
     * @dev this function mint's wUNI_V3_POS amount for "to".
     * @param to ETH_address to mint. 
     * @param amount the token amount in decimals of 18 to mint for "to".
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev this function burn's "amount" of wUNI_V3_POS from "account".
     * @param account ETH_address to burn token's from.
     * @param amount the token amount in decimals of 18 to burn from "account".
     */
    function _burnFrom(address account, uint256 amount) external;

    /**
     * @return _totalSupply returns the totalSupply of the wUNI_V3_POS 
     */
    function totalSupply() external view returns(uint256 _totalSupply);


    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function _balanceOf(address account) external view returns (uint256);
}
