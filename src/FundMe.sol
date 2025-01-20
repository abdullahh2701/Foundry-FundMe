// Get funds From the users
// withdraw funds
// set a min funding value in usd

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    //constant keyword to make it gas efficient
    uint256 public constant MINIMUM_USD = 5e18; // 5 * 1e18 because our getConversionRate function is getting the USD with 18 decimal numbers so min usd should also be with 18 decimal points;

    address[] private s_Funders;

    //immutable keyword to make it gas efficient
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    mapping(address => uint256) private s_addressToAmountFunded;

    function Fund() public payable {
        // Allows user to send transaction
        // Have a minimum $ sent

        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didnt send enough eth"
        ); // 1e18 = 1000000000000000000 Wei(18zeros) = 1 ETH

        //an array of addresses of funders
        s_Funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function Withdraw() public onlyOwner {
        //resetting the mappings
        for (
            uint256 funderIndex = 0;
            funderIndex < s_Funders.length;
            funderIndex++
        ) {
            address funder = s_Funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset the funders array
        s_Funders = new address[](0);

        //Withdraw the funds

        // Three Ways:
        //     transfer
        //msg.sender = address(type)
        //payble(msg.sender) = payble address(type)

        // payable(msg.sender).transfer(address(this).balance);

        // //     send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"send failed");
        //     call
        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "send failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner,"Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        Fund();
    }

    fallback() external payable {
        Fund();
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    //view / pure functions (Getters)

    function getFunder(uint256 index) external view returns (address) {
        return s_Funders[index];
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
