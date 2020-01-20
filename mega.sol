pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;


/*

MEGA.sol v0.012 (Gosia's changes on 20/1/20 4:30pm)

Contract MEGA is intended to assist with allowance trading within the European Union Emissions Trading Scheme (EU ETS).

*/

contract MEGA{


    //Global variables and data structures used in the contract
    uint256 total_cap = 10000; //the initial number of total allowance tokens in the contract
    uint total_actors = 20; //the initial number of actors in the contract
    uint public usersCount = 0; //number of registered users (OPTIONAL - for test purposes)
    uint public auctionCount = 0; //number of currently active auctions (OPTIONAL - for test purposes)
    uint public theBalanceToCheck = 0; //balance that is being checked (OPTIONAL - for test purposes - REMOVE LATER)

    mapping(address => Person) registered_users; //a mapping with registered users and their corresponding addresses
    mapping(uint => Auction) public active_auctions; //a mapping with all currently active auctions and their corresponding IDs



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
        require(registered_users[msg.sender].isActive == false); //check if users not registered yet
        if (usersCount <= total_actors){ //check if there is an available actor slot
            Person memory newUser = createPerson(msg.sender); //generate a new user
            registered_users[msg.sender] = newUser; //add user to registered_users list
            usersCount += 1; //increase user count to keep track of the total registered_users size
        }
    }

    //Struct defining an auction
    struct Auction{
        uint auctionID; //unique auction identifier
        uint numTokens; //number of tokens on sale
        uint minPrice; //minimum price per all tokens offered
        uint increment; //the increment value for bidding - (default set to 1, in the future adjustable)
        address sellerID; //address of the token seller
        bool isActive; //flag for active auction
        uint numBids; //number of current bidders in the auction
        uint highestCurrentBid; //value of the current highest bid
        uint highestMaxBid; //value of the maximum bid from the current highest bidder
        Person highestBidder; //Person instance of the highest bidder

        //Implement the below in the future:
        // endTime : timestamp / endblock
        // payersHistory : list (of tuples?)

    }

    //Function to place tokens on auction
    function sellTokens(uint _amount, uint _minPrice) public {
        require(_amount != 0); //require the auction not to be empty
        auctionCount += 1;
        //Instantiating a new auction with specified amount and minimum price
        Auction memory newAuction = Auction({
                                            auctionID: auctionCount,
                                            numTokens: _amount,
                                            minPrice: _minPrice,
                                            increment: 1,
                                            sellerID: msg.sender,
                                            isActive: true,
                                            numBids: 0,
                                            highestCurrentBid: _minPrice,
                                            highestMaxBid: 0,
                                            highestBidder: Person(0x0000000000000000000000000000000000000000, 0, false)});
        active_auctions[auctionCount] = newAuction; //adding auction to the mapping of currently active functions
    }


    //Function to place a bid on the auction
    function buyTokens(uint _auctionID, uint _maxBid) public {
        //add condition to check if requestor has enough ether
        require(msg.sender.balance > _maxBid); //require the buyer to have enough ether funds to cover the transaction

        if (_maxBid > active_auctions[_auctionID].highestCurrentBid){
            if (_maxBid > active_auctions[_auctionID].highestMaxBid){
                active_auctions[_auctionID].highestCurrentBid = active_auctions[_auctionID].highestMaxBid + active_auctions[_auctionID].increment;
                active_auctions[_auctionID].highestMaxBid = _maxBid;
                active_auctions[_auctionID].highestBidder = registered_users[msg.sender];
                active_auctions[_auctionID].numBids += 1;
            }
            else {
                active_auctions[_auctionID].highestCurrentBid = _maxBid + active_auctions[_auctionID].increment;
            }
        }
        else {}
    }

    //TEST function to check the current user ether balance - to be removed later
    function getBalance(address _addressToCheck) public returns (uint){
        theBalanceToCheck = _addressToCheck.balance;
        return theBalanceToCheck;
    }



}
