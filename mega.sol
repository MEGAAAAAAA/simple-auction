pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

contract MEGA{

    uint256 total_cap = 10000;
    uint total_actors = 20;
    uint public usersCount = 0;
    uint public auctionCount = 0;
    
    mapping(address => Person) registered_users;
    mapping(uint => Auction) public active_auctions;

    struct Person{
        address personAddress;
        uint tokensWallet;
        uint emissionsTotal;
        bool isActive;
    }
    
    function createPerson (address _personAddress) private returns (Person memory){
        uint tokenAllocation = total_cap / total_actors;
        return Person({ personAddress: _personAddress, tokensWallet: tokenAllocation, emissionsTotal: 0, isActive: true});
    }
        
    function register() public{
        require(registered_users[msg.sender].isActive == false);
        Person memory newUser = createPerson(msg.sender);
        registered_users[msg.sender] = newUser;
        usersCount += 1;
    }
    
    struct Auction{
        uint auctionID;
        uint numTokens;
        uint minPrice;
        uint increment; //default set to 1 - verify (lawyers?)
        address sellerID;
        bool isActive;
        
        uint numBids; //default set to 0
        
        uint highestCurrentBid;
        uint highestMaxBid;
        Person highestBidder;
        
        // endTime : timestamp / endblock
        // payersHistory : list (of tuples?)
        
    }
    

    function sellTokens(uint _amount, uint _minPrice) public {
        auctionCount += 1;
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
                                            highestBidder: Person(0x0000000000000000000000000000000000000000, 0, 0, false)
        });
        active_auctions[auctionCount] = newAuction;
    }
    
    
    
    
    function buyTokens(uint _auctionID, uint _maxBid) public {
        //check if requestor has enough ether
        
        // SHALL WE START FROM MINIMUM ? 
        
        //check if maxBid > highestCurrentBid
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


    


}
