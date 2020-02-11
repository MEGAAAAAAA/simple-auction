pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;


/*

MEGA.sol v0.015 (Gosia's changes on 11/2/20 5:00pm)

Contract MEGA is intended to assist with allowance trading within the European Union Emissions Trading Scheme (EU ETS).

*/

contract MEGA{

    //Global variables and data structures used in the contract
    uint256 total_cap = 10000; //the initial number of total allowance tokens in the contract
    uint total_actors = 20; //the initial number of actors in the contract
    uint public frozenTokens = 0;
    uint usersCount = 0; //number of registered users (OPTIONAL - for test purposes)
    uint auctionCount = 0; //number of currently active auctions (OPTIONAL - for test purposes)
    uint public theBalanceToCheckEther = 0; //balance that is being checked (OPTIONAL - for test purposes - REMOVE LATER)
    
    uint yearEndTime = 0; //time when the year is over
    uint daysInYear = 0; //Number of days in this year
    bool yearDistribution = false; //have the tokens been distributed for this year
    address public owner;


    mapping(address => Person) public registered_users; //a mapping with registered users and their corresponding addresses
    mapping(uint => Auction) public active_auctions; //a mapping with all currently active auctions and their corresponding IDs
    mapping(uint => uint) public deposited_tokens;


    constructor() public {
        owner = msg.sender;
        yearEndTime = now + 365 days; // this is variable and I think this is a problem
    }

     modifier _ownerOnly(){
      require(msg.sender == owner);
      _;
    }

    //Struct defining a person (user) in the contract
    struct Person{
        address personAddress; //attribute for user address
        uint tokensWallet;  //attribute for the current number of tokens owned by the user
        bool isActive; //flag for active user
    }

    //Function to generate a new user, taking user address and returning Person instantiation
    function createPerson (address _personAddress) private returns (Person memory){
        uint tokenAllocation = total_cap / total_actors; //number of tokens to allocate per person
        return Person({ personAddress: _personAddress, tokensWallet: tokenAllocation, isActive: true});
    }

    //Function to register a new user
    function register() public{
        require(registered_users[msg.sender].isActive == false, "You are already registered"); //check if users not registered yet
        if (usersCount <= total_actors){ //check if there is an available actor slot
            Person memory newUser = createPerson(msg.sender); //generate a new user
            registered_users[msg.sender] = newUser; //add user to registered_users list
            usersCount += 1; //increase user count to keep track of the total registered_users size
        }
    }

    function endTheYear(uint _daysInNextYear) private _ownerOnly{
        require(now > yearEndTime, 'The year has not ended yet');
        daysInYear = _daysInNextYear;
        yearDistribution = false;
    }

    function distribute() private _ownerOnly{
        require(yearDistribution == false, 'Already distibuted this year');
        //send out tokens to all active users
        yearDistribution = true;
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
        //ACTION REQUIRED : needs to check if has enough tokens to sell
        //

        require(_amount != 0, "Cannot sell empty auction.");//require the auction not to be empty
        auctionCount += 1;
        
        //Instantiating a new auction with specified amount and minimum price
        Auction memory newAuction = Auction({
                                            auctionID: auctionCount,
                                            numTokens: _amount,
                                            minPrice: _minPrice * 1000000000000000000,
                                            sellerID: msg.sender,
                                            isActive: true,
                                            numBids: 0,
                                            highestCurrentBid: 0,
                                            auctionEnd: now + _biddingTime, // * 1 hours,
                                            highestBidder: Person(0x0000000000000000000000000000000000000000, 0, false)
                                            //bidders: 
        });
                                            
        active_auctions[auctionCount] = newAuction; //adding auction to the mapping of currently active functions
        
        
        frozenTokens += _amount;
        registered_users[msg.sender].tokensWallet -= _amount;
        deposited_tokens[auctionCount] = _amount;
    }


    //Function to place a bid on the auction
    function buyTokens(uint _auctionID) public payable {
        
        require(msg.sender.balance > msg.value, "You have insufficient funds."); //require the buyer to have enough ether funds to cover the transaction
        require(now <= active_auctions[_auctionID].auctionEnd, 'The ending time for this auction has been reached');//require that the end time for the auction has not already happened
        require(active_auctions[_auctionID].isActive, 'This auction is not active');//requrie that the auction is active
        require(msg.value > active_auctions[_auctionID].highestCurrentBid, "You cannot bid less than or equal to the current highest bid."); //require the amount that the buyer is offering is greater than the current highest bid.
        require(msg.value >= active_auctions[_auctionID].minPrice, "The seller is not willing to sell at this price"); //require the bidder to bid at least the minPrice


        //CONDITION IF BIDDING FOR THE FIRST TIME
        active_auctions[_auctionID].highestCurrentBid = msg.value;//min((active_auctions[_auctionID].highestMaxBid + active_auctions[_auctionID].increment), _maxBid), but this won't compile;
        active_auctions[_auctionID].highestBidder = registered_users[msg.sender];
        active_auctions[_auctionID].numBids += 1;
        // msg.value = _userBid;
        // depositFunds(_auctionID, msg.sender);
        active_auctions[_auctionID].bidders[msg.sender] = msg.value; 
        
        //CONDITION IF BIDDED ALREADY - INCREMENT
        // active_auctions[_auctionID].bidders[_bidderAddress] = msg.value; /
        
    }



    function endAuction(uint _auctionID) public{
        require(now > active_auctions[_auctionID].auctionEnd, 'The ending time for this auction has not yet been reached');//require that the end time for the auction has already happened
        active_auctions[_auctionID].isActive = false;
        //send back ether to all non-winning bidders
        //add the amount of tokens to the winning bidder
    }

    function cancelAuction(uint _auctionID) public{
        require(msg.sender == active_auctions[_auctionID].sellerID, 'Only the seller can cancel an auction' ); //require that only the seller can cancel an auction
        active_auctions[_auctionID].isActive = false;
        //send back ether to all bidders
        //send back tokens to seller
    }

    //TEST function to check the current user ether balance - to be removed later
    function getBalanceEther(address _addressToCheck) public returns (uint){
        theBalanceToCheckEther = _addressToCheck.balance;
        return theBalanceToCheckEther;
    }

    function contractEther() public {
        theBalanceToCheckEther = getBalanceEther(address(this));
    }



}