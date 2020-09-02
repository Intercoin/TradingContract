pragma solidity >=0.6.0 <0.7.0;

import "../TradingContract.sol";

contract TradingContractMock is TradingContract {
    
    
    constructor (
        address _token1, 
        address _token2,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _priceFloor,
        uint256 _discount
    ) 
        TradingContract(_token1, _token2, _numerator, _denominator, _priceFloor, _discount) 
        public 
    {
//        _discount = discount;
    }

    
}


