// SPDX-License-Identifier: MIt

pragma solidity >=0.6.8 <=0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "../IwUNI_V3_POSCollateral.sol";
import '../IUNI_V3_POS_Wrapper.sol';
library PriceCalculator {

    FeedRegistryInterface constant private registery = FeedRegistryInterface(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf);
    IUNI_V3_POS_Wrapper constant private wUNI_V3_POS_Wrapper =  IUNI_V3_POS_Wrapper(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf); 

    // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
    address constant internal USD = address(840);
    
 /**
  * @notice this function uses this formula to calculate the minted wUNI_V3_POS ERC-20 tokens :
  *(TokenValue) = ( PositionValueInUSD / PositionLiquidity );
  *         >> TV = ( PV / PL )
  *  
  */   
function wUNI_V3_POSPriceCalculator(IUniswapV3Pool _pool) internal view returns(uint192 _wUNI_V3_POSPrice, uint192 _whole_wUNI_V3_POSPrice){
    // temp variables 
    ERC20 tempToken0 = ERC20(_pool.token0());
    ERC20 tempToken1 = ERC20(_pool.token1());

    // fetching the pool liquidity (PL) 
    (uint256 token0Amount, uint256 token1Amount, , , ,) = wUNI_V3_POS_Wrapper.pairTokenInformation(address(tempToken0), address(tempToken1));
    uint256 PL = token0Amount + token1Amount;
    PL = PL - (PL / 10);
    // fetching the prices of the tokens 
    (,int price0, , , ) = registery.latestRoundData(address(tempToken0),USD);
    (,int price1, , , ) = registery.latestRoundData(address(tempToken1),USD);

    // calculatinig the the whole value of the pool 
    uint256 PV = (token0Amount * uint256(price0)) + (token1Amount * uint256(price1));

    // calculating the TV
    uint256 TV = (PV / PL);

    // returning the statment
    return (uint192(TV), uint192(PV));

}

function UNI_V3_POSPriceCalculator(IUniswapV3Pool _pool, uint256 underlyingToken0Amount, uint256 underlyingToken1Amount) internal view returns(uint256 _UNI_V3POSPrice){
            (,int price0,,,) =  registery.latestRoundData(address(ERC20(_pool.token0())),USD); 
            (,int price1,,,) =  registery.latestRoundData(address(ERC20(_pool.token1())),USD); 
            return (underlyingToken0Amount * uint256(price0)) + (underlyingToken1Amount * uint256(price1));
    }
}