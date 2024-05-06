contract mmSwap {

    IPancakeRouter01 public pancakeRouter;
    IKimRouter public kimRouter;
    MultiMode public main;
    address public owner;
    address treasury;

    constructor() {
        pancakeRouter = IPancakeRouter01(0xc1e624C810D297FD70eF53B0E08F44FABE468591);
        kimRouter = IKimRouter(0x5D61c537393cf21893BE619E36fC94cd73C77DD3);
        main = MultiMode(0x38c78C2924E9E95B6BaecF2341e092e8C9e8104A);
        owner = 0x43D86b9A4c67eEB59883Fd5b3628A640B1D630d2;
        treasury = 0x594DAebee354B140e1959ea6707c4E3B746936Ea;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    bool private locked;

    modifier nonReentrant{
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    address referrer = 0x43D86b9A4c67eEB59883Fd5b3628A640B1D630d2;
    uint256 mmFee = 10000000000000;
    bool completed;

    function setFee(uint256 fee) public onlyOwner{
        mmFee = fee;
    }

    function getFee() public view returns(uint256){
        return mmFee;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut
    ) public {
        uint256 amountKim = amountIn - ((amountIn*3)/10);
        uint256 amountSwap = amountIn - amountKim;
        uint256 minKim = amountOutMin - ((amountOutMin*3)/10);
        uint256 minSwap = amountOutMin - minKim;
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        _approveTokenIfNeeded(tokenIn, address(pancakeRouter), amountSwap);
        _approveTokenIfNeeded(tokenIn, address(kimRouter), amountKim);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        kimRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountKim, minKim, path, msg.sender, referrer, block.timestamp + 300);
        pancakeRouter.swapExactTokensForTokens(amountSwap, minSwap, path, msg.sender, block.timestamp + 300);
        completed = true;
    }

    function swapExactEthForTokens(
        uint256 amountOutMin,
        address tokenOut
        ) public payable{
            payable(treasury).transfer(mmFee);
            uint _value = msg.value - mmFee;
            address[] memory path = new address[](2);
            path[0] = pancakeRouter.WETH();
            path[1] = tokenOut;
            uint256 _valueKim = _value - ((_value*3)/10);
            uint256 _valueSwap = _value - _valueKim;
            uint256 minKim = amountOutMin - ((amountOutMin*3)/10);
            uint256 minSwap = amountOutMin - minKim;
            kimRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _valueKim}(minKim, path, msg.sender, address(0), block.timestamp + 300);
            pancakeRouter.swapExactETHForTokens{value: _valueSwap}(minSwap, path, msg.sender, block.timestamp + 300);
            completed = true;
    }

    function swapExactTokensForEth(uint256 amountIn, uint amountOutMin, address tokenIn) public {
        uint256 amountKim = amountIn - ((amountIn*3)/10);
        uint256 amountSwap = amountIn - amountKim;
        uint256 minKim = amountOutMin - ((amountOutMin*3)/10);
        uint256 minSwap = amountOutMin - minKim;
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        _approveTokenIfNeeded(tokenIn, address(pancakeRouter), amountSwap);
        _approveTokenIfNeeded(tokenIn, address(kimRouter), amountKim);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = pancakeRouter.WETH();
        kimRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountKim, minKim, path, msg.sender, referrer, block.timestamp + 300);
        pancakeRouter.swapExactTokensForETH(amountSwap, minSwap, path, msg.sender, block.timestamp + 300);
        completed = true;
    }

    function _approveTokenIfNeeded(address token, address spender, uint256 amount) private {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            IERC20(token).approve(spender, amount);
        }
    }

    struct Tx {
        address tokenIn;
        string tokenFrom;
        address tokenOut;
        uint8 decimalsIn;
        uint8 decimalsOut;
        string tokenTo;
        uint256 amountIn;
        uint256 amountOut;
        uint256 date;
    }

    Tx[] public txs;

    mapping(address => Tx[]) public userSwaps;
    mapping(address => uint32) public nSwaps;
    uint32 public totalSwaps;
    event swapStatus(string swapMsg, bool _completed);

    function swap(
        string memory tickerIn, 
        string memory tickerOut, 
        uint256 amountIn, 
        uint amountOutMin, 
        address tokenIn, 
        address tokenOut
        ) public payable nonReentrant{
            bytes32 t0 = keccak256(abi.encodePacked(tickerIn));
            bytes32 t1 = keccak256(abi.encodePacked(tickerOut));
            bytes32 _eth = keccak256(abi.encodePacked("ETH"));
            if(t0 == _eth){
                require(msg.value > mmFee, "send more Ether");
                swapExactEthForTokens(amountOutMin, tokenOut);
                main.addVolume(amountIn, msg.sender);
            } else if(t0 != _eth && t1 != _eth){
                require(msg.value == mmFee, "send more Ether");
                payable(treasury).transfer(mmFee);
                swapExactTokensForTokens(amountIn, amountOutMin, tokenIn, tokenOut);
                address[] memory path = new address[](3);
                path[0] = tokenIn;
                path[1] = 0x4200000000000000000000000000000000000006;
                path[2] = tokenOut;
                uint256 amountInEth = kimRouter.getAmountsOut(amountIn, path)[1];
                main.addVolume(amountInEth, msg.sender);
            } else if(t0 != _eth && t1 == _eth){
                require(msg.value == mmFee, "send more Ether");
                payable(treasury).transfer(mmFee);
                swapExactTokensForEth(amountIn, amountOutMin, tokenIn);
                main.addVolume(amountOutMin, msg.sender);
            }
            addTx(msg.sender, tickerIn, tickerOut, amountIn, getAmountsOut(amountIn, tokenIn, tokenOut), tokenIn, tokenOut, block.timestamp);
            main.changePoints(1, 50, true, msg.sender);
            emit swapStatus("Swap Status", completed);
            completed = false;
    }

    function addTx(
        address user,
        string memory tickerIn, 
        string memory tickerOut, 
        uint256 amountIn, 
        uint amountOut, 
        address tokenIn, 
        address tokenOut,
        uint256 date
        ) internal {
            Tx memory newTx;
            newTx.tokenFrom = tickerIn;
            newTx.tokenTo = tickerOut;
            newTx.amountIn = amountIn;
            newTx.amountOut = amountOut;
            newTx.tokenIn = tokenIn;
            newTx.tokenOut = tokenOut;
            newTx.date = date;
            newTx.decimalsIn = IERC20Dec(tokenIn).decimals();
            newTx.decimalsOut = IERC20Dec(tokenOut).decimals();
            nSwaps[user]++;
            totalSwaps++;
            userSwaps[user].push(newTx);
    }

    function getAmountsOut(uint amountIn, address tokenIn, address tokenOut) public view returns (uint256) {
        address _eth = 0x4200000000000000000000000000000000000006;
        if(tokenIn == _eth || tokenOut == _eth){
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            uint256 amountKim = amountIn - ((amountIn*3)/10);
            uint256 amountSwap = amountIn - amountKim;
            uint256 amountOutKim = kimRouter.getAmountsOut(amountKim, path)[1];
            uint256 amountOutSwap = pancakeRouter.getAmountsOut(amountSwap, path)[1];
            uint256 amountsOut = amountOutKim + amountOutSwap;
            return amountsOut;
        } else{
            address[] memory path = new address[](3);
            path[0] = tokenIn;
            path[1] = _eth;
            path[2] = tokenOut;
            uint256 amountKim = amountIn - ((amountIn*3)/10);
            uint256 amountSwap = amountIn - amountKim;
            uint256 amountOutKim = kimRouter.getAmountsOut(amountKim, path)[2];
            uint256 amountOutSwap = pancakeRouter.getAmountsOut(amountSwap, path)[2];
            uint256 amountsOut = amountOutKim + amountOutSwap;
            return amountsOut;
        }
    }

    function getUserSwaps(address user) public view returns(Tx[] memory){
        return userSwaps[user];
    }

    function getNumberOfSwaps(address user) public view returns(uint32){
        return nSwaps[user];
    }

    function getTotalSwaps() public view returns(uint32){
        return totalSwaps;
    }

}
