// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {SuperLiquidWork} from "./LiquidWorkManagement.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";

contract ServiceNFT is ERC721URIStorage {

    SuperLiquidWork public superLiquidWork; 

    // Rendering event if NFT is minted for a Service after estimated 
    event NFTMinted(uint256 _ServiceId);

    mapping(address => uint256) private ServicesCompleted;
    mapping(uint256 => bool) private isMinted;


    constructor(
        string memory _name,
        string memory _symbol,
        uint256  _estimate,
        SuperLiquidWork superLiquidWork
    ) ERC721 (_name, _symbol, estimate) {
        superLiquidWork = _superLiquidWork;

    }

    /**************************************************************************
     * NFT Minting/Updating Logic
    *************************************************************************/
    /*
    struct Service {
        string name; 
        string description; 
        uint256 serviceId;
        address sender; //LiquidWork Address 
        address receiver; // User 
        ServiceStatus status;
        int96 flowRate;
        uint256 expirationDate; // expiration date in seconds since 1970 
        uint256 totalAmountStreamed; // total amount streamed by user calculated after each update to stream, to distribute money at the end
    }
    */

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //ERC721 to track Services in our LiquidWork, which have their own attributes. 
    // When one is mapped to a user it will be minted and sent to him. 
    function getNFT(address client, string memory tokenURI) public returns (uint256) only {
        uint256 newServiceId = _tokenIds.current();
        _mint(client, newServiceId);
        _setTokenURI(newServiceId, tokenURI);
        _tokenIds.increment();
        return newServiceId;
    }


}