pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./openzeppelin-contracts/contracts/access/Ownable.sol";
import "./openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./openzeppelin-contracts/contracts/utils/Address.sol";
import "./Rates.sol";

contract TradingContract is Ownable, Rates {
    
    using SafeMath for uint256;
    using Address for address;
    
    uint256 public maxGasPrice = 1 * 10**18; // Adjustable value
    uint256 public interestRate = 1002000; // 1.002 mul 1e6

    address public token1;
    address public token2; // can be address(0) = 0x0000000000000000000000000000000000000000
    
    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice, "Transaction gas price cannot exceed maximum gas price.");
        _;
    }

    modifier isToken() {
        require(address(msg.sender).isContract());
        require(address(msg.sender) == address(token1) || address(msg.sender) == address(token2));
        _;
    }
    
    function setMaxGasPrice(uint256 gasPrice) public onlyOwner {
        maxGasPrice = gasPrice;
    }
    
    constructor(
        address _token1, 
        address _token2,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _priceFloor,
        uint256 _discount
        ) Rates(_numerator,_denominator,_priceFloor,_discount) public payable 
    {
        token1 = _token1;
        token2 = _token2;
    }
    struct Deposit {
        uint256 amount;
        uint256 untilBlock;
        uint256 blockCount;
        bool claimed;
        bool exists;
    }

    mapping(address => Deposit) private token1Deposits;

    mapping(address => Deposit) private token2Deposits;
    
    /**
     * @param blockCount Duration in blocks
     * if less than 0 - then it's Donation
     * if equal 0 - then it's immediately exchange to another token
     * if more than 0 - then it's Deposit for `blockCount` period 
     */
    function depositToken1(int256 blockCount) validGasPrice public {
        
        uint256 _allowedAmount = IERC20(token1).allowance(msg.sender, address(this));
        require(_allowedAmount>0, 'Amount exceeds allowed balance');

        // try to get
        bool success = IERC20(token1).transferFrom(msg.sender, address(this), _allowedAmount);
        require(success == true, 'Transfer tokens were failed');
        
        if (blockCount < 0) {
            // Donation
        } else if (blockCount == 0) {
            _receivedToken1(msg.sender, _allowedAmount);
        } else if (blockCount > 0) {
            // Deposit
            
            if (token1Deposits[msg.sender].exists == true) {
                require(token1Deposits[msg.sender].untilBlock < block.number, string(abi.encodePacked('New deposit will be available after Block #',uint2str(token1Deposits[msg.sender].untilBlock))));
                require(token1Deposits[msg.sender].claimed == true, 'Previous deposit have not claimed yet');
            }
        
            token1Deposits[msg.sender] = 
                Deposit({
                    amount:_allowedAmount,
                    untilBlock:block.number.add(uint256(blockCount)),
                    blockCount: uint256(blockCount),
                    claimed:false,
                    exists:true
                });
        }
    }
    
    /**
     * @param blockCount Duration in blocks
     * if less than 0 - then it's Donation
     * if equal 0 - then it's immediately exchange to another token
     * if more than 0 - then it's Deposit for `blockCount` period 
     */
    function depositToken2(int256 blockCount) payable validGasPrice public {
        uint256 _allowedAmount;
        bool success;
        if (token2 == address(0)) {
            _allowedAmount = msg.value;
            require(_allowedAmount>0, 'Amount exceeds allowed balance');
        } else {
            _allowedAmount = IERC20(token2).allowance(msg.sender, address(this));
            require(_allowedAmount>0, 'Amount exceeds allowed balance');
            // try to get
            success = IERC20(token2).transferFrom(msg.sender, address(this), _allowedAmount);
            require(success == true, 'Transfer tokens were failed');     
        }
        
        if (blockCount < 0) {
            // Donation
        } else if (blockCount == 0) {
            _receivedToken2(msg.sender, _allowedAmount);
        } else if (blockCount > 0) {
            // Deposit
            
            if (token1Deposits[msg.sender].exists == true) {
                require(token2Deposits[msg.sender].untilBlock < block.number, string(abi.encodePacked('New deposit will be available after Block #',uint2str(token2Deposits[msg.sender].untilBlock))));
                require(token2Deposits[msg.sender].claimed == true, 'Previous deposit have not claimed yet');
            }
        
            token2Deposits[msg.sender] = 
                Deposit({
                    amount:_allowedAmount,
                    untilBlock:block.number.add(uint256(blockCount)),
                    blockCount: uint256(blockCount),
                    claimed:false,
                    exists:true
                });
        }
    }
    
    /**
     * @return Deposit info of Token1 
     * array of (deposit's amount, untilBlock, claimed status) 
     */
    function viewDepositsToken1() public view returns(uint256, uint256, bool){
        return (token1Deposits[msg.sender].amount,token1Deposits[msg.sender].untilBlock, token1Deposits[msg.sender].claimed);
    }
    
    /**
     * @return Deposit info of Token2 
     * array of (deposit's amount, untilBlock, claimed status) 
     */
    function viewDepositsToken2() public view returns(uint256, uint256, bool){
        return (token2Deposits[msg.sender].amount,token2Deposits[msg.sender].untilBlock, token2Deposits[msg.sender].claimed);
    }
    
    /**
     * Withdraw deposited tokens1
     */
    function withdrawToken1() validGasPrice public {
        
        require(token1Deposits[msg.sender].exists == true, 'Deposit does not exist');
        require(token1Deposits[msg.sender].claimed == false, 'Deposit have already claimed');
        require(token1Deposits[msg.sender].untilBlock < block.number, string(abi.encodePacked('Withdraw will be available at Block #', uint2str(token1Deposits[msg.sender].untilBlock))));
        
        token1Deposits[msg.sender].claimed = true;
        
        
        uint256 _amount2send = token1Deposits[msg.sender].amount.mul(interest(token1Deposits[msg.sender].blockCount)).div(1e6);
        uint256 _balanceToken1 = IERC20(token1).balanceOf(address(this));
        require (_amount2send <= _balanceToken1 && _balanceToken1>0, "Amount exceeds available balance.");
        bool success = IERC20(token1).transfer(msg.sender,_amount2send);
        require(success == true, 'Transfer tokens were failed'); 
        
    }
    
    /**
     * Withdraw deposited tokens2
     */
    function withdrawToken2() validGasPrice public {
        
        require(token2Deposits[msg.sender].exists == true, 'Deposit does not exist');
        require(token2Deposits[msg.sender].claimed == false, 'Deposit have already claimed');
        require(token2Deposits[msg.sender].untilBlock < block.number, string(abi.encodePacked('Withdraw will be available at Block #',uint2str(token2Deposits[msg.sender].untilBlock))));
        
        token2Deposits[msg.sender].claimed = true;
        
        uint256 _balanceToken2;
        if (address(0) == address(token2)) {  // ETH
            _balanceToken2 = address(this).balance;
        } else { // Token2
            _balanceToken2 = IERC20(token2).balanceOf(address(this));    
        }
        
        uint256 _amount2send = token2Deposits[msg.sender].amount.mul(interest(token1Deposits[msg.sender].blockCount)).div(1e6);
        require ((_amount2send <= _balanceToken2 && _balanceToken2>0), "Amount exceeds available balance.");
        bool success;
        if (address(0) == address(token2)) {
            address payable addr1 = payable(msg.sender); // correct since Solidity >= 0.6.0
            success = addr1.send(_amount2send);
            require(success == true, 'Transfer ether was failed'); 
        } else {
            success = IERC20(token2).transfer(msg.sender,_amount2send);
            require(success == true, 'Transfer tokens were failed');     
        }
    }
    
    // recieve ether and transfer token1 to sender
    receive() external payable validGasPrice {
        require (token2 == address(0), "This method is not supported");
        _receivedToken2(msg.sender, msg.value);
    }
    
    /**
     * Calculated rate amount of deposits
     * @param blockCount Duration in blocks
     */
    function interest(uint256 blockCount) internal returns (uint256) {
        return interestRate;
    }
    
    /**
     * method ganerated random Int. will be used as ID for multiple deposits
     */
    function rndID() internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            now, 
            block.difficulty, 
            msg.sender
        )));    
    }
    
    /**
     * 
     */
    function _receive(uint256 msg_value) private {
        require (token2 == address(0), "This method is not supported"); 
        
        uint256 _balanceToken1 = IERC20(token1).balanceOf(address(this));
        uint256 _balanceToken2 = address(this).balance;
        // _balanceToken1, address(this).balance, msg.value

        uint256 _amount2send = buyExchangeAmount(msg_value,_balanceToken1, _balanceToken2);
        
        require (_amount2send <= _balanceToken1 && _balanceToken1>0 && _amount2send>0, "Amount exceeds available balance.");
        
        bool success = IERC20(token1).transfer(
            msg.sender,
            _amount2send
        );
        require(success == true, 'Transfer tokens were failed');
    }
    
    /**
     * 
     */
    function _receivedToken1(address _from, uint256 token1Amount) private {
        uint256 _balanceToken1 = IERC20(token1).balanceOf(address(this));
        uint256 _balanceToken2;
        if (address(0) == address(token2)) {  // ETH
            _balanceToken2 = address(this).balance;
        } else { // Token2
            _balanceToken2 = IERC20(token2).balanceOf(address(this));    
        }
      
        uint256 _amount2send = sellExchangeAmount(token1Amount, _balanceToken1, _balanceToken2);
        
        require ((_amount2send <= _balanceToken2 && _balanceToken2>0), "Amount exceeds available balance.");
        
        bool success;
        if (address(0) == address(token2)) {
            address payable addr1 = payable(_from); // correct since Solidity >= 0.6.0
            success = addr1.send(_amount2send);
            require(success == true, 'Transfer ether was failed'); 
        } else {
            success = IERC20(token2).transfer(_from,_amount2send);
            require(success == true, 'Transfer tokens were failed');     
        }
            
    }
    
    /**
     * 
     */
    function _receivedToken2(address _from, uint256 token2Amount) private {
        
        uint256 _balanceToken1 = IERC20(token1).balanceOf(address(this));
        uint256 _balanceToken2;
        if (address(0) == address(token2)) {  // ETH
            _balanceToken2 = address(this).balance;
        } else { // Token2
            _balanceToken2 = IERC20(token2).balanceOf(address(this));    
        }
        
        uint256 _amount2send = buyExchangeAmount(token2Amount, _balanceToken1, _balanceToken2);
        
        require (_amount2send <= _balanceToken1 && _balanceToken1>0, "Amount exceeds available balance.");
        
        bool success = IERC20(token1).transfer(_from,_amount2send);
        require(success == true, 'Transfer tokens were failed'); 
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

