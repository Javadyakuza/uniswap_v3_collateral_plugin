// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.18;

/// @title wUNI-V3_POS wrapper contract
/// @notice every pair in a uniswap pool will have a seperate ERC-20 token but all of them are wrapperaable by this wrapper contract. 
 interface IUNI_V3_POS_Wrapper {
    /**
     * @notice this function will return a instance of the PairInfo struct
     * @param token0 the ETH_address of the first token (token0)
     * @param token1 the ETH_address of the second token (token1)
     * @return amount0 a instance of the PairInfo struct 
     * @return amount1 a instance of the PairInfo struct 
     * @return tickLowest the lowest tick ever determined from the deposited positions
     * @return tickUppermost the highest tick ever determined from the deposited positions
     * @return initialLowerTick a constant lower tick that is used to calculate the mint amount of wUNI_V3_POS 
     * @return initialUpperTick a constant upper tick that is used to calculate the mint amount of wUNI_V3_POS 
     */
    function pairTokenInformation(address token0, address token1) external view returns(uint256 amount0, uint256 amount1, uint24 tickLowest, uint24 tickUppermost, uint24 initialLowerTick, uint24 initialUpperTick); 
    /**
     * @notice this fucntion transfer's the tokenId of UNI_NFT to address(this) and then "MINTS" related amount of wUNI_V3_POS ERC-20 token for the depositor.
     * @notice this function mint's different ERC-20 per each pool token, e.g. we have a seperate ERC-20 token fro DAI/USDC positionManager than USDT/USDC positionManager.   
     * @notice  minted wUNI_V3_POS amount : underlyingtoken0Amount + underlyingtoken1Amount 
     * @param _positionId tokenId of the UNI_NFT.
     * @param _poolAddress ETH_address of the UNI_NFT underlying token's.
     * @param _uni_v3_pos_address ETH_address of the UNI_NFT.
     * @return mintedwUNI_V3_POSAmount amount of the wUNI_V3_POS minted for the depositor, this amount is equal to the NFT liquidity.
     */
    function deposit(uint256 _positionId , address _poolAddress , address _uni_v3_pos_address) external returns(uint256 mintedwUNI_V3_POSAmount);
    /**
     * @notice this function "BURNS" the wUNI_V3_POS owned amount by the user and then transfer's back the requested tokenID to the user.
     * @param _positionId tokenId of the UNI_NFT.
     */
    function withdraw(uint256 _positionId) external;
    /**
     * @notice this function fetches the  a specific tokenId of UNI_V3_POS price. 
     * @notice see the {PriceCalculator.sol}.
     * @param _positionId tokenId of the UNI_NFT.
     * @return _nftIdPrice _nftIdPrice specific tokenId of UNI_V3_POS price.
     */
    function nftIdPrice(uint256 _positionId) external view returns(uint256 _nftIdPrice);
      /**
     * @notice this function fetches the wUNI_V3_POS ERC-20 collateral token price. 
     * @notice see the {PriceCalculator.sol}.
     * @return _wUNI_V3_POSPrice wUNI_V3_POS ERC-20 collateral token price.
     */
    function wUNI_V3_POSPrice() external view returns(uint256 _wUNI_V3_POSPrice);
    /**
     * @notice this fucntion changes the ETH_address of the UNI_V3_FACTORY contract 
     * @param _newFactoryAddress ETH_address of the UNI_V3_FACTORY 
     */
    function changeFactory(address _newFactoryAddress) external;
    /**
     * @notice this function deposites all of the earned fee's on a tokenId to the "_recipient".
     * @param _positionId the tokenId of the UNI_NFT. 
     * @param _recipient the receiver of the rewards(fee's earned).
     * @return token0 ETH_address of the underlying token0 
     * @return amount0 amount of fee collected in token0.
     * @return token1 ETH_address of the underlying token1 
     * @return amount1 amount of fee collected in token1.
     */
    function claimRewards(uint256 _positionId, address _recipient) external returns(address token0, uint256 amount0, address token1, uint256 amount1);
    /**
     * @notice this function updates the underlying token amounts and the position liquidity in case of difference.
     * @param _positionId the tokenId of the UNI_NFT. 
     * @return _isChanged is the old data different and changed with the new data.  
     */
    function updatePositionParams(uint256 _positionId) external returns(bool _isChanged);
}
