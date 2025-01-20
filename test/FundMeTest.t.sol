// SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); // Creating a fake user
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // us -> calling FundMe Test -> calling FundMe, so the owner of fund me is fundMeTest
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        vm.deal(USER, STARTING_BALANCE); // Giving the fake user some ether
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // Next line should revert if it doesn't the test fails
        fundMe.Fund(); // sending 0 value
    }

    modifier Funded() {
        vm.prank(USER); // The next transaction will be sent by USER
        fundMe.Fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public Funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER); // The next transaction will be sent by USER
        fundMe.Fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public Funded {
        vm.expectRevert(); // Next line should revert if it doesn't the test fails
        vm.prank(USER);
        fundMe.Withdraw();
    }

    function testWithdrawWithASingleFunder() public Funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 staringFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.Withdraw();

        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + staringFundMeBalance
        );
    }

    function testWithDrawWithMultipleFunders() public Funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        //Arrange
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal() new address
            //we can generate addresses by address(0),address(1),....address(n) but they must be uint160

            hoax(address(i), SEND_VALUE); //same as doing vm.prank and vm.deal()
            fundMe.Fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 staringFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.Withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(
            staringFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
