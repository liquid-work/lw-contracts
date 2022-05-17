// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//LiquidWork = middleman
// User interacts with LiquidWork not Superfluid
// LiquidWork interacts with Superfluid

import "@openzeppelin/contracts/access/Ownable.sol";
import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, ContextDefinitions, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IMATICx} from "./IMATICx.sol";

contract SuperLiquidWork is SuperAppBase {

    ISuperfluid private host; 
    IConstantFlowAgreementV1 private cfa; 
    ISuperToken private acceptedToken; 

    address liquidwork = 0x839B878873998F02cE2f5c6D78d1B0842e58F192; 
    address  MATICx = 0x96B82B65ACF7072eFEb00502F45757F254c2a0D4;

    address[] public users;
    address owner;

    uint256 constant day = 3600 * 24; 
    uint256 constant month = day * 30; 
    uint256 constant year = month * 12; 

    struct Stream {
        bool active;
        bytes ctx;
        uint256 rate;
    }

    event ServiceCreated(address _sender, int96 _flowRate);
    event streamStoped(uint256 _serviceId);
    event streamStarted(uint256 _serviceId);
    event noFunds(uint256 _serviceId);

    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal priceFeed2;

    constructor(
        ISuperfluid _host,
        IConstantFlowAgreementV1 _cfa,
        ISuperToken _acceptedToken,
        address matic
    ) {
        owner = msg.sender;
        host = _host;
        cfa = _cfa;
        acceptedToken = _acceptedToken; 
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);  //MATIC/USD address 
        priceFeed2 = AggregatorV3Interface(0xe699a85EA83Adad57F3510be8AcD9d37f9e9B5d4) ;  // MATIC/ETH

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP; //Not using Before_Agreement callback

        host.registerApp(configWord);
    }

    /**************************************************************************
     * Superfluid Money Management Logic
    *************************************************************************/

    function initInstance(
        address _sender,
        uint256 _estimate,
        uint256 timestamp
    ) external {
        require(_sender != address(0), "Enter a valid address");
        users.push(_sender);
        uint rate = uint(getLatestPrice()); // getting price of USD IN MATIC. 
        uint realRate = _estimate * rate ; // getting price estimate in MATIC. 
        uint MaticBywei = uint(getLatestPrice()) * realRate ; 
        // TODO : code to wrap MATIC to MATICx
        // TODO : make a call on agreement to start a stream with realRate / (day / month / year) [definded constants]


        // transform usd-matic
        // transform matic to wei
        // divide wei/(timestamp*1000) -> flowrate
        // start stream use cfa
    }

    function removeInstance(address _sender, address to, int96 flowRate 
    ) external {
        if(to == liquidwork) return;
        (, int96 outFlowRate, , ) = cfa.getFlow(acceptedToken, liquidwork , to); 
        _deleteFlow(_sender, liquidwork);
        emit noFunds(2);
    }


    /**************************************************************************
     * SuperApp callbacks
     *************************************************************************/

    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata _agreementData, /*_agreementData*/
        bytes calldata, // _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        // Logic after stream created
        // check if stream_flowrate > Service_flowrate
        // change status of Service to Started
        (address sender, ) = abi.decode(_agreementData, (address, address));
        (, int96 flowRate, , ) = cfa.getFlow(
            acceptedToken,
            sender,
            address(this)
        );
        newCtx = _ctx;
    }

    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata _agreementData, //agreementData,
        bytes calldata _cbdata,
        bytes calldata _ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        // Logic after stream updated
        (address sender, ) = abi.decode(_agreementData, (address, address));
        uint256 updateAmount = abi.decode(_cbdata, (uint256));
        (, int96 flowRate, , ) = cfa.getFlow(
            acceptedToken,
            sender,
            address(this)
        );
        // if sender no more funds -> emitEvent(no funds)
        // if stream started ->
        newCtx = _ctx;
    }

    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, //_agreementId,
        bytes calldata _agreementData, /*_agreementData*/
        bytes calldata _cbdata,
        bytes calldata _ctx
    ) external override onlyHost returns (bytes memory newCtx) {
        // According to the app basic law, we should never revert in a termination callback
        if (
            address(_superToken) != address(acceptedToken) ||
            ISuperAgreement(_agreementClass).agreementType() !=
            keccak256(
                "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
            )
        ) return _ctx;

        //emit stream stopped event

        newCtx = _ctx;
    }

    /// helper to delete flow
    function _deleteFlow(address _from, address _to) internal {
        host.callAgreement(
            cfa,
            abi.encodeWithSelector(
                cfa.deleteFlow.selector,
                acceptedToken,
                _from,
                _to,
                new bytes(0) // placeholder
            ),
            "0x"
        );
    }

    modifier onlyHost() {
        require(msg.sender == address(host), "Support only one host");
        _;
    }

    modifier onlyExpected(ISuperToken _superToken, address _agreementClass) {
        require(
            address(_superToken) == address(acceptedToken),
            "not accepted token"
        );
        require(
            ISuperAgreement(_agreementClass).agreementType() ==
                keccak256(
                    "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
                ),
            "only CFAv1 supported"
        );
        _;
    }

    modifier notLiquidWork() {
        require(msg.sender != owner);
        _;
    }

    modifier onlySender(uint256 _serviceId) {
        _;
    }

    modifier onlyReceiver(uint256 _serviceId) {
        _;
    }

    /**************************************************************************
     * Chainlink PriceFeed MATIC/USD
    *************************************************************************/

    /**
     * Network: Polygon Testnet (Mumbai)
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
    */

    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function getLatestPrice2() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed2.latestRoundData();
        return price;
    }

    /**************************************************************************
     * Helper functions 
    *************************************************************************/

    //TIME 

    function getNow() public view  returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    //PROXY 
    /*
    function callAgreement(
        ISuperAgreement agreementClass,
        bytes memory callData,
        bytes memory userData
    )
        external override
        returns(bytes memory returnedData)
    {
        return _callAgreement(msg.sender, agreementClass, callData, userData);
    }
    */


}

