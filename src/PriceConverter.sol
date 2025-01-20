// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //Address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //ABI

        (, int256 price, , , ) = priceFeed.latestRoundData();
        //price of eth in usd
        //2000.00000000(8zeros)
        //since the decimal numbers here are 8 and we need 18 decimal numbers
        //the type is int256 but we need uint256 so

        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
        return ethAmountInUsd;
    }
}
