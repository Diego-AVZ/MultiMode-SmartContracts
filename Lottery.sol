//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainMultiMode.sol";
import "./Referral.sol";

contract Lottery { // 0-99 1/100
 
    MultiMode public main;
    ReferralProgram public ref;
    address public owner;
    address public treasury;

    constructor(address _owner, address _treasury, address multimode, address _ref){
        owner = _owner;
        treasury = _treasury;
        main = MultiMode(multimode);
        ref = ReferralProgram(_ref);
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

    uint32 public lotteryId;
    mapping(uint32 => uint) public finalDate;
    mapping(uint32 => uint) public winnerTicket;
    mapping(uint32 => address[]) public winners;
    mapping(uint32 => mapping(address => uint8[])) public userTickets;
    mapping(uint32 => address[]) public participants;
    mapping(uint32 => bool) public claimed;
    mapping(uint32 => mapping(address => bool)) public hasParti;
    mapping(uint32 => uint) public prizePerWinnerMap;
    uint256 public ticketPrice = 150000000000000;
    uint8 public ticketLimit = 25;
    uint256 public totalPrize;
    uint256 public totalLastPrize;
    uint8 public lotRandomVar;
    bool public firstLottery = true;
    uint8 public points = 25;


    event NewLotteryCreated(uint256 indexed lotteryId);
    event LotteryClosed(uint256 winnerTicket);

    function changePoints(uint8 amount) public onlyOwner{
        points = amount;
    }

    function createNewLottery(uint256 date) public onlyOwner { // date == lottery avaiable time from now (in minutes)
        require(finalDate[lotteryId] < block.timestamp); // Last Lottery has finished
        if(firstLottery == false){
            require(claimed[lotteryId] == true);
        } else {firstLottery = false;}
        lotteryId++; // New Lottery ID
        finalDate[lotteryId] = block.timestamp + (date*60); // This Lottery ID final date
        emit NewLotteryCreated(lotteryId);
    }

    function setTicketPrice(uint256 price) public onlyOwner{
        require(price > 0);
        ticketPrice = price;
    }

    function setBuyTicketLimit(uint8 limit) public onlyOwner{
        require(limit > 0);
        ticketLimit = limit;
    }
    
    uint8 public per = 10;
    uint256 public referrerProfit = ticketPrice/per;
    mapping(address => uint256) public earnedFromFees;

    function setReferrerProfit(uint8 _per) public onlyOwner{
        require(_per == 3 || _per == 5 || _per == 10 || _per == 15);
        if(_per == 3) { //3% for referrer
            per = 33;
        } else if(_per == 5){ //5% for referrer
            per = 20;
        } else if(_per == 10){ //10% for referrer
            per = 10;
        } else if(_per == 15){ //15% for referrer
            per = 7;
        }
    }

    function buyTickets(uint8[] calldata myTickets) public payable notPaused{
        require(block.timestamp < finalDate[lotteryId], "Lottery is closed");
        address referrer = ref.myReferrer(msg.sender);
        if(referrer != address(0)){
            require(msg.value == (ticketPrice * myTickets.length) + (referrerProfit * myTickets.length), "Send more ETH");
        } else {require(msg.value == ticketPrice * myTickets.length, "Send more ETH");}
        require(userTickets[lotteryId][msg.sender].length <= ticketLimit, "Maximum reached");
        if(hasParti[lotteryId][msg.sender] == false){
            participants[lotteryId].push(msg.sender);
            hasParti[lotteryId][msg.sender] = true;
        }
        for(uint8 i = 0; i < myTickets.length; i++){
            userTickets[lotteryId][msg.sender].push(myTickets[i]);
        }
        lotRandomVar = myTickets[0];
        if(referrer != address(0)){
        totalPrize += msg.value - (referrerProfit *  myTickets.length);
        earnedFromFees[referrer] += referrerProfit * myTickets.length;
        } else {totalPrize += msg.value;}
        uint16 pointsToAdd = points * uint16(myTickets.length);
        main.changePoints(1, pointsToAdd, true, msg.sender);
    }

    function referrerClaim() public {
        require(earnedFromFees[msg.sender] > 0);
        payable(msg.sender).transfer(earnedFromFees[msg.sender]);
        earnedFromFees[msg.sender] = 0;
    }

    mapping(address => uint256) public earnedInLottery;

    function sendPrizeToWinners() public onlyOwner notPaused{
        require(finalDate[lotteryId] < block.timestamp); // Lottery has finished
        require(claimed[lotteryId] == false);
        claimed[lotteryId] = true;
        uint256 winnerNumber = uint256(keccak256(abi.encodePacked(lotteryId, finalDate[lotteryId], lotRandomVar, participants[lotteryId].length))) % 100; // 0-99
        winnerTicket[lotteryId] = winnerNumber;
        uint256 partiNum = participants[lotteryId].length;
        for(uint32 i = 0; i < partiNum; i++){
            address partiAddress = participants[lotteryId][i];
            uint8[] memory ticketsToReview = userTickets[lotteryId][partiAddress];
            for(uint8 z = 0; z < ticketsToReview.length; z++){
                if(ticketsToReview[z] == winnerNumber){
                    winners[lotteryId].push(partiAddress);
                }
            }
        }
        uint256 multimodeFee = totalPrize/10;
        uint256 nextLotteryPrize = totalPrize/10;
        uint256 finalPrize = totalPrize - (multimodeFee + nextLotteryPrize);
        totalLastPrize = finalPrize;
        if(winners[lotteryId].length > 0){
            uint256 prizePerWinner = finalPrize / winners[lotteryId].length;
            for(uint32 u = 0; u < winners[lotteryId].length; u++){
                earnedInLottery[winners[lotteryId][u]] += prizePerWinner;
                totalPrize -= prizePerWinner;
            }
            prizePerWinnerMap[lotteryId] = prizePerWinner;
        }
        payable(treasury).transfer(multimodeFee);
        totalPrize -= multimodeFee;
        emit LotteryClosed(winnerNumber);
    }

    function claimLotteryPrize() public {
        require(earnedInLottery[msg.sender] > 0);  
        payable(msg.sender).transfer(earnedInLottery[msg.sender]);
        earnedInLottery[msg.sender] = 0;
    }

    function getMyPrize(address user) public view returns(uint256){
        return(earnedInLottery[user]);
    }

    function withdraw10() public onlyOwner{ // We can withdraw the nextLotteryPrize in case we want to Update the Lottery Contract
        require(finalDate[lotteryId] < block.timestamp);
        require(claimed[lotteryId]);
        payable(treasury).transfer(totalPrize);
        totalPrize = 0;
    }

    struct lastLotResult {
        uint256 winnerNumber;
        uint256 numberOfWinners;
        uint256 numberOfParticipants;
        uint8[] lastLotteryTickets;
        uint256 prizePerWinner;
    }
 
    function getLastLotteryInfo(address user) public view returns(lastLotResult memory){ // LAST lottery Info
        // RETURN : winnerNumber, winners[].length, participants[].length, yourTickets[], PrizePerWinner
        uint32 lastLottery = lotteryId-1;
        
        lastLotResult memory result;

        result.winnerNumber = winnerTicket[lastLottery];
        result.numberOfWinners = winners[lastLottery].length;
        result.numberOfParticipants = participants[lastLottery].length;
        result.lastLotteryTickets = userTickets[lastLottery][user];
        if(winners[lastLottery].length > 0){
            result.prizePerWinner = totalLastPrize / winners[lastLottery].length;
        } else { result.prizePerWinner = 0;}
        return(result);
    }

    struct lotteryResult{
        uint256 finalDate;
        uint256 ticketPrice;
        uint256 totalPrize;
        uint256 numberOfParticipants;
        uint8[] yourTickets;
        uint8 tickLimit;
    }

    function getThisLotteryInfo(address user) public view returns(lotteryResult memory){ // ACTUAL lottery Info
        // finalDate, ticketPrice, totalPrize, numParticipants, yourTickets, ticketLimit
        lotteryResult memory result;

        result.finalDate = finalDate[lotteryId];
        address referrer = ref.myReferrer(msg.sender);
        if(referrer != address(0)){
           result.ticketPrice = ticketPrice + referrerProfit;
        } else {result.ticketPrice = ticketPrice;}
        result.totalPrize = totalPrize - (totalPrize/10);
        result.numberOfParticipants = participants[lotteryId].length;
        result.yourTickets = userTickets[lotteryId][user];
        result.tickLimit = ticketLimit;
        return(result);
    }

    function addPrize() public payable {
        totalPrize += msg.value;
    }


    function getMyLastLotteries(address user) public view returns(uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory winnerNumbers = new uint256[](lotteryId);
        uint256[] memory yourPrize = new uint256[](lotteryId);
        uint256[] memory finalDates = new uint256[](lotteryId);
        for(uint32 i = 0; i < lotteryId; i++) {
            winnerNumbers[i] = winnerTicket[i];
            for(uint8 u = 0; u < userTickets[i][user].length; u++){
                if(winnerTicket[i] == userTickets[i][user][u]){
                    yourPrize[i] = prizePerWinnerMap[i];
                }
            }
            finalDates[i] = finalDate[i];
        
        }
        return(finalDates, winnerNumbers, yourPrize);
    }

    function getLastLotteryTickets(address user, uint32 id) public view returns(uint8[] memory){
        return(userTickets[id][user]);
    }

    function getLastLotteryId() public view returns(uint32) {
        return(lotteryId-1);
    }

    function getReferrerProfit(address user) public view returns(uint256) {
        return(earnedFromFees[user]);
    } 
       
}