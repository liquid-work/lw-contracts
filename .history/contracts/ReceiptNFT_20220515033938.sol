// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {SuperLiquidWork} from "./LiquidWorkManagement.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";

contract ServiceNFT is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    modifier OnlyConsumer{
        require(depositors.address != address(0))
    }

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