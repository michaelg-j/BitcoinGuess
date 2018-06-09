/*
   
*/

pragma solidity ^0.4.0;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract BitcoinGuess is usingOraclize {
    
    
    
    uint startTime = 1528041600;
    uint testTime  = 1528214400; 
  
    mapping(uint => uint)                       public bitcoinPrices;
    mapping(uint => mapping(address => uint))   public userSends;
    mapping(uint => mapping(address => uint))   public userGuesses;
    mapping(uint => mapping(uint => address[])) public samePricePeoples;
    mapping(uint => uint)                       public dailyTotal;
    
    event LogUserSends(uint day,address sender,uint value);
    event LogOraclizeQuery(string description);
    event LogUpdatPrice(uint result);
    event LogResult(uint day, uint successCount, address sender);
    event LogDayFor(uint day);

    

    function BitcoinGuess() {
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
      
        
    }
    
    function guessWithEth(uint guessPrice,uint day) payable public{
        assert(time() >= startTime);
        assert(msg.value == 0.003 ether);
        assert(userSends[day][msg.sender] == 0);
       
        
        userSends[day][msg.sender] += msg.value;
        userGuesses[day][msg.sender] = guessPrice;
        samePricePeoples[day][guessPrice].push(msg.sender);
        
        if(dailyTotal[day]==0){
            update(timeToQuery(day));
        }
        dailyTotal[day] += msg.value;
        
        
        LogUserSends(day, msg.sender, msg.value);
    }
    
     function guess(uint guessPrice) payable public{
       guessWithEth(guessPrice, today());
    }
    
     function result (uint day) public{
        assert(day >= 0);
        assert(time() > timeToResult(day));
        assert(dailyTotal[day] > 0);
        assert(userSends[day][msg.sender] > 0);
        
        uint successCount = samePricePeoples[day][bitcoinPrices[day]].length;
        if(successCount > 0){
            //somebody success
            uint reward = dailyTotal[today()-1]/successCount;
            if(userGuesses[day][msg.sender]==bitcoinPrices[day]){
                msg.sender.transfer(reward);
            }
            
            
        }else{
            //nobody success
            dailyTotal[today()] += dailyTotal[day];
            dailyTotal[day] = 0;
        }
        LogResult(day,successCount,msg.sender);
        
    }
    
    function today() constant returns (uint) {
        return dayFor(time());
    }
    
    function time() constant returns (uint){
        return block.timestamp;
    }
    
    function dayFor(uint timestamp) constant returns (uint){
        uint dayFor = (timestamp - startTime) / 24 hours;
        LogDayFor(dayFor);
        return dayFor;
    }
    
    function timeToQuery(uint day) returns (uint){
        return startTime + (day + 1) * 24 hours + 20 hours;
    }
    
    function timeToResult(uint day) returns (uint){
        return startTime + (day + 1) * 24 hours + 21 hours;
    }

    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != oraclize_cbAddress()) throw;
  
        bitcoinPrices[today()-1] = parseInt(result); 
        
        LogUpdatPrice(bitcoinPrices[today()-1]);
        
   
    }
    
    function update(uint timestamp) payable {
        if (oraclize.getPrice("URL") > this.balance) {
            LogOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            LogOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(timestamp,"URL", "json(https://api.coinmarketcap.com/v2/ticker/1/).data.quotes.USD.price");
        }
    }
    
} 