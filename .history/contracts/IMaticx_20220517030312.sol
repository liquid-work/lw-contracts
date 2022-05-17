//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMATICx {
    function upgradeByETH() external payable;
}


// Should be fixed 
abstract contract UpgradeMATIC is IMATICx { 

    address  MATICx = 0x96B82B65ACF7072eFEb00502F45757F254c2a0D4;

    IMATICx obj ; 

    function upgradeMatic(uint256 _amount) external {
        obj.upgradeByETH();
    }
}
