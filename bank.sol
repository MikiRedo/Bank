// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {

    address admin;
    mapping(address => uint) balances;
    uint public fee;
    uint public realAmount;  //number!  ex:(2 means 2%, etc)
    uint public bankFee;    //amount that the bank keeps

    mapping(address => uint256) private lastInterestTime;
    uint256 private annualInterestRate = 5;  //by default, adomin can change it 
    mapping(address => uint256) private interestGiven;

    event DepositSucced(uint realAmount);
    event NewFee(uint fee);
    event NewStake(uint staking);
    event InterestUpdated(address account, uint newBalance);

    constructor(){
        admin = tx.origin;  //saber qui sera l'admin
        fee = 2;  //by default lets say 2, only admin can change the fee that the bank keeps
    }

    function getUserBalance(address user) public returns (uint256) {
        require(msg.sender == admin, "Not authorised");
        calculateInterest(msg.sender); 
        return balances[user];
    }

    function deposit() public payable {
        require(msg.value > 0, "Not enought money, sorry");

        calculateInterest(msg.sender);

        realAmount = msg.value - (msg.value * (fee/100));  //deposit with comision aplied
        balances[msg.sender] += realAmount;                //we update the balance of the user

        bankFee = msg.value - realAmount;    //fee for the admin is the diference between the deposit and the rea
        balances[admin] += bankFee;         //we update the balance of the admin 

        emit DepositSucced(realAmount);    //remirar on van les bankFee                                                
    }   

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "No money enought");

        calculateInterest(msg.sender);

        payable(msg.sender).transfer(amount);  //pensar
        balances[msg.sender] -= amount;

    }

    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    //fee for the admin functions

    function setFee(uint _fee) public {
        require(_fee >= 1, "We dont allow lower fees");
        require(msg.sender == admin, "Not authorised");  //only admin can change the fee
        
        fee = _fee;

        emit NewFee(fee);
    }

    function checkCureentFee() public view returns (uint){
        return fee;
    }

    //staking-interests functions

    function setNewInterest(uint _interest) public {
        require(_interest >= 1 && _interest <= 15, "Must be in this range");
        require(msg.sender == admin, "Not authorised");  //only admin can change the fee
        
        annualInterestRate = _interest;

        emit NewStake(fee);
    }
    
    function calculateInterest(address user) internal {    

        uint timeSinceUpdate = block.timestamp - lastInterestTime[user]; 
        uint interest = (balances[user] * annualInterestRate * timeSinceUpdate);

        balances[user] += interest;
        lastInterestTime[user] = block.timestamp;

        emit InterestUpdated(user, balances[user]);
    }
}
