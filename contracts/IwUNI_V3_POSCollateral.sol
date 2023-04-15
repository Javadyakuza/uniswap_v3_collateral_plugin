// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity >=0.6.8 <=0.8.18;

/**
 * @title wUNI_V3_POSCollateral
 * @notice Collateral plugin for uniswap V3 UNI_V3_POS's.
 * tok = wUNI_V3_POS
 * ref = wUNI_V3_POS
 * tar = USD
 * UoA = USD
 */
interface WUNI_V3_POSCollateral {

    /**
     * @notice this function will claim the required UNI_NFT_ID collected rewards
     * @notice couldnt overwrite the claim reward fucntion because we needed inputes 
     * @notice we could do it with out inputs which in that case it would be too costly and non-arbitary reward caliming for some user's  
     * @param _positionId the tokenId of the UNI_NFT
     * @param _recipient ETH_address of the rewards claimer
     */
    function claimRewardsForPositionId(uint256 _positionId, address _recipient) external;
    /**
     * @notice because of the demurrage collateral methode that the collateral token is its reference unit and basically the whole amount of the reference liquidity is the totalSupply of the wUNI_V3_POS   
     * @return referenceWholeAmount totalsupply of the wUNI_V3_POS  
     */ 
    function _underlyingRefPerTok() external view returns (uint192 referenceWholeAmount);

    /**
     * @notice the collateral method is demurrage collateraling therefor 
     * // the returning statment will be calculated throw this operation
     * >> ((1 + (demurrageRate / 31536000)) ** t);
     * @return refPerTok the ratio of the refPerTok based on the timeline 
     */
    function refPerTok() external view returns (uint256 refPerTok);

    /**
     * @notice divides the whole value of the tokenAmounts per USD to the whole amount of the liquidity and returns each refrence unit price in USD 
     * @return targetPerRef USD price per each unit of the referecne liquidity amount that is equal to the wUNI_v3_POS totalSupply 
     */
    function targetPerRef() external view returns(uint8 targetPerRef);

    /// Can revert, used by other contract functions in order to catch errors
    /// Should not return FIX_MAX for low
    /// Should only return FIX_MAX for high if low is 0
    /// @return low {UoA/tok} The low price estimate
    /// @return high {UoA/tok} The high price estimate
    /// @return pegPrice {target/ref} The actual price observed in the peg
    function tryPrice() external view returns (
            uint192 low,
            uint192 high,
            uint192 pegPrice
        );


    /// Should not revert
    /// Refresh exchange rates and update default status.
    /// @dev Should not need to override: can handle collateral with variable refPerTok()
    function refresh() external;
}
