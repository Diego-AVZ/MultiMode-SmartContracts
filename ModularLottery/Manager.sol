//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./modularLottery.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Referral.sol";

contract LotteryManager {
    
    address public owner;
    ReferralProgram public ref;
    MultiMode public main;
    uint256[] public avaiableLotteries;

    constructor(address _owner, address _ref){
        owner = _owner;
        ref = ReferralProgram(_ref);
        main = MultiMode(0xA6f4F93cE7bd60326F39FE34C1bD2440a3Bd2Cf0);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Sender != owner");
        _;
    }

    bool public isLocked;

    modifier nonReentrancy(){
        require(!isLocked, "ReentrancyGuard");
        isLocked = true;
        _;
        isLocked = false;
    }

    struct LotteryData{ 
        address token;
        uint prize;
        int8 loops;
        uint8 _type;
        address creator;
        address contractAddr;
        uint256 ticketPrice;
        uint256 Id;
        uint16 subId;
        string _ticker;
        uint currentPrize;
    }

    function getLotteries() public view returns(uint256[] memory){
        return avaiableLotteries;
    }

    uint256 public lotteryId = 1;
    mapping(uint256 => LotteryData) public lotteryMap;
    mapping(uint256 => address) public lotteryAddresses;

    function getData(uint id) public view returns(LotteryData memory){
        return lotteryMap[id];
    }
    
    function createLottery(
            address token, 
            uint amount, 
            uint8 loops, 
            uint8 _type, 
            uint256 ticketPrice, 
            address newLottery,
            address user,
            string calldata _ticker
        ) public {
        require(ticketPrice > minTicketPrice, "Must be more expensive");
        LotteryData memory data = LotteryData(token,amount,int8(loops),_type,user,newLottery,ticketPrice,lotteryId,0,_ticker,amount/loops);
        lotteryMap[lotteryId] = data;
        lotteryAddresses[lotteryId] = newLottery;
        avaiableLotteries.push(lotteryId);
        lotteryId++;
    }

    function openLotteries(uint lotDuration) internal {
        uint256[] memory toRemove = new uint256[](avaiableLotteries.length);
        uint256 numToRemove = 0;
        for(uint i = 0; i < avaiableLotteries.length; i++){
            uint256 id = avaiableLotteries[i];
            address lotAdd = lotteryAddresses[id];
            if(lotteryMap[id].loops > 0){
                ModularLottery(lotAdd).openNewLotteries(lotDuration);
                lotteryMap[id].loops--;
                lotteryMap[id].subId++;
            } else if(lotteryMap[id].loops == 0){
                lotteryMap[id].loops--;
            } else {
                toRemove[numToRemove] = i;
                numToRemove++;
            }
        }
        for (uint256 j = 0; j < numToRemove; j++) {
            uint256 indexToRemove = toRemove[j] - j; 
            for (uint256 z = indexToRemove; z < avaiableLotteries.length - 1; z++){
                avaiableLotteries[z] = avaiableLotteries[z + 1];
            }
            avaiableLotteries.pop();
        }
    }

    mapping(address => mapping(uint => mapping(uint => bool))) public isInSubId;
    mapping(address => mapping(uint256 => Tickets[])) userTickets;
    mapping(address => mapping(uint => mapping(uint16 => uint32))) timesPlayedSubId;  

    function buyTickets(uint32[] calldata myTickets, uint256 id) public payable nonReentrancy{
        uint ticketPrice = lotteryMap[id].ticketPrice;
        require(msg.value == myTickets.length * ticketPrice);
        address r = ref.myReferrer(msg.sender);
        uint x;
        uint y;
        uint z;
        if(r == address(0)){
            x = (msg.value*85)/100;
            y = msg.value/20;
            z = msg.value/10;
        } else{
            x = (msg.value*80)/100;
            y = msg.value/20;
            z = msg.value/10;
            payable(r).transfer(y);
        }
        
        payable(lotteryMap[id].creator).transfer(x);
        payable(0xAA87a33BFa6BccFb4263324018604655da0433C1).transfer(z);
        payable(0xF1eb6B5a776Fc644Ed914bB8d1FB916B54cca603).transfer(y);
        address toContract = lotteryMap[id].contractAddr;
        ModularLottery(toContract).buyTickets(myTickets, msg.sender);
        isInSubId[msg.sender][id][lotteryMap[id].subId] = true;
        if(timesPlayedSubId[msg.sender][id][lotteryMap[id].subId] == 0){ 
            participations[msg.sender].push(id);
            timesPlayedSubId[msg.sender][id][lotteryMap[id].subId]++;
        }
    }

    struct userPrize{
        string ticker;
        address token;
        uint amount;
        uint id;
        uint subId;
    }
    
    mapping(address => userPrize[]) public userPrizes;

    function sendPrizeToWinners(uint duration) public onlyOwner nonReentrancy{
        for(uint i = 0; i < avaiableLotteries.length; i++){
            uint id = avaiableLotteries[i];
            address lotAddr = lotteryAddresses[id]; 
            if(lotteryMap[id].loops >= 0 && lotteryMap[id].subId > 0){
                ModularLottery(lotAddr).sendPrizeToWinners(id);
            } 
            if(lotteryMap[id].loops != 0){
                lotteryMap[id].currentPrize= lotteryMap[id].prize / uint8(lotteryMap[id].loops);
            } else {
                lotteryMap[id].currentPrize= lotteryMap[id].prize / 1;
            }
        }
        openLotteries(duration);
    }

    function sendUserPrizes(address user, uint amount, address token, string calldata tick, bool returnPrize, uint id, uint subId) external {
        require(msg.sender == lotteryAddresses[id]);
        if(returnPrize){  
            uint x = lotteryMap[id].prize;
            lotteryMap[id].prize = 0;
            lotteryMap[id].currentPrize = 0;
            IERC20(token).transfer(lotteryMap[id].creator, x);
        } else if(!returnPrize && token != address(0)){ 
            lotteryMap[id].prize -= amount;
            lotteryMap[id].currentPrize -= amount;
            userPrize memory prize = userPrize(tick, token, amount, id, subId);
            userPrizes[user].push(prize);
        } else{
            lotteryMap[id].currentPrize += amount;
        }
    }

    function claimPrize() public nonReentrancy{
        uint len = userPrizes[msg.sender].length;
        for(uint i = 0; i < len; i++){
            address token = userPrizes[msg.sender][i].token;
            uint amount = userPrizes[msg.sender][i].amount;
            userPrizes[msg.sender][i].amount = 0;   
            IERC20(token).transfer(msg.sender, amount);
            ModularLottery(lotteryAddresses[userPrizes[msg.sender][i].id]).setClaimed(msg.sender,userPrizes[msg.sender][i].subId);
        }
        delete userPrizes[msg.sender];
    }

    function getUserPrizes(address user) public view returns(userPrize[] memory){
        return(userPrizes[user]);
    }
/*
    function deleteLottery(uint id) public {
        require(msg.sender == lotteryMap[id].creator || msg.sender == owner, "You can not Delete this Lottery");
        require(lotteryMap[id].subId == 0);
        for(uint i = 0; i < avaiableLotteries.length; i++){
            if(avaiableLotteries[i] == id){
                avaiableLotteries[i] = avaiableLotteries[avaiableLotteries.length-1];
                avaiableLotteries.pop();
                address token = lotteryMap[id].token;
                address creator = lotteryMap[id].creator;
                uint amount = lotteryMap[id].prize;
                lotteryMap[id].prize = 0;
                IERC20(token).transfer(creator, amount);
                return;
            }
        }
    }
*/
        // History

    function getIds(address user) public view returns(uint256[] memory){
        uint len = participations[user].length;
        uint256[] memory ids = new uint256[](len);
        for(uint i = 0; i < len; i++){
            ids[i] = participations[user][i];
        }
        return(ids);
    }

    function getPrizes(address user) public view returns(Prizes[] memory){
        uint len = participations[user].length;
        Prizes[] memory prizes = new Prizes[](len);
        for(uint i = 0; i < len; i++){
            uint id = participations[user][i];
            uint timesId = 0;
            for(uint j = 0; j < i; j++){
                if(id == participations[user][j]){
                    timesId++;
                }
            }
            prizes[i] = getIdPrizes(user, id)[timesId];
        }
        return prizes;
    }

    function getIdPrizes(address user, uint id) public view returns(Prizes[] memory){
        address lotAddr = lotteryAddresses[id];
        uint len = ModularLottery(lotAddr).getParticipations(user).length;
        Prizes[] memory temporalPrizes = new Prizes[](len);
        for(uint i = 0; i < len; i++){
            (uint256[] memory amounts, address token, string memory ticker, bool[] memory isClaimed) = ModularLottery(lotAddr).getMyLastPrizes(user);
            temporalPrizes[i] = Prizes({
                amount: amounts[i],
                token: token,
                ticker: ticker,
                isClaimed: isClaimed[i]
            });
        }
        return temporalPrizes;
    }

    function getTickets(address user) public view returns(Tickets[] memory){
        uint len = participations[user].length;
        Tickets[] memory tickets = new Tickets[](len);
        for(uint i = 0; i < len; i++){
            uint id = participations[user][i]; 
            address lotAddr = lotteryAddresses[id]; 
            uint256 timesId = 1;
            for(uint j = 0; j < i; j++){
                if(id == participations[user][j]){
                    timesId++;
                }
            }
            uint subId = 1;
            for(uint u = 1; u < timesId+1; u++){
                if(isInSubId[user][id][subId] == true){
                    uint ticketsLen = ModularLottery(lotAddr).getLotteryTickets(user, subId).length;
                    tickets[i].tickets = new uint32[](ticketsLen);
                    for(uint k = 0; k < ticketsLen; k++){
                        tickets[i].tickets[k] = ModularLottery(lotAddr).getLotteryTickets(user, subId)[k];
                    }
                    subId++;
                } else {
                    subId++;
                    u--;
                }
            }
        }
        return tickets;
    } 

    function getFinalDates(address user) public view returns(uint[] memory){
        uint len = participations[user].length;
        uint[] memory finalDates = new uint[](len);
        for(uint i = 0; i < len; i++){
            uint id = participations[user][i];
            address lotAddr = lotteryAddresses[id];
            uint32 timesId = 1;
            for(uint j = 0; j < i; j++){
                if(id == participations[user][j]){
                    timesId++;
                }
            }
            finalDates[i] = ModularLottery(lotAddr).finalDate(timesId);
        }
        return finalDates;
    }

    function getWinnerNumbers(address user) public view returns(uint256[] memory){
        uint len = participations[user].length;
        uint256[] memory winnerNumbers = new uint256[](len);
        for(uint i = 0; i < len; i++){
            uint id = participations[user][i];
            address lotAddr = lotteryAddresses[id];
            uint256 timesId = 0;
            for(uint j = 0; j < i; j++){
                if(id == participations[user][j]){
                    timesId++;
                }
            }
            winnerNumbers[i] = ModularLottery(lotAddr).getWinnerNumber(user)[timesId];
        }
        return winnerNumbers;
    }

    struct Prizes {
        string ticker;
        address token;
        uint256 amount;
        bool isClaimed;
    }

    struct Tickets {
        uint32[] tickets;
        uint optional;
    }
    
    mapping(address => uint256[]) public participations;

    struct ParticipationsData {
        uint256 ids;
        Prizes userPrizes;
        Tickets tickets;
        uint256 finalDates;
        uint256 winnerNumber;
    }

    mapping(address => ParticipationsData[]) public History;

    function getUserHistory(address user) public view returns(ParticipationsData[] memory){
        uint len = participations[user].length;
        ParticipationsData[] memory history = new ParticipationsData[](len); 
        for(uint i = 0; i < len; i++){
            history[i].ids = getIds(user)[i];
            history[i].userPrizes = getPrizes(user)[i];
            history[i].tickets = getTickets(user)[i];
            history[i].finalDates = getFinalDates(user)[i];
            history[i].winnerNumber = getWinnerNumbers(user)[i];
        }
        return history;
    }

    uint256 minTicketPrice;

    function setMinTicketPrice(uint256 price) public onlyOwner{
        minTicketPrice = price;
    }
}
