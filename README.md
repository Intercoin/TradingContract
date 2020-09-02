# TradingContract
A smart contract with the ability to trade one token against others, eliminating the need for centralized trust.
# Deploy
when deploy it need to pass parameters in to constructor
name  | type | description
--|--|--
_token1|address| address of first erc20token
_token2|address| address of second erc20token or zero-address (in this case exchange will be erc20token/ETH )
_numerator|uint256| price increment
_denominator|uint256| how much ether to next price
_priceFloor|uint256| price floor
_discount|uint256|  99% * 1e6 (used for calculate sellExchangeRate)

# Methods
once installed will be use methods to exchange
Note that contract accept tokens, it should be approve before (for contract address)
*     function depositToken1(int256 blockCount)
if blockCount < 0 tokens will be donated
if blockCount = 0 tokens will be exchanged to token2
if blockCount > 0 tokens will be deposited and can be withdraw after `blockCount` blocks
*     function depositToken2(int256 blockCount)
if blockCount < 0 tokens will be donated
if blockCount = 0 tokens will be exchanged to token1
if blockCount > 0 tokens will be deposited and can be withdraw after `blockCount` blocks
*     function viewDepositsToken1()
*     function viewDepositsToken2()
*     function withdrawToken1()
*     function withdrawToken2()
# Examples
* how to donate tokens
    * call method approve from erc20 token
    `approve(<address TradingContract>, <amount tokens>)`
    * call method depositToken1 from TradingContract
    `depositToken1(-1)`
* how to exchange tokens from token1 to token2 immediately
    * call method approve from erc20 token
    `approve(<address TradingContract>, <amount tokens>)`
    * call method depositToken1 from TradingContract
    `depositToken1(0)`
* how to deposit tokens to TradingContract i.e for 100 blocks and withdraw
    * call method approve from erc20 token
    `approve(<address TradingContract>, <amount tokens>)`
    * call method depositToken1 from TradingContract
    `depositToken1(100)`
    * call method withdrawToken1 from TradingContract
    `withdrawToken1()`

**Note**
1. `blockCount` it is duration in blocks NOT BLOCK NUMBER
2. eth deposit will be available if 
    1. contract created with token2 = address(0) and 
    2. transaction with method `depositToken2()` are payable 