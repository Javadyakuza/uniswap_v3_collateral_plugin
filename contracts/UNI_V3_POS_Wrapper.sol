// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@uniswap/v3-periphery/contracts/libraries/PositionValue.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "./WUNI_V3_POS.sol";
import "./IwUNI_V3_POS.sol";
import "./libraries/PriceCalculator.sol";
import "./libraries/LiquidityAmountCalculator.sol";
/// @title wUNI-V3_POS wrapper contract

 contract UNI_V3_POS_Wrapper is Ownable, IwUNI_V3_POS, WUNI_V3_POS, INonfungiblePositionManager, IUniswapV3Pool, ERC20{
    
    address public factoryAddress;
    IUniswapV3Pool public pool;
    address pulic collateralPlugin; 
    constructor(
        address _factoryAddress,
          ){
        factoryAddress = _factoryAddress;
    }
    // amount0 and amount1 are the underlyingtoken amounts of a specific UNI_NFT of pair 
    // @notice tickUppermost and tickLowest are used to calculate the whole liquidity for thr _underlyingRefpereTok uint amount.
    struct PairInfo{
        uint256 amount0;
        uint256 amount1;
        uint24 tickUppermost; // uppermost tick in all of the positions 
        uint24 tickLowest; // lowest tick in all of the positions
    }

    PairTicks{
        uint24  initialLowerTick; // will be used to calculate the wUNI_V3_POS minting amount in temrs of overcollateralaziation (constructor intialing)
        uint24  initialUpperTick; // will be used to calculate the wUNI_V3_POS minting amount in temrs of overcollateralaziation (constructor intialing)
    }

    struct PositionParams{
        address owner; //const
        address poolAddress; //const
        address uni_v3_pos_address; //const
        uint256 uni_v3_pos_id; //const
        uint256 index; //various (changes in withdrawal)
        address underlyingToken0; //const
        address underlyingToken1; //const
        uint256 underlyingToken0Amount; // decimals is 18 //various (changes in updatePositionParams)
        uint256 underlyingToken1Amount; // decimals is 18 //various (changes in updatePositionParams)
        uint128 positionLiquidity; //various (changes in updatePositionParams)
    }
    
    mapping(address => unit256[]) public ownerNfts;
    mapping(uint256 => PositionParams) public positionInfo;
    // mapping(address => AggregatorV3Interface) public chainLinkPriceFeed;
    mapping(uint8 => address) public indexPerToken;
    /// @notice the ordering of the token0 and token1 will be setted based on the pool token ordering.
    mapping(address => mapping(address => IwUNI_V3_POS)) public pairPerErc20; // address(USDC) / address(USDT) = specific_erc20_token.
    mapping(address => mapping(address => PairInfo)) public pairTokenAmounts;
    mapping(address => mapping(address => PairTicks)) public pairTokenTicks; // will return the the intialing ticks

    modifier isReal(uint256 _positionId){
        require(_positionId[_positionId].owner == address(0), "position id doesn't exist's !!");
        _;
    }
    function deposit(uint256 _positionId , address _poolAddress , address _uni_v3_pos_address) external override returns(uint256 mintedwUNI_V3_POSAmount){

        // depositing the nft to the collateral address 
        INonfungiblePositionManager tempINonfungiblePositionManager = INonfungiblePositionManager(_uni_v3_pos_address)
        tempINonfungiblePositionManager.transferFrom(msg.sender, address(this), _positionId);

        // fetching the principal amount of the tokens 
        IUniswapV3Pool tempIUniswapV3Pool = IUniswapV3Pool(_poolAddress);
        (uint160 sqrtPriceX96, , , , , , ,) = tempIUniswapV3Pool.slot0();
        (uint256 amount0, uint256 amount1) = PositionValue.principal(_uni_v3_pos_address, _positionId , sqrtPriceX96);

        // conevrting the tokens decimals incase if they are not "18" to "18".
        if ((18 - tempIUniswapV3Pool.token0().decimals()) != 0){
            amount0 = amount0 * (10**(18 - ERC20(tempIUniswapV3Pool.token0()).decimals()));
        }
        if ((18 - tempIUniswapV3Pool.token1().decimals()) != 0){
            amount1 = amount1 * (10**(18 - ERC20(tempIUniswapV3Pool.token1()).decimals()));
        }
        
        // updating PairInfo and generatinig the mint amount  
        PairInfo memory tempPairInfo = pairTokenAmounts[tempIUniswapV3Pool.token0()][tempIUniswapV3Pool.token1()];
        PairTicks memory temoPairTicks = pairTokenTicks[tempIUniswapV3Pool.token0()][tempIUniswapV3Pool.token1()];
        uint256 mintAmountRaw = calculateAmounts.getWholeAmountsLiquidity(amount0, amount1, temoPairTicks.initialLowerTick, temoPairTicks.initialUpperTick);
        uint256 mintAmount = mintAmountRaw - (mintAmountRaw / 10);
        // @param TL = tickLoer, TU = tickUpper 
        (uint24 TL, uint24 TU) = (tempINonfungiblePositionManager.tickLower, tempINonfungiblePositionManager.tickUpper)
        if (tempPairInfo.tickUppermost > TU) TU = tempPairInfo.tickUppermost;  
        if (tempPairInfo.tickLowest > TL) TU = tempPairInfo.tickLowest;  
        pairTokenAmounts[tempIUniswapV3Pool.token0()][tempIUniswapV3Pool.token1()] = PairInfo(amount0 + tempPairInfo.amount0, amount1 + tempPairInfo.amount1, TL, TU);

        // adding the information to the "ownerNfts" and "positionInfo" mappings 
        ownerNfts[msg.sender].push(_positionId);
        positionInfo[_positionId] = PositionParams(msg.sender, _poolAddress, _uni_v3_pos_address, _positionId, ownerNfts[msg.sender] - 1, tempIUniswapV3Pool.token0(), tempIUniswapV3Pool.token1(), amount0, amount1, tempINonfungiblePositionManager.positions(_positionId).liquidity);

        // minting the amount0 + amount1 to the depositor 
        pairPerErc20[tempIUniswapV3Pool.token0()][tempIUniswapV3Pool.token1()].mint(msg.sender, mintAmount);
    }

    function withdraw(uint256 _positionId) external override isReal(_positionId) {
        updatePositionParams(_positionId);

        require(positionInfo[_positionId].owner == msg.sender,"you don't own this positionId !!");

        // burning the whole owned amount of the WUNI_V3_POS that user has
        // the allowance will be called directly from the wUNI_v3_POS contract
        pairPerErc20[positionInfo[_positionId].underlyingToken0][positionInfo[_positionId].underlyingToken0].burnFrom(msg.sender, wUNI_v3_POS.balanceOf(msg.sender));
        
        // decreasing the paitTokenAmounts
        PairInfo tempPairInfo = pairTokenAmounts[positionInfo[_positionId].underlyingToken0][positionInfo[_positionId].underlyingToken1];
        pairTokenAmounts[positionInfo[_positionId].underlyingToken0][positionInfo[_positionId].underlyingToken1] = PairInfo(tempPairInfo.amount0 - positionInfo[_positionId].underlyingToken0Amount, tempPairInfo.amount1 - positionInfo[_positionId].underlyingToken1Amount);

        // updating the states
        delete ownerNfts[positionInfo[_positionId].index];
        ownerNfts[positionInfo[_positionId].index] = ownerNfts[ownerNfts.lenght - 1];
        positionInfo[ownerNfts[positionInfo[_positionId].index]].index = positionInfo[_positionId].index;
        delete positionInfo[_positionId];

        // withrwaing the the positionId to the msg.sender
        INonfungiblePositionManager(_uni_v3_pos_address).transferFrom( address(this), msg.sender, _positionId);
    }

    function nftIdPrice(uint256 _positionId) external override view isReal(_positionId) returns(uint256 _nftIdPrice){
        return UNI_V3_POSPriceCalculator(IUniswapV3Pool(positionInfo[_positionId].poolAddress), positionInfo[_positionId].underlyingToken0Amount, positionInfo[_positionId].underlyingToken1Amount);
    }   
    function wUNI_V3_POSPrice(IUniswapV3Pool _pool) external override view returns(uint256 _wUNI_V3_POSPrice){
        return wUNI_V3_POSPriceCalculator(_pool);
    }
    function changeFactory(address _newFactoryAddress) external override onlyOwner{
        require(_newFactoryAddress != address(0),"zero address input")
        factoryAddress = _newFactoryAddress; 
    } 

    function claimRewards(address _sender, uint256 _positionId, address _recipient) internal override isReal(_positionId) returns(address token0, uint256 amount0, address token1, uint256 amount1){
        require(positionInfo[_positionId].owner == _sender,"you don't own this positionId !!");
        (uint256 amount0, uint256 amount1) = PositionValue.fees(positionInfo[_positionId].uni_v3_pos_address, _positionId);
        INonfungiblePositionManager tempINonfungiblePositionManager = INonfungiblePositionManager(positionInfo[_positionId].uni_v3_pos_address);
        tempINonfungiblePositionManager.CollectParams tempCollectParams = (_positionId, _recipient, amount0, amount1);
        (uint256 amount0, uint256 amount1) = tempINonfungiblePositionManager.collect(tempCollectParams);

        return (positionInfo[_positionId].underlyingToken0, amount0, positionInfo[_positionId].underlyingToken1, amount1);
        // return statement shuold be replaced with the event emiting 
    }
    function updatePositionParams(uint256 _positionId) private override isReal(_positionId) returns(bool _isChanged){
        require(msg.sender == address(this, "only callable by the contract itself"));
        // initializing the reterning value
        bool isChanged = false; 
        
        // fetching the position liquidity and updating if there is any difference
        if ( INonfungiblePositionManager(positionInfo[_positionId].uni_v3_pos_address).positions(_positionId).liquidity != positionInfo[_positionId].liquidity){
        uint256 oldPositionLiquidity = positionInfo[_positionId].liquidity
        positionInfo[_positionId].liquidity = INonfungiblePositionManager(positionInfo[_positionId].uni_v3_pos_address).positions(_positionId).liquidity;
        if(!isChanged) isChanged = true;  
        }

        // fetching the tokens amounts and updating if there is any difference
        (uint160 sqrtPriceX96, , , , , , ,) = IUniswapV3Pool(positionInfo[_positionId].poolAddress).slot0();
        (uint256 amount0, uint256 amount1) = PositionValue.principal(positionInfo[_positionId].uni_v3_pos_address, _positionId , sqrtPriceX96);
        if(amount0 != positionInfo[_positionId].underlyingToken0Amount){ 
            positionInfo[_positionId].underlyingToken0Amount = amount0;
         if(!isChanged) isChanged = true;  
        } 
        if(amount1 != positionInfo[_positionId].underlyingToken1Amount){
            positionInfo[_positionId].underlyingToken1Amount = amount1;
            if(!isChanged) isChanged = true;  
        } 
        return isChanged;
    }
    function pairTokenInformation(address _token0, address _token1) external view returns(uint256 amount0, uint256 amount1, uint24 tickLowest, uint24 tickUppermost, uint24 initialLowerTick, uint24 initialUpperTick){
        return (
        pairTokenAmounts[token0][token1].amount0,
        pairTokenAmounts[token0][token1].amount1, 
        pairTokenAmounts[token0][token1].tickLowest,
        pairTokenAmounts[token0][token1].tickUppermost,
        pairTokenTicks[_token0][_token1].initialLowerTick,
        pairTokenTicks[_token0][_token1].initialUpperTick);
    }
    function pairTokenTicks(address _token0, address _token1, uint24 _tickLower, uint24 _tickUpper) external onlyOwner{
        pairTokenTicks[_token0][_token1] = PairTicks(_tickLower, _tickUpper);
    }  
    
}
