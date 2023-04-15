// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.6.8 <=0.8.18;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "./IwUNI_V3_POS.sol";
import "./WUNI_V3_POS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionValue.sol";
import "./libraries/PriceCalculator.sol";
import "./libraries/LiquidityAmountCalculator.sol";

/// @title wUNI-V3_POS wrapper contract

contract UNI_V3_POS_Wrapper is Ownable {
    // amount0 and amount1 are the whoel received underlyingtoken amounts of a specific UNI_NFT of pair
    /// @notice tickUppermost and tickLowest are used to calculate the whole liquidity for thr _underlyingRefpereTok uint amount.
    struct PairInfo {
        uint256 amount0;
        uint256 amount1;
        int24 tickUppermost; // uppermost tick in all of the positions
        int24 tickLowest; // lowest tick in all of the positions
    }

    struct PairTicks {
        int24 initialLowerTick; // will be used to calculate the wUNI_V3_POS minting amount in temrs of overcollateralaziation (constructor intialing)
        int24 initialUpperTick; // will be used to calculate the wUNI_V3_POS minting amount in temrs of overcollateralaziation (constructor intialing)
    }

    struct PositionParams {
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

    mapping(address => uint256[]) public ownerNfts;
    mapping(uint256 => PositionParams) public positionInfo;
    mapping(uint8 => address) public indexPerToken;
    /// @notice the ordering of the token0 and token1 will be setted based on the pool token ordering.
    mapping(address => mapping(address => IwUNI_V3_POS)) public erc20Perpair; // address(USDC) / address(USDT) = specific_erc20_token.
    mapping(address => mapping(address => PairInfo)) public pairTokenAmounts;
    mapping(address => mapping(address => PairTicks)) public pairTokenTicks; // will return the the intialing ticks

    modifier isReal(uint256 _positionId) {
        require(
            positionInfo[_positionId].owner == address(0),
            "position id doesn't exist's !!"
        );
        _;
    }

    function deposit(
        uint256 _positionId,
        address _poolAddress,
        address _uni_v3_pos_address
    ) external returns (uint256 mintedwUNI_V3_POSAmount) {
        // depositing the nft to the collateral address
        INonfungiblePositionManager tempINonfungiblePositionManager = INonfungiblePositionManager(
                _uni_v3_pos_address
            );
        tempINonfungiblePositionManager.transferFrom(
            msg.sender,
            address(this),
            _positionId
        );

        // fetching the principal amount of the tokens
        IUniswapV3Pool tempIUniswapV3Pool = IUniswapV3Pool(_poolAddress);
        (uint160 sqrtPriceX96, , , , , , ) = tempIUniswapV3Pool.slot0();
        (uint256 amount0, uint256 amount1) = PositionValue.principal(
            tempINonfungiblePositionManager,
            _positionId,
            sqrtPriceX96
        );

        // conevrting the tokens decimals incase if they are not "18" to "18".
        if ((18 - ERC20(tempIUniswapV3Pool.token0()).decimals()) != 0) {
            amount0 =
                amount0 *
                (10 ** (18 - ERC20(tempIUniswapV3Pool.token0()).decimals()));
        }
        if ((18 - ERC20(tempIUniswapV3Pool.token1()).decimals()) != 0) {
            amount1 =
                amount1 *
                (10 ** (18 - ERC20(tempIUniswapV3Pool.token1()).decimals()));
        }

        // updating PairInfo and generatinig the mint amount
        PairInfo memory tempPairInfo = pairTokenAmounts[
            tempIUniswapV3Pool.token0()
        ][tempIUniswapV3Pool.token1()];
        PairTicks memory temoPairTicks = pairTokenTicks[
            tempIUniswapV3Pool.token0()
        ][tempIUniswapV3Pool.token1()];
        uint256 mintAmountRaw = calculateAmounts.getWholeAmountsLiquidity(
            amount0,
            amount1,
            int24(temoPairTicks.initialLowerTick),
            int24(temoPairTicks.initialUpperTick),
            tempIUniswapV3Pool
        );
        uint256 mintAmount = mintAmountRaw - (mintAmountRaw / 10);
        // @param TL = tickLoer, TU = tickUpper

        (
            ,
            ,
            ,
            ,
            ,
            int24 TL,
            int24 TU,
            uint128 liquidity,
            ,
            ,
            ,

        ) = tempINonfungiblePositionManager.positions(_positionId);

        if (tempPairInfo.tickUppermost > TU) TU = tempPairInfo.tickUppermost;
        if (tempPairInfo.tickLowest > TL) TU = tempPairInfo.tickLowest;
        pairTokenAmounts[tempIUniswapV3Pool.token0()][
            tempIUniswapV3Pool.token1()
        ] = PairInfo(
            amount0 + tempPairInfo.amount0,
            amount1 + tempPairInfo.amount1,
            TL,
            TU
        );

        // adding the information to the "ownerNfts" and "positionInfo" mappings
        ownerNfts[msg.sender].push(_positionId);
        positionInfo[_positionId] = PositionParams(
            msg.sender,
            _poolAddress,
            _uni_v3_pos_address,
            _positionId,
            ownerNfts[msg.sender].length - 1,
            tempIUniswapV3Pool.token0(),
            tempIUniswapV3Pool.token1(),
            amount0,
            amount1,
            liquidity
        );

        // minting the amount0 + amount1 to the depositor
        erc20Perpair[tempIUniswapV3Pool.token0()][tempIUniswapV3Pool.token1()]
            .mint(msg.sender, mintAmount);
        return (mintAmount);
    }

    function withdraw(uint256 _positionId) external isReal(_positionId) {
        updatePositionParams(_positionId);

        require(
            positionInfo[_positionId].owner == msg.sender,
            "you don't own this positionId !!"
        );

        // burning the whole owned amount of the WUNI_V3_POS that user has
        // the allowance will be called directly from the wUNI_v3_POS contract
        IwUNI_V3_POS tempIwUNI_V3_POS = erc20Perpair[
            positionInfo[_positionId].underlyingToken0
        ][positionInfo[_positionId].underlyingToken0];
        tempIwUNI_V3_POS._burnFrom(
            msg.sender,
            tempIwUNI_V3_POS._balanceOf(msg.sender)
        );

        // decreasing the paitTokenAmounts
        PairInfo memory tempPairInfo = pairTokenAmounts[
            positionInfo[_positionId].underlyingToken0
        ][positionInfo[_positionId].underlyingToken1];
        pairTokenAmounts[positionInfo[_positionId].underlyingToken0][
            positionInfo[_positionId].underlyingToken1
        ] = PairInfo(
            tempPairInfo.amount0 -
                positionInfo[_positionId].underlyingToken0Amount,
            tempPairInfo.amount1 -
                positionInfo[_positionId].underlyingToken1Amount,
            pairTokenAmounts[positionInfo[_positionId].underlyingToken0][
                positionInfo[_positionId].underlyingToken1
            ].tickUppermost,
            pairTokenAmounts[positionInfo[_positionId].underlyingToken0][
                positionInfo[_positionId].underlyingToken1
            ].tickLowest
        );

        // updating the states
        delete ownerNfts[positionInfo[_positionId].owner][
            positionInfo[_positionId].index
        ];
        ownerNfts[positionInfo[_positionId].owner][
            positionInfo[_positionId].index
        ] = ownerNfts[positionInfo[_positionId].owner].length - 1;
        ownerNfts[positionInfo[_positionId].owner].pop();
        positionInfo[
            ownerNfts[positionInfo[_positionId].owner][
                positionInfo[_positionId].index
            ]
        ].index = positionInfo[_positionId].index;
        delete positionInfo[_positionId];

        // withrwaing the the positionId to the msg.sender
        INonfungiblePositionManager(
            positionInfo[_positionId].uni_v3_pos_address
        ).transferFrom(address(this), msg.sender, _positionId);
    }

    function nftIdPrice(
        uint256 _positionId
    ) external view isReal(_positionId) returns (uint256 _nftIdPrice) {
        return
            PriceCalculator.UNI_V3_POSPriceCalculator(
                IUniswapV3Pool(positionInfo[_positionId].poolAddress),
                positionInfo[_positionId].underlyingToken0Amount,
                positionInfo[_positionId].underlyingToken1Amount
            );
    }

    function wUNI_V3_POSPrice(
        IUniswapV3Pool _pool
    )
        external
        view
        returns (uint192 _wUNI_V3_POSPrice, uint192 _whole_wUNI_V3_POSPrice)
    {
        return PriceCalculator.wUNI_V3_POSPriceCalculator(_pool);
    }

    function claimRewards(
        address _sender,
        uint256 _positionId,
        address _recipient
    )
        internal
        isReal(_positionId)
        returns (
            address token0,
            uint256 _amount0Collected,
            address token1,
            uint256 _amount1Collected
        )
    {
        require(
            positionInfo[_positionId].owner == _sender ||
                positionInfo[_positionId].owner == msg.sender,
            "you don't own this positionId !!"
        );
        require(_recipient != address(0), "zero-address recipient");
        INonfungiblePositionManager tempINonfungiblePositionManager = INonfungiblePositionManager(
                positionInfo[_positionId].uni_v3_pos_address
            );
        (uint256 amount0, uint256 amount1) = PositionValue.fees(
            tempINonfungiblePositionManager,
            _positionId
        );
        (
            uint256 amount0Collected,
            uint256 amount1Collected
        ) = tempINonfungiblePositionManager.collect(
                INonfungiblePositionManager.CollectParams(
                    _positionId,
                    _recipient,
                    uint128(amount0),
                    uint128(amount1)
                )
            );
        return (
            positionInfo[_positionId].underlyingToken0,
            amount0Collected,
            positionInfo[_positionId].underlyingToken1,
            amount1Collected
        );
    }

    function updatePositionParams(
        uint256 _positionId
    ) private isReal(_positionId) returns (bool _isChanged) {
        // initializing the reterning value
        bool isChanged = false;

        // fetching the position liquidity and updating if there is any difference
        INonfungiblePositionManager tempINonfungiblePositionManager = INonfungiblePositionManager(
                positionInfo[_positionId].uni_v3_pos_address
            );
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = tempINonfungiblePositionManager.positions(_positionId);
        if (liquidity != positionInfo[_positionId].positionLiquidity) {
            uint256 oldPositionLiquidity = positionInfo[_positionId]
                .positionLiquidity;
            positionInfo[_positionId].positionLiquidity = liquidity;
            if (!isChanged) isChanged = true;
        }

        // fetching the tokens amounts and updating if there is any difference
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(
            positionInfo[_positionId].poolAddress
        ).slot0();
        (uint256 amount0, uint256 amount1) = PositionValue.principal(
            tempINonfungiblePositionManager,
            _positionId,
            sqrtPriceX96
        );
        if (amount0 != positionInfo[_positionId].underlyingToken0Amount) {
            positionInfo[_positionId].underlyingToken0Amount = amount0;
            if (!isChanged) isChanged = true;
        }
        if (amount1 != positionInfo[_positionId].underlyingToken1Amount) {
            positionInfo[_positionId].underlyingToken1Amount = amount1;
            if (!isChanged) isChanged = true;
        }
        return isChanged;
    }

    function pairTokenInformation(
        address _token0,
        address _token1
    )
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            int24 tickLowest,
            int24 tickUppermost,
            int24 initialLowerTick,
            int24 initialUpperTick
        )
    {
        return (
            pairTokenAmounts[_token0][_token1].amount0,
            pairTokenAmounts[_token0][_token1].amount1,
            pairTokenAmounts[_token0][_token1].tickLowest,
            pairTokenAmounts[_token0][_token1].tickUppermost,
            pairTokenTicks[_token0][_token1].initialLowerTick,
            pairTokenTicks[_token0][_token1].initialUpperTick
        );
    }

    function setPairTokenTicks(
        address _token0,
        address _token1,
        int24 _tickLower,
        int24 _tickUpper
    ) external onlyOwner {
        require(
            _token0 != address(0) && _token1 != address(0),
            "zerp-address token address"
        );
        pairTokenTicks[_token0][_token1] = PairTicks(_tickLower, _tickUpper);
    }
}
