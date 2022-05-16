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

contract SuperLiquidWork is SuperAppBase {

    address owner;

    ISuperfluid private host; // host 
    IConstantFlowAgreementV1 private cfa; // type of agreement
    ISuperToken private acceptedToken; // address of token 

    address[] public users; 

    event ServiceCreated(
        address _sender,  
        int96 _flowRate
    );

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

        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP; //Not using Before_Agreement callback

        host.registerApp(configWord);
    }


    /**************************************************************************
    * LiquidWork Management Logic 
    *************************************************************************/

    //@notice User makes deposit to the LiquidWork contract
    function makeDeposit() public payable notLiquidWork {
        require(msg.value >= entry, "Please check our pricing");
        depositors.push(payable(msg.sender));
    }

    //@notice Tracking the balance of the LiquidWork contract 










    /**************************************************************************
     * Superfluid Money Management Logic 
     *************************************************************************/

    /// @dev function for LiquidWork to create a custom service
    function createService(string memory _name, string memory _description, uint256 _serviceId, address _sender, address _receiver, ServiceStatus _status, int96 _flowRate,  uint256 _expirationDate, uint256 _totalAmountStreamed) external noServiceStarted {
        require(msg.sender != _receiver, "sender and receiver are the same");
        require(_expirationDate > block.timestamp, "expiration date is past ");
        servicesCount++; // so that no Service had id = 0
        Service memory newService = Service(
            _name,
            _description,
            _serviceId,
            _sender,
            _receiver,
            _status,
            _flowRate,
            _expirationDate, 
            _totalAmountStreamed
        );
        services.push(newService);
        senderToServiceId[msg.sender] = servicesCount;
        emit ServiceCreated(
            servicesCount,
            msg.sender,
            _receiver,
            _flowRate,
            _expirationDate
        );
    }


    /// @dev function for user to abandon service, can only abandon if service is created
    function abandonService(uint256 _serviceId) external onlySender(_serviceId) {
        require(
            services[_serviceId].status == ServiceStatus.STARTED,
            "cant abandon now"
        );
        services[_serviceId].status = ServiceStatus.ABANDONNED;
        emit ServiceAbandonned(_serviceId);
        (uint256 timestamp, int96 flowRate, , ) = cfa.getFlow(
            acceptedToken,
            msg.sender,
            address(this)
        );
        uint256 amountToSendBack = uint256(uint96(flowRate)) *
            (block.timestamp - timestamp) +
            services[_serviceId].totalAmountStreamed;
        services[_serviceId].totalAmountStreamed = 0;
        _deleteFlow(services[_serviceId].sender, address(this));
        IERC20(acceptedToken).transfer(
            services[_serviceId].receiver,
            amountToSendBack
        );
    }

    /// @dev function for receiver to expire a Service that reached expiration, sends money to receiver
    function expireService(uint256 _serviceId) external onlyReceiver(_serviceId) {
        require(
            block.timestamp > services[_serviceId].expirationDate,
            "Contract not expired yet expired"
        );
        require(
            services[_serviceId].status == ServiceStatus.STARTED,
            "Service cant be expired in current state"
        );
        services[_serviceId].status = ServiceStatus.EXPIRED;
        emit ServiceExpired(_serviceId);
        (uint256 timestamp, int96 flowRate, , ) = cfa.getFlow(
            acceptedToken,
            services[_serviceId].sender,
            address(this)
        );
        uint256 amountToSendBack = uint256(uint96(flowRate)) *
            (block.timestamp - timestamp) +
            services[_serviceId].totalAmountStreamed;
        services[_serviceId].totalAmountStreamed = 0;
        _deleteFlow(services[_serviceId].sender, address(this));
        IERC20(acceptedToken).transfer(
            services[_serviceId].receiver,
            amountToSendBack
        );
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

    /**************************************************************************
     * Helpers functions
     *************************************************************************/
    /// show Service
    function showService(uint256 _serviceId) public view returns (Service memory service) {
        service = services[_serviceId];
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

    function beforeAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, /*agreementId*/
        bytes calldata _agreementData, /*agreementData*/
        bytes calldata /*ctx*/
    )
        external
        view
        virtual
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory cbdata)
    {
        // get the amount streamed by sender before the update
        (address sender, ) = abi.decode(_agreementData, (address, address));
        (uint256 timestamp, int96 flowRate, , ) = cfa.getFlow(
            acceptedToken,
            sender,
            address(this)
        );
        uint256 updateAmount = uint256(uint96(flowRate)) *
            (block.timestamp - timestamp);

        cbdata = abi.encode(updateAmount);
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
        // update amount streamed by user
        (address sender, ) = abi.decode(_agreementData, (address, address));
        uint256 updateAmount = abi.decode(_cbdata, (uint256));
        (, int96 flowRate, , ) = cfa.getFlow(
            acceptedToken,
            sender,
            address(this)
        );
        uint256 serviceId = senderToServiceId[sender];
        // update amount streamed first
        services[serviceId].totalAmountStreamed += updateAmount;
        // check if stream_flowrate > flowrate and status not started => start Service
        // check if new_flowrate < flowrate => Service abandonned and pay receiver
        if (
            flowRate >= services[serviceId].flowRate &&
            services[serviceId].status == ServiceStatus.NOT_STARTED
        ) {
            services[serviceId].status = ServiceStatus.STARTED;
            emit ServiceStarted(serviceId);
        } else if (
            flowRate < services[serviceId].flowRate &&
            services[serviceId].status == ServiceStatus.STARTED
        ) {
            services[serviceId].status = ServiceStatus.ABANDONNED;
            emit ServiceAbandonned(serviceId);
            IERC20(acceptedToken).transfer(
                services[serviceId].receiver,
                services[serviceId].totalAmountStreamed
            );
            services[serviceId].totalAmountStreamed = 0;
        }
        newCtx = _ctx;
    }

    function beforeAgreementTerminated(
        ISuperToken, /*superToken*/
        address, /*agreementClass*/
        bytes32, /*agreementId*/
        bytes calldata _agreementData, /*agreementData*/
        bytes calldata /*ctx*/
    ) external view virtual override returns (bytes memory cbdata) {
        // get the amount streamer by sender before the update
        (address sender, ) = abi.decode(_agreementData, (address, address));
        (uint256 timestamp, int96 flowRate, , ) = cfa.getFlow(
            acceptedToken,
            sender,
            address(this)
        );
        uint256 updateAmount = uint256(uint96(flowRate)) *
            (block.timestamp - timestamp);
        cbdata = abi.encode(updateAmount);
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

        // depening on Service state send money to receiver or sender
        // first update amount to send
        (address sender, ) = abi.decode(_agreementData, (address, address));
        uint256 serviceId = senderToServiceId[sender];
        // update total amount streamed
        services[serviceId].totalAmountStreamed += abi.decode(_cbdata, (uint256));
        uint256 amountToSend = services[serviceId].totalAmountStreamed;

        if (services[serviceId].status == ServiceStatus.STARTED) {
            services[serviceId].status = ServiceStatus.ABANDONNED;
            emit ServiceAbandonned(serviceId);
            services[serviceId].totalAmountStreamed = 0;
            IERC20(acceptedToken).transfer(
                services[serviceId].receiver,
                amountToSend
            );
        } else if (services[serviceId].status == ServiceStatus.NOT_STARTED) {
            services[serviceId].status = ServiceStatus.ABANDONNED;
            //Service(serviceId);
            services[serviceId].totalAmountStreamed = 0;
            IERC20(acceptedToken).transfer(sender, amountToSend);
        }
        newCtx = _ctx;
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



modifier notLiquidWork {
        require(msg.sender != owner);
        _;
    }

modifier onlySender(uint256 _serviceId) {
        require(services[_serviceId].sender == msg.sender, "Only sender Allowed");
        _;
    }

    modifier onlyReceiver(uint256 _serviceId) {
        require(services[_serviceId].receiver == msg.sender, "Only receiver Allowed");
        _;
    }

}