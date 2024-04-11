//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainMultiMode.sol";

contract ReferralProgram {

    MultiMode public main;

    constructor(address multimode){
        main = MultiMode(multimode);
    }

    mapping(address => bytes8) public addressCode;
    mapping(bytes8 => address) public codeAddress;
    mapping(address => address) public myReferrer;
    mapping(address => uint32) public usersPerReferralCode;
    mapping(address => bool) hasReg;
    mapping(address => bool) hasCreated;

    function createCode(address user) public {
        require(!hasCreated[user]);
        bytes8  code = bytes8 (keccak256(abi.encodePacked(user)));
        addressCode[user] = code;
        codeAddress[code] = user;
        hasCreated[user] = true;
    }

    function useReferral(bytes8 code, address user) public {
        require(hasReg[user] == false);
        myReferrer[user] = codeAddress[code];
        usersPerReferralCode[codeAddress[code]]++;
        hasReg[user] = true;
        main.changePoints(1, 50, false, user);  // User earns points
        main.changePoints(1, 150, false, myReferrer[user] ); // Referrer earns points
    }

    function seeIfHasCreated(address user) public view returns(bool, bytes8){
       return(hasCreated[user], addressCode[user]);
    } 

    function getReferralUsersCount(address user) public view returns(uint32){
        return(usersPerReferralCode[user]);
    } 

}