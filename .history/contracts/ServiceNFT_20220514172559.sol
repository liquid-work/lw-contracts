// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {SuperLiquidWork} from "./liquidwork.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";

contract ServiceNFT is ERC721URIStorage {

    SuperLiquidWork public superLiquidWork; 

    event NFTMinted(uint256 _ServiceId);

    mapping(address => uint256) private ServicesCompleted;
    mapping(uint256 => bool) private isMinted;




}