// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import {ISuperfluid, ISuperToken, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SuperLiquidWork is SuperAppBase, Ownable {
    ISuperfluid private host;
    // AggregatorV3Interface internal priceFeed;

    struct instance {
        address sender;
        uint256 flowRate;
        uint256 deposit;
    }

    mapping(string => instance) private instances;

    event agreementCreated(
        address sender,
        string instanceId,
        uint256 flowRate,
        uint256 deposit
    );
    event agreementTerminated(
        address sender,
        string instanceId,
        uint256 flowRate,
        uint256 deposit
    );

    constructor(ISuperfluid _host) {
        host = _host;

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.AFTER_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        host.registerApp(configWord);
    }

    receive() external payable {}

    function deposit(string calldata instanceId) external payable {
        instances[instanceId] = instance(msg.sender, 0, msg.value);
        payable(address(this)).transfer(msg.value);
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
        (
            address sender,
            string memory instanceId,
            uint256 flowRate
        ) = decodeData(_agreementData, _ctx);

        require(
            instances[instanceId].deposit > 0,
            "No deposit was made for that instance"
        );

        emit agreementCreated(
            sender,
            instanceId,
            flowRate,
            instances[instanceId].deposit
        ); // -> nodejs server listens and deploys infrastructure

        newCtx = _ctx;
    }

    function afterAgreementTerminated(
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
        (
            address sender,
            string memory instanceId,
            uint256 flowrate
        ) = decodeData(_agreementData, _ctx);
        emit agreementTerminated(
            sender,
            instanceId,
            flowrate,
            instances[instanceId].deposit
        ); // -> nodejs server listens and destroys infrastructure
        delete instances[instanceId];
        newCtx = _ctx;
    }

    function decodeData(bytes memory _agreementData, bytes memory _ctx)
        private
        returns (
            address sender,
            string memory instanceId,
            uint256 flowRate
        )
    {
        (address senderData, ) = abi.decode(_agreementData, (address, address));
        ISuperfluid.Context memory decompiledContext = host.decodeCtx(_ctx);

        uint256 flowrate = decompiledContext.appAllowanceWanted;
        string memory instanceIdData = abi.decode(
            decompiledContext.userData,
            (string)
        );

        instances[instanceIdData].sender = senderData;
        instances[instanceIdData].flowRate = flowRate;

        return (senderData, instanceIdData, flowrate);
    }

    modifier onlyExpected(ISuperToken _superToken, address _agreementClass) {
        require(
            ISuperAgreement(_agreementClass).agreementType() ==
                keccak256(
                    "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
                ),
            "only CFAv1 supported"
        );
        _;
    }
    modifier onlyInstanceOwner(string memory instanceId) {
        require(
            msg.sender != instances[instanceId].sender,
            "Only instance owner can delete it"
        );
        _;
    }
    modifier onlyValidAddress() {
        require(msg.sender != address(0), "Enter a valid address");
        _;
    }
    modifier onlyHost() {
        require(msg.sender == address(host), "Support only one host");
        _;
    }
    modifier onlySender(uint256 _serviceId) {
        _;
    }
    modifier onlyReceiver(uint256 _serviceId) {
        _;
    }

    // function getLatestPrice() public view returns (int256) {
    //     (
    //         ,
    //         /*uint80 roundID*/
    //         int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
    //         ,
    //         ,

    //     ) = priceFeed.latestRoundData();
    //     return price;
    // }
}
