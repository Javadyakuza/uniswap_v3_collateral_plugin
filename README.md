# uniswapV3CollateralPlugin

this collateral plugin will enable the uniswap v3 pool liquidity providers to use the nonFungiblePositionManager erc-721 tokens to back the reserve protocol stable RTokens and earn even more rewards

---

| tok         | ref         | target | UoA |
| ----------- | ----------- | ------ | --- |
| wUNI_V3_POS | wUNI_V3_POS | USD    | USD |

---

increasinf and decreasing liquidity is basically impossible because its only operatable by the owner of the deposited NFT which is us therefor COLLATERAL methode type is demurrage to calcualte the revenue.

DemurrageRate and t will be initialed in constructor by the deploye.

each collateral plugin is used to support only one pair at the moment and the target pair will be initialed in constructor.

the wrapper contract will take care of the wrapping the NFTs into erc-20 tokens named wUNI_V3_POS.

the wrapper contract will mint an amount of erc-20 in a way that the position liquidity be 110% of it.

the value of the wUNI_V3_POS will be calculated based on the pairs underlyingtokens real time price in USD.

claiming rewards will be handled via the wrapper contract and callable from the collateral contract but with some differences, so basically wwe have not overwritten the traditionl "calimRewards" function because it didnt meet our needs.

statu() of the contract will only be disabled if and only if all of the underlying stableCoins get the value of zero in the real market.

as mentioned before, the price is calculated via "PriceCalculator" and the deployer doesnt need to provide priceFeed eth-address for deployment.

NOTE : this faze of the project is only to do with the stableCoin backed UNI_V3_POS NFT's.
