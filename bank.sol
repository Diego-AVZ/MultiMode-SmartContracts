//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainMultiMode.sol";


contract BankV2 {

    MultiMode public main;
    address public owner;

    constructor(address multimode, address _owner){
        main = MultiMode(multimode);
        owner = _owner;
    }

    modifier onlyOwner(){ 
        require(msg.sender == owner);
        _;
    }

    bool public paused;

    function pause() public onlyOwner{
        paused = true;
    }

    function open() public onlyOwner{
        paused = false;
    }

    modifier notPaused(){
        require(paused == false);
        _;
    }

    struct stakes {
        uint256 amountEth;
        uint256 date;
    }

    mapping(address => uint) public myDepositedEth;
    mapping(address => stakes[]) public myStakes;
    mapping(address => uint16) public numOfTx;
    mapping(address => uint16) public stPoints;

    function depositEth() public payable notPaused {
        require(msg.value > 0);
        myDepositedEth[msg.sender] += msg.value;
        numOfTx[msg.sender]++;
        main.addVolume(msg.value, msg.sender); 
        if(msg.value >= 100000000000000 && msg.value < 1000000000000000) { 
            main.changePoints(1, 1, true, msg.sender);
        } else if(msg.value >= 1000000000000000 && msg.value < 5000000000000000) {
            main.changePoints(1, 5, true, msg.sender);
        } else if(msg.value >= 5000000000000000 && msg.value < 10000000000000000) {
            main.changePoints(1, 10, true, msg.sender);
        } else if(msg.value >= 10000000000000000 && msg.value < 25000000000000000) {
            main.changePoints(1, 25, true, msg.sender);
        } else if(msg.value >= 25000000000000000 && msg.value < 50000000000000000) {
            main.changePoints(1, 35, true, msg.sender);
        } else if(msg.value >= 50000000000000000 && msg.value < 100000000000000000) {
            main.changePoints(1, 75, true, msg.sender);
        }  else if(msg.value >= 100000000000000000) {
            main.changePoints(1, 150, true, msg.sender);
        }
    }

    function stake(uint256 amount) public notPaused{
        require(amount > 0 && amount <= myDepositedEth[msg.sender]);
        stakes memory newStake = stakes(amount, block.timestamp);
        myStakes[msg.sender].push(newStake);
        myDepositedEth[msg.sender] -= amount;
    }

    function unStake() public notPaused{
        uint256 numOfStakes = myStakes[msg.sender].length;
        uint256 amountStaked;
        for(uint8 i = 0; i < numOfStakes; i++){
            amountStaked += myStakes[msg.sender][i].amountEth;
        }
        require(amountStaked > 0);
        myDepositedEth[msg.sender] += amountStaked;
        stPoints[msg.sender] += calculateStakingPoints(msg.sender);
        delete myStakes[msg.sender];
    }

    function claimStPoints() public {
        uint16 pointsToClaim = stPoints[msg.sender] + calculateStakingPoints(msg.sender);
        main.changePoints(1, pointsToClaim, true, msg.sender);
        stPoints[msg.sender] = 0;
        uint256 numOfStakes = myStakes[msg.sender].length;
        uint256 amountStaked;
        if(numOfStakes > 0){
            for(uint8 i = 0; i < numOfStakes; i++){
                amountStaked += myStakes[msg.sender][i].amountEth;
            }
        }
        delete myStakes[msg.sender];
        stakes memory newStake = stakes(amountStaked, block.timestamp);
        myStakes[msg.sender].push(newStake);
    }
 
    function withdrawMyEth() public notPaused{
        require(myDepositedEth[msg.sender]>0);
        payable(msg.sender).transfer(myDepositedEth[msg.sender]);
        numOfTx[msg.sender]++;
        main.addVolume(myDepositedEth[msg.sender], msg.sender);
        main.changePoints(1, 1, true, msg.sender);
        myDepositedEth[msg.sender] = 0;
    }

    function calculateStakingPoints(address user) public view returns(uint16){
        uint256 numOfStakes = myStakes[user].length;
        uint256 points; 
        if(numOfStakes > 0){
            for(uint8 i = 0; i < numOfStakes; i++){
                uint256 amount = myStakes[user][i].amountEth;
                uint256 date = myStakes[user][i].date;
                uint256 timeStaked = block.timestamp - date; // In Seconds
                if(amount > 0 && amount < 10000000000000000){
                    points += (timeStaked / 60)/5;
                } else if(amount >= 10000000000000000 && amount < 20000000000000000) {
                    points += (timeStaked / 60)/3;
                } else if(amount >= 20000000000000000 && amount < 50000000000000000){
                    points += (timeStaked / 60)/2;
                } else if(amount >= 50000000000000000 && amount < 100000000000000000){
                    points += (timeStaked / 60);
                } else if(amount >= 100000000000000000){
                    points += (timeStaked / 60)*2;
                }
            } 
        } else {points = stPoints[user]; }
        return(uint16(points));
    }

    function getBankData(address user) public view returns(uint, uint16){
        return(myDepositedEth[user], numOfTx[user]);
    }

    struct bankData {
        uint256 myDepositedEth;
        uint256 myStakedEth;
        uint16 numOfTx;
        uint16 myStPoints;
    }

    function getBankData2(address user) public view returns(bankData memory){
        uint256 myStakedEth;
        uint256 numOfStakes = myStakes[user].length;
        if(numOfStakes > 0){
            for(uint8 i = 0; i < numOfStakes; i++){
                myStakedEth += myStakes[user][i].amountEth;
            }
            bankData memory myBankData = bankData(myDepositedEth[user], myStakedEth, numOfTx[user], stPoints[user] + calculateStakingPoints(user));
            return(myBankData);
        } else {
            bankData memory myBankData = bankData(myDepositedEth[user], 0, numOfTx[user], stPoints[user]);
            return(myBankData);
        }
    }

}