//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import "./Referral.sol";
import "./MainMultiMode.sol";


contract LogInDisclaimer {

    ReferralProgram public referral;
    MultiMode public main;
    uint256 deployDate;

    constructor(address _referral, address multimode){
        referral = ReferralProgram(_referral);
        main = MultiMode(multimode);
        deployDate = block.timestamp;
    }

    mapping(address => bool) hasLogIn;
    mapping(address => string) public disclaimers;

    function simpleLogIn(string memory data) public {
        require(hasLogIn[msg.sender] == false);
        uint8 level = main.levelChecker(msg.sender); 
        if(level == 0) {main.changeLevel(msg.sender);} 
        hasLogIn[msg.sender] = true;
        disclaimers[msg.sender] = data;
        referral.createCode(msg.sender);
        if(block.timestamp < deployDate + 10 days){
            main.changeLevel(msg.sender);
        }
        main.registerUser(msg.sender);
    }

    function logInReferral(string memory data, bytes8 code) public {
        require(hasLogIn[msg.sender] == false);
        uint8 level = main.levelChecker(msg.sender); 
        if(level == 0) {main.changeLevel(msg.sender);} 
        hasLogIn[msg.sender] = true;
        disclaimers[msg.sender] = data;
        referral.useReferral(code, msg.sender);
        referral.createCode(msg.sender);
        if(block.timestamp < deployDate + 10 days){
            main.changeLevel(msg.sender);
        }
        main.registerUser(msg.sender);
    }
 
    mapping(address => bool) completedTask1;

    function registerMailTask() public{
        require(completedTask1[msg.sender] == false);
        completedTask1[msg.sender] = true;
        main.changePoints(1, 150, false, msg.sender);
    }

    function seeIfRegis(address user) public view returns(bool){
        return(completedTask1[user]);
    }

    // call() Functions / No gas

    function seeIfHasSigned(address user) public view returns(bool, string memory){
        if(hasLogIn[user] == true){
            return(hasLogIn[user], disclaimers[user]);
        } else {
            return(hasLogIn[user], "...No...");
        }
    }

}
