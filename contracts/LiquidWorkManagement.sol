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

contract SuperLiquidWork is SuperAppBase {
    address owner;

    ISuperfluid private host; // host
    IConstantFlowAgreementV1 private cfa; // type of agreement
    ISuperToken private acceptedToken; // address of token

    address[] public users;

    event ServiceCreated(address _sender, int96 _flowRate);

    event streamStoped(uint256 _serviceId);
    event streamStarted(uint256 _serviceId);
    event noFunds(uint256 _serviceId);

    constructor(
        ISuperfluid _host,
        IConstantFlowAgreementV1 _cfa,
        ISuperToken _acceptedToken
    ) {
        owner = msg.sender;
        host = _host;
        cfa = _cfa;
        acceptedToken = _acceptedToken;
        priceFeed = AggregatorV3Interface();

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP; //Not using Before_Agreement callback

        host.registerApp(configWord);
    }

    /**************************************************************************
     * Superfluid Money Management Logic
     *************************************************************************/

    // @notice
    function initInstance(
        address _sender,
        uint256 _usd,
        uint256 timestamp
    ) external {
        // transform usd-matic
        // transform matic to wei
        // divide wei/(timestamp*1000) -> flowrate
        // start stream use cfa
    }

    function removeInstance(
        //do magic here
    ) external {

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
        // get serciveId and serviceFlow rate
        uint256 serviceId = senderToServiceId[sender];
        int96 serviceFlowRate = services[serviceId].flowRate;

        if (
            flowRate >= serviceFlowRate &&
            services[serviceId].status == ServiceStatus.NOT_STARTED
        ) {
            services[serviceId].status = ServiceStatus.STARTED;
            emit ServiceStarted(serviceId);
        }
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
        require(
            services[_serviceId].sender == msg.sender,
            "Only sender Allowed"
        );
        _;
    }

    modifier onlyReceiver(uint256 _serviceId) {
        require(
            services[_serviceId].receiver == msg.sender,
            "Only receiver Allowed"
        );
        _;
    }

    /**************************************************************************
     * Chainlink PriceFeed MATIC/USD
     *************************************************************************/

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

        ) = priceFeed.latestRoundData();
        return price;
    }
}
