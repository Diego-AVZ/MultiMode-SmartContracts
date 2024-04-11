//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainMultiMode.sol";

contract mmDAO {

    MultiMode public main;

    constructor(address multimode){
        main = MultiMode(multimode);
    }

    address public w = 0x5c8Ae61e061BCeFBc241DE8F3F216D6C000128f5;
    address public x = 0x5c8Ae61e061BCeFBc241DE8F3F216D6C000128f5;
    address public y = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public z = 0xFD7924cc5885422E7ACC0901B6930c471Da4021B;
    
    modifier onlyFounders(){
        require(msg.sender == x || msg.sender == y || msg.sender == z || msg.sender == w);
        _;
    }

    struct proposal {
        uint16 propId;
        string title;
        string text;
        string question;
        string option1;
        string option2;
        string option3;
        uint16 votes1;
        uint16 votes2;
        uint16 votes3;
        bool closed;
    }

    proposal public newProp;
    uint16 public id = 0;
    mapping(uint16 => mapping(address => bool)) hasVoted;
    mapping(uint16 => mapping(address => uint8)) userVote;
    mapping(uint16 => proposal) idProp;

    function createProposal(
        string memory title,
        string memory text,
        string memory question,
        string memory option1,
        string memory option2,
        string memory option3
        ) public onlyFounders{
            id++;
            newProp = proposal(id, title, text, question, option1, option2, option3, 0,0,0, false);
            idProp[id] = newProp;
    }

    function voteProposal(uint8 vote) public {
        require(hasVoted[id][msg.sender] == false);
        require(newProp.closed == false);
        if(vote == 1){
            newProp.votes1++;
        } else if(vote == 2){
            newProp.votes2++;
        } else if(vote == 3){
            newProp.votes3++;
        } else if(vote == 3){
            newProp.votes3++;
        }
        userVote[id][msg.sender] = vote;
        hasVoted[id][msg.sender] == true;
        main.changePoints(1, 25, true, msg.sender);
    }

    function closeProposal() public onlyFounders{
        newProp.closed = true;
    }

    function seeMyVote(address user) public view returns(uint8, bool){ // and if I can vote
        return(userVote[id][user], hasVoted[id][user]);
    }

    function readProposal() public view returns(
        string memory,
        string memory, 
        string memory, 
        string memory, 
        string memory, 
        string memory, 
        uint16, 
        uint16, 
        uint16
        ){
            return(newProp.title,
                newProp.text, 
                newProp.question, 
                newProp.option1, 
                newProp.option2, 
                newProp.option3, 
                newProp.votes1,
                newProp.votes2,
                newProp.votes3
            );
    }

}