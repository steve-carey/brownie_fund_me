// SPDX-Licence-Identifier: MIT

pragma solidity ^0.6.6;

// importing chainlink from NPM
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// safemath used to prevent Uint wrap arround error
// no longer needed in solidity 0.8. or geater
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // Keyword using
    // using attaches SafeMathChainlink library to uint256
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    // constructor executed instantly when contract is deployed to identify owner
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        // executing this provides wallet address
        owner = msg.sender;
    }

    // Function as payable (function can be used to pay for things)
    function fund() public payable {
        // $5
        uint256 minimumUSD = 5 * 10 ** 18;

        // Keyword require - checks truthiness
        // If truthiness is False exe is stopped (it will revert, safely ending the transaction)
        require(getConversionRate(msg.value) >= minimumUSD, " You need to spend more ETH!"); 

        // Keywords value and sender
        // sender - who sent it
        // value - how much has been sent
        addressToAmountFunded[msg.sender] += msg.value;
        // what the Eth -> USD conversion rate is


        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256){
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256){
        (,int256 answer,,,) = priceFeed.latestRoundData();
         return uint256(answer * 10000000000);
    }

    // get conversion in Wei
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        // 3839857941590
        // 0.000003839857941590
    }

    function getEntranceFee() public view returns (uint256) {
        // Minimum USD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 *10**18;
        return (minimumUSD*precision)/price;
    }

    // modifiers are used to change the behaviour of another function
    // used in withdraw() to ensure that withdrawal is sent to owner account
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the account owner.");
        _;
    }

    function withdraw() payable onlyOwner public {
        // whoever calls the withdraw function is the msg.sender
        // transefer this to address (person who called function)
        // balance is the balance that has been funded into the app
        msg.sender.transfer(address(this).balance);

        // reset
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}