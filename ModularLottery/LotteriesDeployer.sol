//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainLotteryControler.sol";
import "./modularLottery.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LotteryDeployer {

    LotteryManager public manager;
    address public owner;

    constructor(address _owner, address _manager){
        manager = LotteryManager(_manager);
        owner = _owner;
    }
    
    bool public isLocked;

    modifier nonReentrancy(){
        require(!isLocked, "ReentrancyGuard");
        isLocked = true;
        _;
        isLocked = false;
    }

    function createLottery(
        string memory _ticker,
        address token,
        uint amount,
        uint8 loops, 
        uint8 _type, 
        uint256 ticketPrice
    ) public payable nonReentrancy{
        require(msg.value == createLotteryPrice);
        require(IERC20(token).allowance(msg.sender, address(this))>=amount);
        payable(0x43D86b9A4c67eEB59883Fd5b3628A640B1D630d2).transfer(msg.value);
        IERC20(token).transferFrom(msg.sender, address(manager), amount);
        ModularLottery _lot = new ModularLottery(owner, address(manager), token, _ticker, ticketPrice, amount, loops);
        manager.createLottery(token,amount,loops,_type,ticketPrice,address(_lot),msg.sender,_ticker);
    }

    uint createLotteryPrice = 1000000000000000;

    function getCreateLotteryPrice() public view returns(uint){
        return createLotteryPrice;
    }

    function setCreateLotteryPrice(uint price) public{
        createLotteryPrice = price;
    }
}
