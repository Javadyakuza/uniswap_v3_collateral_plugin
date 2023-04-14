// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "protocol/contracts/libraries/Fixed.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import "protocol/contracts/plugins/assets/AppreciatingFiatCollateral.sol";
import "protocol/contracts/plugins/assets/OracleLib.sol";
import "./IUNI_V3_POS_Wrapper.sol";
import "./libraries/LiquidityAmountCalculator.sol";
/**
 * @title wUNI_V3_POSCollateral
 * @notice Collateral plugin for uniswap V3 UNI_V3_POS's.
 * tok = wUNI_V3_POS
 * ref = UNI_V3_POS_underlying0 + UNI_V3_POS_underlying1 LIQUIDIY 
 * tar = USD
 * UoA = USD
 */
contract WUNI_V3_POSCollateral is AppreciatingFiatCollateral {

    using OracleLib for AggregatorV3Interface;
    using FixLib for uint192;

    IUniswapV3Pool constant public pairPool;
    IERC20 public rewardERC20;
    IUNI_V3_POS_Wrapper wrapper;
    AggregatorV3Interface chainLinkBranch
    // uint256 public immutable reservesThresholdIffy; // {qUSDC}

    /// @param config.chainlinkFeed Feed units: {UoA/ref}
    constructor(
        IUNI_V3_POS_Wrapper tempIUNI_V3_POS_Wrapper,
        IUniswapV3Pool _pairPool,
        CollateralConfig memory config,
        
    ) AppreciatingFiatCollateral(config, revenueHiding) {
        wrapper = IUNI_V3_POS_Wrapper(tempIUNI_V3_POS_Wrapper);
        pairPool = IUniswapV3Pool(_pairPool);
    }

    function claimRewards(uint256 _positionId, address _recipient) external override(Asset, IRewardable) {
        (address token0 , uint256 amount0, address token1 , uint256 amount1) = wrapper.claimRewards(msg.sender, _positionId, _recipient);
        emit RewardsClaimed(rewardERC20(token0), amount0);
        emit RewardsClaimed(rewardERC20(token1), amount1);

    }

    function _underlyingRefPerTok() internal view virtual override returns (uint192 collateralAmount, uint192 amountForPrice) {
        (uint256 amount0, uint256 amount1, uint24 tickLowest, uint24 tickUppermost, uint24 initialLowerTick, uint24 initialUpperTick) = wrapper.pairTokenInformation(pairPool.token0(), pairPool.token1());
        return (calculateAmounts.getWholeAmountsLiquidity(amount0, amount1, initialLowerTick, initialUpperTick, pairPool), calculateAmounts.getWholeAmountsLiquidity(amount0, amount1, initialLowerTick, initialUpperTick, pairPool));
    }

    function refPerTok(){};
    // function targetPerRef(){}; not required, underlyingtoken0,underlyingtoken1 always equal underlyingtoken0,underlyingtoken1. 

    /// Can revert, used by other contract functions in order to catch errors
    /// Should not return FIX_MAX for low
    /// Should only return FIX_MAX for high if low is 0
    /// @return low {UoA/tok} The low price estimate
    /// @return high {UoA/tok} The high price estimate
    /// @return pegPrice {target/ref} The actual price observed in the peg
    function tryPrice()
        external
        view
        virtual
        override
        returns (
            uint192 low,
            uint192 high,
            uint192 pegPrice
        )
    {
        // assert(low <= high); obviously true just by inspection
        // {target/ref} = {UoA/ref} / {UoA/target} >> USD/wUNI_V3_POS_LIQ = USD/wUNI_V3_POS_LIQ / USD/USD(1)
        // every collateral plugin only supports one pair so the pairPool is constant  
        pegPrice = wrapper.wUNI_V3_POSPrice(pairPool);

        // {UoA/tok} = {target/ref} * {ref/tok} * {UoA/target} (1)
        (,uint192 _underlyingRefPerTok) = _underlyingRefPerTok()
        uint192 p = pegPrice.mul(_underlyingRefPerTok);
        uint192 err = p.mul(oracleError, CEIL);

        low = p - err;
        high = p + err;
 
    }


    /// Should not revert
    /// Refresh exchange rates and update default status.
    /// @dev Should not need to override: can handle collateral with variable refPerTok()
    function refresh() public virtual override {
        (uint192 _underlyingRefPerTok, ) = _underlyingRefPerTok()
        if (alreadyDefaulted()) {
            // continue to update rates
            exposedReferencePrice = _underlyingRefPerTok.mul(revenueShowing);
            return;
        }

        CollateralStatus oldStatus = status();

        // Check for hard default
        // must happen before tryPrice() call since `refPerTok()` returns a stored value

        // revenue hiding: do not DISABLE if drawdown is small
        uint192 underlyingRefPerTok = _underlyingRefPerTok;

        // {ref/tok} = {ref/tok} * {1}
        uint192 hiddenReferencePrice = underlyingRefPerTok.mul(revenueShowing);

        // uint192(<) is equivalent to Fix.lt
        if (underlyingRefPerTok < exposedReferencePrice) {
            exposedReferencePrice = hiddenReferencePrice;
            markStatus(CollateralStatus.DISABLED);
        } else if (hiddenReferencePrice > exposedReferencePrice) {
            exposedReferencePrice = hiddenReferencePrice;
        }

        // Check for soft default + save prices
        try this.tryPrice() returns (uint192 low, uint192 high, uint192 pegPrice) {
            // {UoA/tok}, {UoA/tok}, {target/ref}
            // (0, 0) is a valid price; (0, FIX_MAX) is unpriced

            // Save prices if priced
            if (high < FIX_MAX) {
                savedLowPrice = low;
                savedHighPrice = high;
                lastSave = uint48(block.timestamp);
            } else {
                // must be unpriced
                assert(low == 0);
            }

            // If the price is below the default-threshold price, default eventually
            // uint192(+/-) is the same as Fix.plus/minus
            if (pegPrice < pegBottom || pegPrice > pegTop || low == 0) {
                markStatus(CollateralStatus.IFFY);
            } else {
                markStatus(CollateralStatus.SOUND);
            }
        } catch (bytes memory errData) {
            // see: docs/solidity-style.md#Catching-Empty-Data
            if (errData.length == 0) revert(); // solhint-disable-line reason-string
            markStatus(CollateralStatus.IFFY);
        }

        CollateralStatus newStatus = status();
        if (oldStatus != newStatus) {
            emit CollateralStatusChanged(oldStatus, newStatus);
        }
    }
}
