pragma solidity >=0.4.22 <0.6.0;
contract MEGA{
    // string token_name = "ETS tokens";
    // string token_code = "ETS";

    //static variable : total initial cap

    //empty mapping / dictionary : user id (blockchain address) to the number of allowances and number of emissions


    uint256 total_cap = 10000;
    mapping(address => uint256) public user_balance;

    address owner;

    constructor() public {
        // if (user_balance[owner] == 0){
        //     user_balance[owner] =  200;
        // }
        // here assign each user with the initial number of tokens
        //
    }

    //function : see total cap
    function totalEmissionsCap() view public returns (uint256){
        return total_cap;
    }

    //function : see user balance

    //function : see user ether

    //function : see user emissions

    //fucntion : sell allowance

    //function : see all auctions

    //function : cancel transaction

    //function : (ADMIN) finalise year

    //function : (ADMIN) set total cap

    //function : (ADMIN) set decrease rate




    // function balanceOf(address _user) view public returns (uint256){
    //     return user_balance[_user];
    // }


    // function transfer(address _to, uint _value) public returns (bool){
    //     if (user_balance[owner] >= _value){
    //         user_balance[owner] -= _value;
    //         user_balance[_to] += _value;
    //         emit Transfer(owner, _to, _value);
    //     }
    //     else {
    //         emit NotEnoughFunds(owner, _to, _value, user_balance[owner]);
    //     }

    // }

    // event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // event NotEnoughFunds(address indexed _from, address indexed _to, uint256 _value, uint256 _userbalance);


}
