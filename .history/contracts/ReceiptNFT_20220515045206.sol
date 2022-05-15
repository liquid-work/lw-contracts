// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {SuperLiquidWork} from "./LiquidWorkManagement.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

abstract contract ServiceNFT is ERC721URIStorage {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    SuperLiquidWork public superLiquidWork ; 

    constructor(SuperLiquidWork _superLiquidWork){
        superLiquidWork = _superLiquidWork;
            
    }

    modifier OnlyDepositor(uint256 _depositorId) {
        _;
    }

    //@notice Depositor can get his receipt as NFT minted 
    function getNFT(address client, string memory tokenURI, uint256 _depositorId) public returns (uint256) {
        require(superLiquidWork.depositors(_depositorId) != address(0));
        // Depositor gets his NFT at the end 
        require(superLiquidWork.status() == SuperLiquidWork.ServiceStatus.FINISHED);
        uint256 newServiceId = _tokenIds.current();
        _mint(client, newServiceId);
        _setTokenURI(newServiceId, tokenURI);
        _tokenIds.increment();
        return newServiceId;
    }
}

