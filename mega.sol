pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;


/*

MEGA.sol v0.9 (Gosia's changes on 09/03/2020 9:30pm - added an Oracle)

Contract MEGA is intended to assist with allowance trading within the European Union Emissions Trading Scheme (EU ETS).

*/

pragma solidity ^0.4.6;

//This is the Oracle that allows an admin user to put in the emission values
contract Oracle {

    mapping(address => uint) public emissions_registry; //the registry of emission values
    address private owner; //the only address that can change the entry values
    
    constructor() public {
        owner = msg.sender;
    }
    
    //This is a setter function that allows the owner user to set the emission values
    function set(address _address, uint _x) public returns(bool success) {
        require(msg.sender == owner, 'Only the contract owner can call this function');
        emissions_registry[_address] = _x;
        return true;
    }
}

//This is the interface for the Oracle contract
contract OracleInterface {
    mapping(address => uint) public emissions_registry;
    function set(address _address, uint _x) returns(bool success) {} 
}


//This is the main MEGA contract code
contract MEGA{

    //Global variables and data structures used in the contract
    uint256 total_cap = 10000; //the initial number of total allowance tokens in the contract
    uint total_actors = 20; //the initial number of actors in the contract
    uint public frozenTokens = 0;
    uint usersCount = 0; //number of registered users (OPTIONAL - for test purposes)
    uint auctionCount = 0; //number of currently active auctions (OPTIONAL - for test purposes)
    uint public theBalanceToCheckEther = 0; //balance that is being checked (OPTIONAL - for test purposes)
    uint public mostRecentAuctionCreated = 0;

    uint yearEndTime = 0; //time when the year is over
    uint daysInYear = 0; //Number of days in this year
    uint yearDistribution = 0; //The number of years that have passed. I am going to use this to track whether users are entitled to a distribution
    uint yearTokenDistribution = 0; //The amount of tokens to be distributed this year
    //uint minimumBidIncrease = 0; //This is the minimum amount by which one has to outbid
    address public owner;


    mapping(address => Person) public registered_users; //a mapping with registered users and their corresponding addresses
    mapping(uint => Auction) public active_auctions; //a mapping with all currently active auctions and their corresponding IDs
    mapping(uint => uint) public deposited_tokens;

    uint public theBidAmount = 0; //Tester function to see if the mapping works
    uint public theTokenBalance = 0; //Tester function to see if the token wallets work as they shoiuld


    address addressOracle;

    function MEGA(address OAddress) {
        addressOracle = OAddress;
        owner = msg.sender;
    }


    //Struct defining a person (user) in the contract
    struct Person{
        address personAddress; //attribute for user address
        uint tokensWallet;  //attribute for the current number of tokens owned by the user
        bool isActive; //flag for active user
        uint theYear; //which year has the user taken their distribution of tokens for
    }

    //Function to generate a new user, taking user address and returning Person instantiation
    function createPerson (address _personAddress) private returns (Person memory){
        uint tokenAllocation = total_cap / total_actors; //number of tokens to allocate per person
        return Person({ personAddress: _personAddress, tokensWallet: tokenAllocation, isActive: true, theYear: yearDistribution});
    }

    //Function to register a new user
    function register() public{
        require(registered_users[msg.sender].isActive == false, "You are already registered"); //check if users not registered yet
        require(usersCount < total_actors, "There are no more actors allowed in this system"); //Make sure we have not exceeded the size of the system
            Person memory newUser = createPerson(msg.sender); //generate a new user
            registered_users[msg.sender] = newUser; //add user to registered_users list
            usersCount += 1; //increase user count to keep track of the total registered_users size
    }

    function deregister() public{
        require(registered_users[msg.sender].isActive == true, "You are not registered"); //check if users not registered yet
        registered_users[msg.sender].isActive = false;
    }

    //allows owner of the contract to end the current year (Assuming a year has already passed) and start a new year of a specified length, and with a specified token distribution
    function endTheYear(uint _daysInNextYear, uint _numberOfTokensToDistribute) public {
        require(msg.sender == owner, 'Only the contract owner can call this function'); //Ensures only the contract owner has access to all factors affecting initial token distribution
        require(now > yearEndTime, 'The year has not ended yet');
        daysInYear = _daysInNextYear;
        yearEndTime = now + _daysInNextYear;
        yearTokenDistribution = _numberOfTokensToDistribute;
        yearDistribution += 1;
    }

    function recieveDistribution() public {
        require(registered_users[msg.sender].theYear <= yearDistribution,'You have already recieved your distribution of tokens for this year');
        registered_users[msg.sender].tokensWallet += yearTokenDistribution;
        registered_users[msg.sender].theYear = yearDistribution + 1;

    }

    //Struct defining an auction, I got rid of increment and highestMaxBid
    struct Auction{
        uint auctionID; //unique auction identifier
        uint numTokens; //number of tokens on sale
        uint minPrice; //minimum price per all tokens offered
        address sellerID; //address of the token seller
        bool isActive; //flag for active auction
        uint numBids; //number of current bidders in the auction
        uint highestCurrentBid; //value of the current highest bid
        uint auctionEnd; //The time after which the auction can be ended
        Person highestBidder; //Person instance of the highest bidder

        mapping(address => uint) bidders; //mapping with amount of money paid to bid

    }

    //Function to place tokens on auction
    function sellTokens(uint _amount, uint _minPrice, uint _biddingTime) public {
        require(_amount != 0, "Cannot sell empty auction.");//require the auction not to be empty
        require(registered_users[msg.sender].isActive == true, "You need to register as a user in order to sell"); //check if users is registered
        require(registered_users[msg.sender].tokensWallet >= _amount, "You do not have enough tokens for this auction"); //Require that the user has the amount of tokens that they are trying to sell
        auctionCount += 1;
        mostRecentAuctionCreated = auctionCount;
        //Instantiating a new auction with specified amount and minimum price
        Auction memory newAuction = Auction({
                                            auctionID: auctionCount,
                                            numTokens: _amount,
                                            minPrice: _minPrice * 1 ether, //* 1000000000000000000,
                                            sellerID: msg.sender,
                                            isActive: true,
                                            numBids: 0,
                                            highestCurrentBid: 0,
                                            auctionEnd: now + _biddingTime, // * 1 hours,
                                            highestBidder: Person(0x0000000000000000000000000000000000000000, 0, false, 0)
        });

        active_auctions[auctionCount] = newAuction; //adding auction to the mapping of currently active functions


        frozenTokens += _amount;
        registered_users[msg.sender].tokensWallet -= _amount;
        deposited_tokens[auctionCount] = _amount;
    }


    //Function to place a bid on the auction
    function buyTokens(uint _auctionID) public payable {

        require(_auctionID <= auctionCount, "This is not an auction that has been created"); //check if user has put in the number for an auction that exists
        require(now <= active_auctions[_auctionID].auctionEnd, 'The ending time for this auction has been reached');//require that the end time for the auction has not already happened
        require(active_auctions[_auctionID].isActive, 'This auction is not active');//requrie that the auction is active
        require(msg.value + active_auctions[_auctionID].bidders[msg.sender] > active_auctions[_auctionID].highestCurrentBid, "You cannot bid less than or equal to the current highest bid."); //require the amount that the buyer is offering is greater than the current highest bid.
        require(msg.value + active_auctions[_auctionID].bidders[msg.sender] >= active_auctions[_auctionID].minPrice, "The seller is not willing to sell at this price"); //require the bidder to bid at least the minPrice
        require(registered_users[msg.sender].isActive == true, "You need to register as a user in order to bid"); //check if users not registered yet


        //CONDITION IF BIDDING FOR THE FIRST TIME
        active_auctions[_auctionID].highestCurrentBid = active_auctions[_auctionID].bidders[msg.sender] + msg.value;
        active_auctions[_auctionID].highestBidder = registered_users[msg.sender];
        active_auctions[_auctionID].numBids += 1;
        // depositFunds(_auctionID, msg.sender);
        active_auctions[_auctionID].bidders[msg.sender] = active_auctions[_auctionID].bidders[msg.sender] + msg.value;



    }


    //This function can be called by anyone once the time for the funciton is over
    function endAuction(uint _auctionID) public{
        require(now > active_auctions[_auctionID].auctionEnd, 'The ending time for this auction has not yet been reached');//require that the end time for the auction has already happened
        active_auctions[_auctionID].isActive = false;
        //send back ether to all non-winning bidders
        //registered_users[active_auctions[_auctionID].highestBidder.personAddress].tokensWallet += active_auctions[_auctionID].numTokens;
    }


    //This function allows the seller to cancel an auction, within this step, they also get back the tokens that they were getting back for sale
    function cancelAuction(uint _auctionID) public{
        require(msg.sender == active_auctions[_auctionID].sellerID, 'Only the seller can cancel an auction' ); //require that only the seller can cancel an auction
        active_auctions[_auctionID].isActive = false;
        //send back ether to all bidders
        registered_users[active_auctions[_auctionID].sellerID].tokensWallet += active_auctions[_auctionID].numTokens;
        frozenTokens -= active_auctions[_auctionID].numTokens;
        active_auctions[_auctionID].highestBidder.personAddress = msg.sender;
    }

    //This function allows for people who didn't win an auction to get back all of the ether that they bid.
    function withdrawEther(uint _auctionID) public{
        require(active_auctions[_auctionID].highestBidder.personAddress != msg.sender, "You are the highest bidder for this auction, so you cannot withdraw the money that you bid");
        msg.sender.transfer(active_auctions[_auctionID].bidders[msg.sender]);
        active_auctions[_auctionID].bidders[msg.sender] = 0;
    }

    //This funciton allows the winning bidder to retrieve their winnings
    function retrieveWinnings(uint _auctionID) public{
        require(active_auctions[_auctionID].highestBidder.personAddress == msg.sender, "You were not the winner of this auction");
        require(active_auctions[_auctionID].isActive == false, "You must wait until the auction is over for you to withdraw your winnings");
       registered_users[active_auctions[_auctionID].highestBidder.personAddress].tokensWallet += active_auctions[_auctionID].numTokens;
       frozenTokens -= active_auctions[_auctionID].numTokens;
       active_auctions[_auctionID].numTokens = 0;
    }


    //This function allows the seller of an auction to retrieve their earnings
    function retrieveEarningsFromSale(uint _auctionID) public{
        require(active_auctions[_auctionID].sellerID == msg.sender, "You were not the seller for this auction");
        require(active_auctions[_auctionID].isActive == false, "You must wait until the auction is over for you to withdraw your earnings");
        msg.sender.transfer(active_auctions[_auctionID].highestCurrentBid);
        active_auctions[_auctionID].highestCurrentBid = 0;
    }

    //TEST function to check the current user ether balance - to be removed later
    function getBalanceEther(address _addressToCheck) public returns (uint){
        theBalanceToCheckEther = _addressToCheck.balance;
        return theBalanceToCheckEther;
    }

    //This function allows you to check the amount of ether stroed in the contract
    function contractEther() public {
        theBalanceToCheckEther = getBalanceEther(address(this));
    }
    //This function takes in the auction that a user has participated in, and returns the amount that they have bid on that auction
    function checkBidAmount(uint _auctionID) public {
        theBidAmount = active_auctions[_auctionID].bidders[msg.sender] ;
    }

    //This function tells you how many tokens you have
    function checkTokenBalance() public {
        theTokenBalance = registered_users[msg.sender].tokensWallet;
    }
    
    //This function retrieves the emissions value from the Oracle
    function getEmission(address _address) public constant returns(uint O) {
        OracleInterface o = OracleInterface(addressOracle);
        return o.emissions_registry(_address); 
    }
    
    //This function allows individual users to finish their year calculations
    function endYearCalculation() public {
        uint emissions = getEmission(msg.sender); 
        //NEED TO HAVE A FLAG ON THE USER WHETHER THEY CAN FINISH THE YEAR OR NOT
        
    }
    

}