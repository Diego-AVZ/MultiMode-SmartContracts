// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainMultiMode.sol";

contract LevelManagerAndBuyPoints{

    MultiMode public main;

    constructor(address multimode){
        main = MultiMode(multimode);
    }

    function levelUp(address user) public{
        uint32 myPoints = main.getMyPuntuation(user);
        uint32 myLevel = uint32(main.levelChecker(user));
        require(myLevel < 101, "max level reached!");
        require(myPoints >= (myLevel+1)*5000);
        uint32 points = uint32((myLevel+1)*5000)/(myLevel);
        for(uint8 i = 0; i < myLevel; i++){
            main.changePoints(2, uint16(points), false, user); 
        }
        main.changeLevel(user);
    }

    function checkIfCanLevelUp(address user) public view returns(bool){
        uint32 myPoints = main.getMyPuntuation(user);
        uint32 myLevel = uint32(main.levelChecker(user));
        if(myPoints >= (myLevel+1)*5000 && myLevel < 101){
            return(true);
        } else{return(false);}
    }

    function getPointUntilNextLevel(address user) public view returns(uint32){
        uint32 myPoints = main.getMyPuntuation(user);
        uint32 myLevel = uint32(main.levelChecker(user));
        uint32 nextLevel = myLevel + 1;
        uint32 pointsNeeded = nextLevel * 5000;
        if(myLevel < 101){
            if(myPoints > pointsNeeded) {
                return 0;
            }
            return pointsNeeded - myPoints;
        } else {
            return 0;
        }
    }
}
