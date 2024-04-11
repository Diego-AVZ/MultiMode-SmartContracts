//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Treasury {

    address public w = 0x2cba26026528a0453897443Da36B13b1DA0edF04; 
    address public x = 0x9C0305DF20F44408515f08EF24fCE19Cd36487cD;
    address public y = 0xCF7395902F4BcBDA06928306A4f233633441b78c; 
    address public z = 0x6F8781DA9eC9E742D8d32Bf7D7e10e96c0B6b6ea; 
    
    
    modifier onlyFounders(){
        require(msg.sender == w || msg.sender == x || msg.sender == y || msg.sender == z);
        _;
    }

    function deposit() payable public{

    }

    struct withdrawOrder {
        address to;
        uint amount;
        bool completed;
        uint8 votes;
        string concept;
    }

    withdrawOrder public newOrder;

    mapping(address => bool) hasVoted;

    function createWithdraw(uint amount, address to, string memory concept) public onlyFounders{
        newOrder = withdrawOrder(to, amount, false, 0, concept);
        hasVoted[w] = false;
        hasVoted[x] = false;
        hasVoted[y] = false;
        hasVoted[z] = false;
    }

    function approveWithdraw(bool iApprove) public onlyFounders{
        require(newOrder.completed == false);
        require(hasVoted[msg.sender] == false);
        hasVoted[msg.sender] = true;
        if(newOrder.votes == 0 && iApprove == true){
            newOrder.votes++;
        } else if(newOrder.votes == 1 && iApprove == true){
            newOrder.votes++;
        } else if(newOrder.votes == 2 && iApprove == true){
            newOrder.votes++;
            newOrder.completed = true;
            payable(newOrder.to).transfer(newOrder.amount);
        }
    }

    function seeWithdrawOrder() public view returns(address, uint, uint8, string memory){
        return(newOrder.to, newOrder.amount, newOrder.votes, newOrder.concept);
    }

    receive() external payable {}

}