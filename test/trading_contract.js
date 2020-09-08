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
                                                            1, //uint256 _discount
                                                            );
        await Token1Instance.mint(accountOne ,'0x'+(10*oneEther).toString(16), { from: accountOne });
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(3*oneEther).toString(16), { from: accountOne });
        await TradingContractInstance.depositToken1(-1, { from: accountOne });
        
    });
    
    it('should deposit and withdraw', async () => {
        const Token1Instance = await ERC20Mintable.new('t1','t1');
        const TradingContractInstance = await TradingContract.new(
                                                            Token1Instance.address, // address _token1,
                                                            zeroAddress, // address _token2,
                                                            1, //uint256 _numerator,
                                                            1, //uint256 _denominator,
                                                            0, //uint256 _priceFloor,
                                                            1, //uint256 _discount
                                                            );
        await Token1Instance.mint(accountOne ,'0x'+(10*oneEther).toString(16), { from: accountOne });
        await Token1Instance.mint(accountThree ,'0x'+(10*oneEther).toString(16), { from: accountOne });
        await Token1Instance.mint(accountFourth ,'0x'+(10*oneEther).toString(16), { from: accountOne });
        
        //donate
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(3*oneEther).toString(16), { from: accountOne });
        await TradingContractInstance.depositToken1(-1, { from: accountOne });
        
        const accountThreeStartingBalance = (await Token1Instance.balanceOf(accountThree));
        
        //deposit for period 20 blocks
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(10*oneEther).toString(16), { from: accountThree });
        await TradingContractInstance.depositToken1(20, { from: accountThree });
        
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(5*oneEther).toString(16), { from: accountFourth });
        await TradingContractInstance.depositToken1(20, { from: accountFourth });
        
        await Token1Instance.approve(TradingContractInstance.address,'0x'+(5*oneEther).toString(16), { from: accountFourth });
        await truffleAssert.reverts(
            TradingContractInstance.depositToken1(20, { from: accountFourth }),
            "New deposit will be available after Block #39"
        );
        
        // pass 30 block.   to voting period
        for (let i=0; i<30; i++) {
            await helper.advanceBlock();
        }
        
        await TradingContractInstance.withdrawToken1({ from: accountThree });
        const accountThreeEndingBalance = (await Token1Instance.balanceOf(accountThree));
        
        assert.equal(
            (
                new BN((accountThreeStartingBalance*1.002).toString(16),16)
            ).toString(16),
            (new BN((accountThreeEndingBalance).toString(16),16)).toString(16),
            "balance after withdraw not equal"
            );
    });
    
    it('should exchange', async () => {
        const Token1Instance = await ERC20Mintable.new('t1','t1');
        const TradingContractInstance = await TradingContract.new(
                                                            Token1Instance.address, // address _token1,
                                                            zeroAddress, // address _token2,
                                                            10, //uint256 _numerator,
                                                            300, //uint256 _denominator,
                                                            330, //uint256 _priceFloor,
                                                            99e4, //uint256 _discount
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
    
   
  
});
