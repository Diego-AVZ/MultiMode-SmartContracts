//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./MainMultiMode.sol";

contract DeployerAndMinter{ 

    MultiMode public main;
    address public treasury;
    MultiModeNfts public newNft;
    string public nftName;
    string public nftUrl;
    string public rarity;
    uint32 maxSupply;
    uint256 nftTotalCount;
    uint256 contractsTotalCount;
    address public owner;

    constructor(address multimode, address _treasury, address _owner){
        main = MultiMode(multimode);
        treasury = _treasury; 
        owner = _owner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function setNft(address nftContract, string memory _nftName, string memory _nftUrl, uint32 _maxSupply, string memory _rarity) public onlyOwner{
        newNft = MultiModeNfts(nftContract);
        nftName = _nftName;
        nftUrl = _nftUrl;
        maxSupply = _maxSupply;
        tokenId = 0;
        rarity = _rarity;
    }

    uint256 public deployPrice = 150000000000000;
    uint256 public mintPrice = 150000000000000;

    function setPrices(uint256 priceMint, uint256 priceDeploy) public onlyOwner{
        mintPrice = priceMint;
        deployPrice = priceDeploy;
    }

    mapping(address => bool) isDeployed;

    function permitAddressAndAddPoints(address newContract, address user) public payable  {
        require(!isDeployed[newContract]);
        require(msg.value >= deployPrice);
        payable(treasury).transfer(msg.value); 
        changePoints(user);
        isDeployed[newContract] = true;
    }
 
    mapping(address => uint16) public contractsDeployed;
    mapping(address => uint16) public nftsMinted;
    uint256 tokenId;
    uint256 contractId;

    function addContractsToUser(address user) public {
        contractsDeployed[user]++;
        contractsTotalCount++;
    }

    mapping(address => string[]) userNftNames;
    mapping(address => string[]) userNftUrls;
    mapping(address => string[]) userNftRarities;
    mapping(address => uint256[]) userNftIds;
    mapping(address => uint256[]) userNftPrices;
    mapping(address => uint32[]) userNftMaxSupply;

    function mint() public payable {
        require(tokenId <= maxSupply);
        require(msg.value >= mintPrice);
        payable(treasury).transfer(msg.value);
        newNft.mint(msg.sender, tokenId);  
        userNftIds[msg.sender].push(tokenId);
        changePoints(msg.sender);
        nftsMinted[msg.sender]++;
        userNftNames[msg.sender].push(nftName);
        userNftUrls[msg.sender].push(nftUrl);
        userNftRarities[msg.sender].push(rarity);
        userNftPrices[msg.sender].push(mintPrice);
        userNftMaxSupply[msg.sender].push(maxSupply);
        tokenId++;
        nftTotalCount++;
    }

    uint16 points = 50;

    function setPoints(uint16 _points) public onlyOwner{
        points = _points;
    }

    function changePoints(address user) private {
        main.changePoints(1, points, true, user);
    }

    function getDeployPrice() public view returns(uint256) {
        return(deployPrice);
    } 

     function getMintPrice() public view returns(uint256) {
        return(mintPrice);
    } 

    function getMintedNfts(address user) public view returns(uint16){
        return(nftsMinted[user]);
    }
    
    function getDeployedContracts(address user) public view returns(uint16){
        return(contractsDeployed[user]);
    }

    function getTotalMinted() public view returns(uint256){
        return(nftTotalCount);
    }

    function getTotalDeployed() public view returns(uint256){
        return(contractId);
    }

    function getUserNftData(address user) public view returns(string[] memory, string[] memory, uint256[] memory, string[] memory, uint256[] memory, uint32[] memory){
        return(userNftNames[user], userNftUrls[user], userNftIds[user], userNftRarities[user], userNftPrices[user], userNftMaxSupply[user]);
    }

    struct currentNftSale{
        uint256 id;
        string name;
        string url;
        uint256 maxTokens;
        string rarity;
        uint256 price;
    }

    function getCurrentNftSale() public view returns(currentNftSale memory) {
        currentNftSale memory result;
        result.id = tokenId;
        result.name = nftName;
        result.url = nftUrl;
        result.maxTokens = maxSupply;
        result.rarity = rarity;
        result.price = mintPrice;
        return result;
    }
}

contract contractToDeploy {

    address public deployerUser;
    DeployerAndMinter public deployer;
    address public treasury;
    address thisContract;

    constructor(address user) payable{ 
        thisContract = address(this);
        treasury = 0x594DAebee354B140e1959ea6707c4E3B746936Ea;
        deployer = DeployerAndMinter(0x1d4A1F29250c48aA71482E5DeC8C30722F86F3DF);
        require(msg.value >= deployer.getDeployPrice());
        deployer.permitAddressAndAddPoints{value: msg.value}(thisContract, user);
        deployerUser = user;
        deployer.addContractsToUser(user);
    }
}


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MultiModeNfts is ERC721 {
    constructor() ERC721("MultiModeEarlyNFT", "EarlyMultiMode") {}

    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}

// https://pbs.twimg.com/profile_images/1710206028787093504/5hgtWHJl_400x400.jpg

contract MultiModeID is ERC721 {

    MultiMode public main;

    struct nftData {
        string name;
        string uri;
        uint256 tokenId;
    }

    mapping(uint256 => nftData) public data;
    mapping(address => nftData) public idData;

    constructor(address _main) ERC721("MultiModeID", "MM.ID") {
        main = MultiMode(_main);
    }

    uint256 public tokenId;
    string[] names;
    mapping(uint256 => string) public _tokenURIs;
    mapping(string => address) public addressId;

    function mint(string memory name, string memory uri) public payable {
        require(!nameControl(name));
        require(msg.value == 275000000000000);
        _mint(msg.sender, tokenId);
        _setTokenMetadata(msg.sender, tokenId, name, uri);
        _tokenURIs[tokenId] = uri;
        tokenId++;
        main.changePoints(1, 350, true, msg.sender);
    }

    function _setTokenMetadata(address user, uint256 _tokenId, string memory name, string memory uri) internal {
        data[_tokenId] = nftData(name, uri, tokenId);
        idData[user] =  nftData(name, uri, tokenId);
        names.push(name);
    }

    function nameControl(string memory name) public view returns(bool){
        bool isRegistered;
        for(uint256 i = 0; i < names.length; i++){
            if(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(names[i]))){
                isRegistered = true;
            }
        }
        return(isRegistered);
    } 

    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        return data[_tokenId].uri;
    }

    function tokenURI(uint256 _tokenId) public view override  returns (string memory) {
        return _tokenURIs[_tokenId];
    }

    function getAddressFromId(string memory name) public view returns(address){
        return(addressId[name]);
    }
}




