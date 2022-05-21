// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract NFTExp is ChainlinkClient, ERC721 {
    using Chainlink for Chainlink.Request;
    //using SafeMath for uint256; 


    bytes32 public timeStarted; 
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    event ExperienceFinished(bytes32 firstName, bytes32 lastName, uint256 TimeLeft);


    struct Status{
        uint256 one; //started 
        uint256 two; //finished 
    }

    struct Experience{
        Status status; 
        string review;

    }

    Experience[] public experiences;

    mapping(bytes32 => uint256) requestToTokenId; 
    mapping(bytes32 => bytes32) requestToNewTime; 
    mapping(bytes32 => address) requestToSender;
    bytes32 public requestId; 
 


    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel   
     * Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    constructor() ERC721("Experience", "EX") {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestAPI() public 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        // Set the URL to perform the GET request on
        request.add("get", "http://worldtimeapi.org/api/timezone/America/New_York");
        
        // Set the path to find the desired data in the API response, where the response format is:
    
        request.add("path", "unixtime"); // add a nested path 
        
        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);
        
        // Sends the request
        sendChainlinkRequestTo(oracle, request, fee);
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        setTokenURI(tokenId, _tokenURI);
    }

   
    /**
     * Callback function
     */
    function fulfill(bytes32 requestId, bytes32 _timeStarted) public recordChainlinkFulfillment(requestId)
    {
        timeStarted = _timeStarted; 
        uint256 newId = experiences.length; 
        _safeMint(requestToSender[requestId], newId);

    }

    function requestNewTime(string memory _newTime) public returns (bytes32) {
        //require(LINK.balanceOf(address(this) >= fee, "Not enought LINK - fill contract with faucet"));
       // bytes32 requestId = requestAPI(_time);
       // requestToNewTime[requestId] = requestId + timeStarted; // TimeSpent 
       // return requestToNewTime;
    }

    // function getUser(uint256 _index) external view returns (uint32, string memory, string memory, uint32, bool) {
    //     (uint32 decodedId, string memory decodedFirstName, string memory decodedLastName, uint32 decodedTimeLeft, bool decodedIsExpired ) = 
    //         abi.decode(users[_index], (uint32, string, string, uint32, bool)); 
    //     return (decodedId, decodedFirstName, decodedLastName, decodedTimeLeft, decodedIsExpired);
    // }
    
}



