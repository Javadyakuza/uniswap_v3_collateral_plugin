//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IwUNI_V3_POS is IERC20Metadata{
    /**
     * @notice this function mint's wUNI_V3_POS amount for "to".
     * @param to ETH_address to mint. 
     * @param amount the token amount in decimals of 18 to mint for "to".
     */
    function mint(address to, uint256 amount) external;
    /**
     * @notice this function burn's "amount" of wUNI_V3_POS from "account".
     * @param account ETH_address to burn token's from.
     * @param amount the token amount in decimals of 18 to burn from "account".
     */
    function _burnFrom(address account, uint256 amount) external;

}