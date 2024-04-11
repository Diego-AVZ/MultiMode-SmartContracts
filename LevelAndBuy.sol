// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainMultiMode.sol";

contract LevelManagerAndBuyPoints{

    MultiMode public main;
    address public treasury;
    address public owner;

    constructor(address multimode, address _treasury, address _owner){
        main = MultiMode(multimode);
        treasury = _treasury;
        owner = _owner;
    }

    modifier onlyOwner(){
        require (msg.sender == owner);
        _;
    }

    bool private locked;

    modifier noReentrancy() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function exchangePoints(address user) public{
        uint32 myPoints = main.getMyPuntuation(user);
        uint8 myLevel = main.levelChecker(user);

        if(myLevel == 1){
            require(myPoints >= 500);
            main.changePoints(2, 500, false, user);
            main.changeLevel(user);
        } else if(myLevel == 2){
            require(myPoints >= 1500);
            main.changePoints(2, 1500, false, user);
            main.changeLevel(user);
        } else if(myLevel == 3){
            require(myPoints >= 3000);
            main.changePoints(2, 3000, false, user);
            main.changeLevel(user);
        } else if(myLevel == 4){
            require(myPoints >= 6000);
            main.changePoints(2, 6000, false, user);
            main.changeLevel(user);
        } else if(myLevel == 5){
            require(myPoints >= 10000);
            main.changePoints(2, 10000, false, user);
            main.changeLevel(user);
        } else if(myLevel == 6){
            require(myPoints >= 15000);
            main.changePoints(2, 15000, false, user);
            main.changeLevel(user);
        } else if(myLevel == 7){
            require(myPoints >= 22500);
            main.changePoints(2, 22500, false, user);
            main.changeLevel(user);
        } else if(myLevel == 8){
            require(myPoints >= 30000);
            main.changePoints(2, 30000, false, user);
            main.changeLevel(user);
        } else if(myLevel == 9){
            require(myPoints >= 35000);
            main.changePoints(2, 35000, false, user);
            main.changeLevel(user);
        } 
    }

    function canLevelUp(address user) public view returns(bool){
        uint32 myPoints = main.getMyPuntuation(user);
        uint8 myLevel = main.levelChecker(user);

        if(
            myLevel == 1 && myPoints >= 500 ||
            myLevel == 2 && myPoints >= 1500 ||
            myLevel == 3 && myPoints >= 3000 ||
            myLevel == 4 && myPoints >= 6000 ||
            myLevel == 5 && myPoints >= 10000 ||
            myLevel == 6 && myPoints >= 15000 ||
            myLevel == 7 && myPoints >= 22500 ||
            myLevel == 8 && myPoints >= 30000 ||
            myLevel == 9 && myPoints >= 35000 
        ){
            return(true);
        } else{return(false);}

    }

    uint public contractBalance;
    uint public pricePerPoint = 750000000000; // 1 point = 0.00000075 ETH

    function buyPoints(uint16 amount) payable public { // Input amount of points
            require(msg.value >= amount * pricePerPoint); 
            main.changePoints(1, amount, false, msg.sender);
            contractBalance += msg.value;
    }

    function devWithdraw() public onlyOwner noReentrancy{
        payable(treasury).transfer(contractBalance);
        contractBalance = 0;
    }

    function get1PointPrice() public view returns(uint){
        return(pricePerPoint);
    }

    function getPointsPrice(uint16 amount) public view returns(uint){
        return(amount * pricePerPoint);
    }
    
}