# Liquidor

Liquidity for everyone.

## Idea

Usual protocols generate liquidity only when user interact with this protoclol. That means when users are not interactiong with protocol liquidity is not generated. What we can do with that? If some user deposited liquidity we can generate yield for it while our protocol is not functining for 100%. In our case Liquidor is lending platfor which allows lender to lend tokens and borrowers can borrow them for some other collateral. Nothing special, but wait. To not wait for borrowers to appear this liquidity is redeposited into AAVE. Only when borrower for specific token appears we withdraw necessary amount of tokens from AAVE to borrower and borrower tokens is deposited to aave. in other words we give user 100% of token for 120% of token, and this 20% generatete protocol even more profit (20% because protocol for deposit allows 80% LTV which would be explained later). Everyone are happy:
- borrower can borrow tokens which they want
- lender earn passive incom and earn even more when borrower appears
- protocol 

## But what can we do better?

Why do we need to wait apr to generate yield to increase borrower health. Why can we not just add user additional health when we know that some token that user deposit (in our case collateral token) will generate enough tokens to cover debt but in future? We can. But it's not that easy. In best case we can add additional 1% for health because it's very hard for collateral to gain even 1% (or more) in month. Also what is collateral doen't generate enough yield before borrow ends? That's the problem. Because that you must dissalow for user to borrow tokens (with APR feature directly in health) in case oracle didn't predict future very well. Also because that oracle must provide value a little bit lover that actual predictable APR as safe measurements. 

## Contracts

(from least significant to most)

### PriceOracle

Retrieves TWAP for 1 hour interval which is used in core. It was chosen to calculate price of every token in USDT

### Connector

This contract is a layer between `Core` contract and token transfers. It manage all token transfers, Morpheus, and Uniswap V3 interactions.

### Core

Main beast of all protocol. It manages user deposits in ERC4626 type.