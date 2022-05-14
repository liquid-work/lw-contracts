// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {SuperLiquidWork} from "./liquidwork.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";

contract ServiceNFT is ERC721URIStorage {

    SuperLiquidWork public superLiquidWork; 

    // Rendering event if NFT is minted for a Service after estimated 
    event NFTMinted(uint256 _ServiceId);

    // Checks 
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






}