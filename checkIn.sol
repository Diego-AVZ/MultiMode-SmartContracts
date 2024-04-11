// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainMultiMode.sol";

contract CheckIn {

    MultiMode public main;
    
    constructor(address multimode){
        main = MultiMode(multimode);
    } 

    mapping(address => uint16) activeDays;
    mapping(address => uint[]) calendar;

    // gas functions

    function checkIn() public {
            require(!isCheckedToday(msg.sender), "You can only check in once per day");
            main.changePoints(1, 5, true, msg.sender);
            activeDays[msg.sender]++;
            calendar[msg.sender].push(block.timestamp);
    }

    // OnlyRead Functions

    function isCheckedToday(address user) public view returns (bool) {
        uint256[] memory userCalendar = calendar[user];
        if (userCalendar.length == 0) {
            return false;
        }
        
        uint256 lastCheck = userCalendar[userCalendar.length - 1];
        uint256 todayStart = getTodayStart();

        return lastCheck >= todayStart;
    }

    function getTodayStart() public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        return timestamp - (timestamp % 1 days);
    }

    function getActivity(address user) public view returns(uint16) {
        return(activeDays[user]);
    }

    function getCheckInData(uint16 xDays, address user) public view returns(uint256[] memory){
        uint256 userArrayLen = calendar[user].length;
        if(xDays < userArrayLen) {
            uint256 iValue = userArrayLen - xDays;
            uint256[] memory newCalendar = new uint256[](xDays);
            for(uint256 i = iValue; i < calendar[user].length; i++){
                newCalendar[i - iValue] = calendar[user][i];
            }
            return(newCalendar);
        } else {
            return(calendar[user]);
        }
        
    }
}