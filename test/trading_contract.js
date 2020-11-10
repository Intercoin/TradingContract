const BN = require('bn.js'); // https://github.com/indutny/bn.js
const util = require('util');
const TradingContract = artifacts.require("TradingContract");
const TradingContractMock = artifacts.require("TradingContractMock");

const ERC20Mintable = artifacts.require("ERC20Mintable");

const truffleAssert = require('truffle-assertions');

const helper = require("../helpers/truffleTestHelper");

contract('TradingContract', (accounts) => {
    
    // it("should assert true", async function(done) {
    //     await TestExample.deployed();
    //     assert.isTrue(true);
    //     done();
    //   });
    
    // Setup accounts.
    const accountOne = accounts[0];
    const accountTwo = accounts[1];  
    const accountThree = accounts[2];
    const accountFourth= accounts[3];
    const accountFive = accounts[4];
    const accountSix = accounts[5];
    const accountSeven = accounts[6];
    const accountEight = accounts[7];
    const accountNine = accounts[8];
    const accountTen = accounts[9];
    const accountEleven = accounts[10];
    const accountTwelwe = accounts[11];

    
    
    // setup useful values
    const oneEther = 1000000000000000000; // 1eth
    const zeroAddress = "0x0000000000000000000000000000000000000000";
 
    it('should donate', async () => {
        const Token1Instance = await ERC20Mintable.new('t1','t1');
        const TradingContractInstance = await TradingContract.new(
                                                            Token1Instance.address, // address _token1,
                                                            zeroAddress, // address _token2,
                                                            1, //uint256 _numerator,
                                                            1, //uint256 _denominator,
                                                            0, //uint256 _priceFloor,
                                                            1, //uint256 _discount,
                                                            1, //fee1
                                                            1 //fee2
                                                            );
        await Token1Instance.mint(accountOne ,'0x'+(10*oneEther).toString(16), { from: accountOne });
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(3*oneEther).toString(16), { from: accountOne });
        await TradingContractInstance.depositToken1(-1, false, { from: accountOne });
        
    });
 
    it('should deposit and withdraw. accrual fee test', async () => {
        const Token1Instance = await ERC20Mintable.new('t1','t1');
        const TradingContractInstance = await TradingContract.new(
                                                            Token1Instance.address, // address _token1,
                                                            zeroAddress, // address _token2,
                                                            1, //uint256 _numerator,
                                                            10000, //uint256 _denominator,
                                                            '0x'+(1*oneEther).toString(16), //uint256 _priceFloor,
                                                            990000, //uint256 _discount
                                                            1, //fee1
                                                            1 //fee2
                                                            );
        await Token1Instance.mint(accountOne ,'0x'+(10*oneEther).toString(16), { from: accountOne });
        await Token1Instance.mint(accountThree ,'0x'+(10*oneEther).toString(16), { from: accountOne });
        await Token1Instance.mint(accountFourth ,'0x'+(10*oneEther).toString(16), { from: accountOne });
     
        //donate
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(3*oneEther).toString(16), { from: accountOne });
        await TradingContractInstance.depositToken1(-1, false, { from: accountOne });
  
        const accountThreeStartingBalance = (await Token1Instance.balanceOf(accountThree));
        const accountFourthStartingBalance = (await Token1Instance.balanceOf(accountFourth));
        
        //deposit for period 20 blocks, DirectToAccount = false
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(10*oneEther).toString(16), { from: accountThree });
        await TradingContractInstance.depositToken1(20, false, { from: accountThree });
  
        //deposit for period 20 blocks, DirectToAccount = true
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(5*oneEther).toString(16), { from: accountFourth });
        await TradingContractInstance.depositToken1(20, true, { from: accountFourth });
  
        // await Token1Instance.approve(TradingContractInstance.address,'0x'+(5*oneEther).toString(16), { from: accountFourth });
        // await truffleAssert.reverts(
        //     TradingContractInstance.depositToken1(20, false, { from: accountFourth }),
        //     "New deposit will be available after Block #39"
        // );
        
        // pass 30 seconds.   to voting period
        
        await helper.advanceTime(30);
        
        var depositId;
        
        await TradingContractInstance.getPastEvents('DepositCreated', {
            filter: {addr: accountThree}, // Using an array in param means OR: e.g. 20 or 23
            fromBlock: 0,
            toBlock: 'latest'
        }, function(error, events){ /* console.log(events);*/ })
        .then(function(events){
            depositId = events[0].returnValues['depositID'];
        });
        
        const accountFourthEndingBalanceWithoutFee = (await Token1Instance.balanceOf(accountFourth));

        await TradingContractInstance.withdrawToken1(true, depositId, { from: accountThree });

        const accountThreeEndingBalance = (await Token1Instance.balanceOf(accountThree));
        const accountFourthEndingBalance = (await Token1Instance.balanceOf(accountFourth));
        
        let feeForWithdraw = 10*oneEther*0.000001;
        
        assert.equal(
            (
                new BN((parseInt(accountThreeStartingBalance-feeForWithdraw)).toString(16),16)
            ).toString(16),
            (
                new BN((parseInt(accountThreeEndingBalance)).toString(16),16)
            ).toString(16),
            "balance after withdraw not equal"
            );
            
            //let feeForOtherPeopleDeposits = 10*oneEther*0.000001*5/18;
            
 
        let feeForOtherPeopleDeposits = 
            new BN((10*oneEther).toString(16), 16).
            mul(new BN(1, 10)).
            div(new BN(1000000, 10)).
            mul(new BN(5, 10)). // deposit recipient
            div(new BN(5, 10)); // total deposit without sender

        assert.equal(
            (
                new BN((accountFourthEndingBalance).toString(16),16)
            ).toString(16),
            (
                
                new BN(((new BN((accountFourthEndingBalanceWithoutFee).toString(16),16)).add(new BN(feeForOtherPeopleDeposits, 10))).toString(16),16)
            ).toString(16),
            "wrong Fee accrual"
            );

    });
    
    /*
    myContract.getPastEvents('MyEvent', {
    filter: {myIndexedParam: [20,23], myOtherIndexedParam: '0x123456789...'}, // Using an array means OR: e.g. 20 or 23
    fromBlock: 0,
    toBlock: 'latest'
}, function(error, events){ console.log(events); })
.then(function(events){
    console.log(events) // same results as the optional callback above
});
    */
    /*
    it('should exchange', async () => {
        const Token1Instance = await ERC20Mintable.new('t1','t1');
        const TradingContractInstance = await TradingContract.new(
                                                            Token1Instance.address, // address _token1,
                                                            zeroAddress, // address _token2,
                                                            1, //uint256 _numerator,
                                                            10000, //uint256 _denominator,
                                                            '0x'+(1*oneEther).toString(16), //uint256 _priceFloor,
                                                            990000, //uint256 _discount
                                                            1, //fee1
                                                            1, //fee2
                                                            100200 //interestRate
                                                            );
        // make donate tokens by admin )
        await Token1Instance.mint(TradingContractInstance.address ,'0x'+(10000*oneEther).toString(16), { from: accountOne });

        const accountThreeStartingBalance = (await Token1Instance.balanceOf(accountThree));
         // send 10 eth to contract 
         const amountETHSendToContract = 10*10**18; // 10ETH
         await TradingContractInstance.depositToken2(0, { from: accountThree, to: TradingContractInstance.address, value: '0x'+(10*oneEther).toString(16) });                                                        
         
        const accountThreeEndingBalance = (await Token1Instance.balanceOf(accountThree)); 
        
        // approve to contract 
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(accountThreeEndingBalance).toString(16), { from: accountThree });     
        // make exchange 
        await TradingContractInstance.depositToken1(0, { from: accountThree });
    });
    */
   
  
});
