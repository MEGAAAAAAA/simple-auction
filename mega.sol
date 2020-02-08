pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;


/*

MEGA.sol v0.013 (Annazita's changes on 20/1/20 7:08pm)

Contract MEGA is intended to assist with allowance trading within the European Union Emissions Trading Scheme (EU ETS).

*/

contract MEGA{


    //Global variables and data structures used in the contract
    uint256 total_cap = 10000; //the initial number of total allowance tokens in the contract
    uint total_actors = 20; //the initial number of actors in the contract
    uint public frozenTokens = 0;
    uint public usersCount = 0; //number of registered users (OPTIONAL - for test purposes)
    uint public auctionCount = 0; //number of currently active auctions (OPTIONAL - for test purposes)
    uint public theBalanceToCheckEther = 0; //balance that is being checked (OPTIONAL - for test purposes - REMOVE LATER)
    uint public theBalanceToCheckTokens = 0;
    address payable owner;


    mapping(address => Person) registered_users; //a mapping with registered users and their corresponding addresses
    mapping(uint => Auction) public active_auctions; //a mapping with all currently active auctions and their corresponding IDs
    mapping(uint => uint) public depositors_tokens;


    constructor() public {
        // State variables are accessed via their name
        // and not via e.g. this.owner. This also applies
        // to functions and especially in the constructors,
        // you can only call them like that ("internally"),
        // because the contract itself does not exist yet.
        owner = msg.sender;
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

    //Struct defining an auction, I got rid of increment and highestMaxBid
    struct Auction{
        uint auctionID; //unique auction identifier
        uint numTokens; //number of tokens on sale
        uint minPrice; //minimum price per all tokens offered
        address sellerID; //address of the token seller
        bool isActive; //flag for active auction
        uint numBids; //number of current bidders in the auction
        uint highestCurrentBid; //value of the current highest bid
        Person highestBidder; //Person instance of the highest bidder

        mapping(address => uint) bidders; //mapping with amount of money paid to bid

        //Implement the below in the future:
        // endTime : timestamp / endblock
        // payersHistory : list (of tuples?)

    }

    //Function to place tokens on auction
    function sellTokens(uint _amount, uint _minPrice) public {
        //ACTION REQUIRED : needs to check if has enough tokens to sell


        require(_amount != 0, "Cannot sell empty auction.");//require the auction not to be empty
        auctionCount += 1;
        //Instantiating a new auction with specified amount and minimum price
        Auction memory newAuction = Auction({
                                            auctionID: auctionCount,
                                            numTokens: _amount,
                                            minPrice: _minPrice,
                                            sellerID: msg.sender,
                                            isActive: true,
                                            numBids: 0,
                                            highestCurrentBid: 0,
                                            highestBidder: Person(0x0000000000000000000000000000000000000000, 0, false)});
        active_auctions[auctionCount] = newAuction; //adding auction to the mapping of currently active functions
    }


    //Function to place a bid on the auction
    function buyTokens(uint _auctionID, uint _userBid) public {
        //add condition to check if requestor has enough ether
        require(msg.sender.balance > _userBid, "You have insufficient funds."); //require the buyer to have enough ether funds to cover the transaction
        //I think eventually we will need a requirement here that the auction addressed is active
        require(_userBid > active_auctions[_auctionID].highestCurrentBid, "You cannot bid less than or equal to the current highest bid."); //require the amount that the buyer is offering is greater than the current highest bid.
        require(_userBid >= active_auctions[_auctionID].minPrice, "The seller is not willing to sell at this price"); //require the bidder to bid at least the minPrice

        active_auctions[_auctionID].highestCurrentBid = _userBid;//min((active_auctions[_auctionID].highestMaxBid + active_auctions[_auctionID].increment), _maxBid), but this won't compile;
        active_auctions[_auctionID].highestBidder = registered_users[msg.sender];
        active_auctions[_auctionID].numBids += 1;
        // msg.value = _userBid;
        // depositFunds(_auctionID, msg.sender);
    }


    //TEST function to check the current user ether balance - to be removed later
    function getBalanceEther(address _addressToCheck) public returns (uint){
        theBalanceToCheckEther = _addressToCheck.balance;
        return theBalanceToCheckEther;
    }


    //Function to check the balance of tokens of a particular user
    function getBalanceTokens(address _addressToCheck) public returns (uint){
        theBalanceToCheckTokens = registered_users[_addressToCheck].tokensWallet;
        return theBalanceToCheckTokens;
    }


    function depositFunds(uint _auctionID, address _bidderAddress) external payable { //auction ID, bidder address
        owner.transfer(msg.value); // transfer from bidder to ^^account;
        active_auctions[_auctionID].bidders[_bidderAddress] = msg.value; // add to the list of mappings of bidders in a specific auction

        // error message
    }



    // function depositTokens(address _depositorT, uint _amountT, uint _auctionID){
    //     frozenTokens += _amountT;
    //     registered_users[_depositorT].tokensWallet -= _amountT;
    // }


    // function withdrawTokens(address _collectorT, uint _amountT){

    // }

}
