pragma solidity >=0.6.0 <0.7.0;

import "./openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./openzeppelin-contracts/contracts/utils/EnumerableSet.sol";

contract Fee {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    
     // rate mul by 1e6   like 1002000; // 1.002 mul 1e6
    uint256 internal interestRate;
    
    struct Deposit {
        uint256 amount;
        uint256 untilBlock;
        uint256 blockCount;
        uint256 feeAmount;
        bool claimed; 
        bool exists;
    }

    struct FeeStruct {
        address feeIdent;
        mapping(address => Deposit) feeMap;
        EnumerableSet.AddressSet feeSet;
        uint256 totalBalance;
        uint256 feeValue;
        
    }
    mapping(address => FeeStruct) private feeList;
    
    event AccuralFee(address indexed addr, uint256 amount);

    /**
     * @param token1 address of token1. used as identificator in mapping
     * @param token2 address of token2(or address(0) for ETH). used as identificator in mapping
     * @param fee1 // 1 means 0.000001% mul 1e6
     * @param fee2 // 1 means 0.000001% mul 1e6
     * @param interest // 1002000 means 1.002% mul 1e6
     */
    constructor(address token1, address token2, uint256 fee1, uint256 fee2, uint256 interest) public {
        
            feeList[token1].feeIdent = token1;
            feeList[token1].totalBalance = 0;
            feeList[token1].feeValue = fee1;    
        
            feeList[token2].feeIdent = token1;
            feeList[token2].totalBalance = 0;
            feeList[token2].feeValue = fee2; 
            
            interestRate = interest;

    }
    
    /**
     * set funds as deposit 
     * @param ident identificator
     * @param amount amount of tokens
     * @param blockCount duration in blocks
     */
    function setFunds(address ident, uint256 amount, uint256 blockCount)  internal {
        
        if (feeList[ident].feeMap[msg.sender].exists == true) {
                require(feeList[ident].feeMap[msg.sender].untilBlock < block.number, string(abi.encodePacked('New deposit will be available after Block #',uint2str(feeList[ident].feeMap[msg.sender].untilBlock))));
                require(feeList[ident].feeMap[msg.sender].claimed == true, 'Previous deposit have not claimed yet');
            }
        

            feeList[ident].feeMap[msg.sender] = 
                Deposit({
                    amount:amount,
                    untilBlock:block.number.add(uint256(blockCount)),
                    blockCount: uint256(blockCount),
                    feeAmount: 0,
                    claimed:false,
                    exists:true
            });
            // accural Fee before adding to deposit lists
            accrualFee(ident, amount);
            
            
            feeList[ident].feeSet.add(msg.sender);
            feeList[ident].totalBalance = feeList[ident].totalBalance.add(amount);
            
            
    }
    
    /**
     * view status of deposit 
     * @param ident identificator
     */
    function viewFunds(address ident) internal view returns(uint256, uint256, bool) {
        
        return (feeList[ident].feeMap[msg.sender].amount,feeList[ident].feeMap[msg.sender].untilBlock, feeList[ident].feeMap[msg.sender].claimed);
    }
    
    /**
     * withdraw current deposit
     * @param ident identificator
     */
    function withdrawFunds(address ident) internal returns(uint256) {
        require(feeList[ident].feeMap[msg.sender].exists == true, 'Deposit does not exist');
        require(feeList[ident].feeMap[msg.sender].claimed == false, 'Deposit have already claimed');
        require(feeList[ident].feeMap[msg.sender].untilBlock < block.number, string(abi.encodePacked('Withdraw will be available at Block #', uint2str(feeList[ident].feeMap[msg.sender].untilBlock))));
        
        feeList[ident].feeMap[msg.sender].claimed = true;
        
        // body
        uint256 amount2send = 0;
        
        // interest calculation
        amount2send = (feeList[ident].feeMap[msg.sender].amount).mul(interest(feeList[ident].feeMap[msg.sender].blockCount)).div(1e6);
        
        // Fees from every deposit transaction
        amount2send = amount2send.add(feeList[ident].feeMap[msg.sender].feeAmount);
        
        return amount2send;
    }
    
    /**
     * Calculated rate amount of deposits
     * @param blockCount Duration in blocks
     */
    function interest(uint256 blockCount) internal returns (uint256) {
        return interestRate;
    }
    
    /**
     * calls at every users donation. accural for every active deposit amount*fee
     * @param ident identificator
     * @param amount amount
     */
    function accrualFee(address ident, uint256 amount) private {
        uint256 len = feeList[ident].feeSet.length();
        address addr;
        for (uint256 i = 0; i < len; i ++) {
            addr = feeList[ident].feeSet.at(i);
            if (feeList[ident].feeMap[addr].claimed == false && feeList[ident].feeMap[addr].exists == true) {
                feeList[ident].feeMap[addr].feeAmount = (feeList[ident].feeMap[addr].feeAmount).add(
                        amount.mul(feeList[ident].feeValue).div(1e6)
                );
                emit AccuralFee(addr,amount.mul(feeList[ident].feeValue).div(1e6));
            }
        }
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}