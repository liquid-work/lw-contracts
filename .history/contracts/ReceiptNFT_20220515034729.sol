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

    modifier OnlyDepositor{
        require(SuperLiquidWork.depositors[msg.sender] != address(0))
    };

    //@notice Depositor can get his receipt as NFT minted 
    function getNFT(address client, string memory tokenURI) public returns (uint256) onlyDepositor {
        require(SuperLiquidWork.status == SuperLiquidWork.ServiceStatus.FINISHED);
        uint256 newServiceId = _tokenIds.current();
        _mint(client, newServiceId);
        _setTokenURI(newServiceId, tokenURI);
        _tokenIds.increment();
        return newServiceId;
    }
}

