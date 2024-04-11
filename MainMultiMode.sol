//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MultiMode {

    address public owner;
    address public treasury;

    constructor(address _owner, address _treasury){
        owner = _owner;
        treasury = _treasury;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
  
    modifier onlyMultiMode(){
        bool accepted = false;
        for(uint8 i = 0; i < multimodeContracts.length; i++){
            if(msg.sender == multimodeContracts[i]){
                accepted = true;
                break;
            }
        }
        require(accepted, "Not in the Multimode Contracts List");
        _;
    }

    bool public paused;

    function pause() public onlyOwner{
        paused = true;
    }

    function open() public onlyOwner{
        paused = false;
    }

    uint32 public totalPoints;
    uint public totalVolume;
    uint32 public totalUsers;
    mapping(address => uint32) userPoints;
    mapping(address => uint8) level;
    mapping(address => uint) userVol;

    function getMyPuntuation(address user) public view returns(uint32) {
        return(userPoints[user]);
    }

    function getTotalPoints() public view returns(uint32) {
        return(totalPoints);
    }

    function levelChecker(address user) public view returns(uint8){
        return(level[user]);
    }

    function volumeChecker(address user) public view returns(uint){
        return(userVol[user]);
    }

    function totalVolumeChecker() public view returns(uint){
        return(totalVolume);
    }

     function totalUsersChecker() public view returns(uint){
        return(totalUsers);
    }

    function getTotalUsers() public view returns(uint){
        return(users.length);
    }
    
    address[] public multimodeContracts;

    function givePermission(address a) public onlyOwner(){
        multimodeContracts.push(a);
    }

    function changePoints(uint8 ty, uint16 amount, bool multi, address user) public onlyMultiMode{
        if(!paused){
            if(ty == 1){ // + points
                if(multi == true){
                    userPoints[user] += amount*level[user];
                    totalPoints += amount*level[user];
                } else {
                    userPoints[user] += amount;
                    totalPoints += amount;
                }
            } else if(ty == 2) { // - points
                userPoints[user] -= amount;
                totalPoints -= amount; 
            }
        }
    }

    function addVolume(uint amount, address user) public onlyMultiMode(){
        userVol[user] += amount;
        totalVolume += amount;
    }

    function changeLevel(address user) public onlyMultiMode{ // Level Up
        level[user]++;
    }

    struct usersPoints {
        address user;
        uint32 mmPoints;
    }
    
    address[] public users;
    usersPoints[] public usersPointsList;

    function getLeaderBoard() public view returns (usersPoints[] memory) {
        uint256 usersLen = users.length;
        usersPoints[] memory leaderBoardInfo = new usersPoints[](usersLen);
        for (uint256 i = 0; i < usersLen; i++) {
            address userAddr = users[i];
            leaderBoardInfo[i].user = userAddr;
            leaderBoardInfo[i].mmPoints = userPoints[userAddr];
        }
        return leaderBoardInfo;
    }

    function registerUser(address user) public onlyMultiMode{
        users.push(user);
    }

}