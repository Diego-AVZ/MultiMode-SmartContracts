//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MainLotteryControler.sol";

contract GetLotteriesData {

    LotteryManager public manager;
    MultiMode public main;

    constructor(address _manager){
        manager = LotteryManager(_manager);
        main = MultiMode(0xA6f4F93cE7bd60326F39FE34C1bD2440a3Bd2Cf0);
    }

    struct CurrentLotteryUniversalResult {
        address token;
        uint256 finalDate;
        uint256 ticketPrice;
        string ticker;
        uint256 totalPrize;
        uint256 numberOfParticipants;
        uint32[] userTickets;
        uint8 ticketsLimit;
        uint16 subId;
        int8 loopsLeft;
        uint32 optionalUint;
        uint32[] optionalUintArray;
        bool optionalBool;
        string optionalString;
    }

    function getCurrentLotteryInfo(uint256 id, address user) public view returns(CurrentLotteryUniversalResult memory){
        address lotAddr = manager.lotteryAddresses(id);
        CurrentLotteryUniversalResult memory result;
        result.token = manager.getData(id).token;
        result.ticker = manager.getData(id)._ticker;
        result.finalDate = ModularLottery(lotAddr).getThisLotteryInfo(user).finalDate;
        result.ticketPrice = ModularLottery(lotAddr).getThisLotteryInfo(user).ticketPrice;
        result.totalPrize = manager.getData(id).currentPrize; 
        result.numberOfParticipants = ModularLottery(lotAddr).getThisLotteryInfo(user).numberOfParticipants;
        result.userTickets = ModularLottery(lotAddr).getThisLotteryInfo(user).yourTickets;
        result.ticketsLimit = ModularLottery(lotAddr).getThisLotteryInfo(user).tickLimit;
        result.subId = manager.getData(id).subId;
        result.loopsLeft = manager.getData(id).loops;
        return(result);
    }

    struct LastLotterryResult{
        uint256 winnerNumber;
        uint256 numberOfWinners;
        uint256 numberOfParticipants;
        uint32[] lastLotteryTickets;
        uint256 prizePerWinner;
        uint32 optionalUint;
        uint32[] optionalUintArray;
        bool optionalBool;
        string optionalString;
    }

    function getLastLotteryInfo(uint256 id, address user) public view returns(LastLotterryResult memory){
        address lotAddr = manager.lotteryAddresses(id);
        LastLotterryResult memory result;
        result.winnerNumber = ModularLottery(lotAddr).getLastLotteryInfo(user).winnerNumber;
        result.numberOfWinners = ModularLottery(lotAddr).getLastLotteryInfo(user).numberOfWinners;
        result.numberOfParticipants = ModularLottery(lotAddr).getLastLotteryInfo(user).numberOfParticipants;
        result.lastLotteryTickets = ModularLottery(lotAddr).getLastLotteryInfo(user).lastLotteryTickets;
        result.prizePerWinner = ModularLottery(lotAddr).getLastLotteryInfo(user).prizePerWinner;
        result.optionalUint = ModularLottery(lotAddr).getLastLotteryInfo(user).optionalUint;
        result.optionalUintArray = ModularLottery(lotAddr).getLastLotteryInfo(user).optionalUintArray;
        result.optionalBool = ModularLottery(lotAddr).getLastLotteryInfo(user).optionalBool;
        result.optionalString = ModularLottery(lotAddr).getLastLotteryInfo(user).optionalString;
        return(result);
    }

}
