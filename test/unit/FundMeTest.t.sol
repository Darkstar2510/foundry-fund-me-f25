// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); //this cannot be constant
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //always runs first
        //in all of our test -- 1st thing happen is our setup funtion
        // new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);   instead of this line we simply use
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        //coz run() now gona return FundMe contract
        vm.deal(USER, STARTING_BALANCE); //this will give some fake balance to the user
    }

    function testMinimumDollarIsFive() public {
        //this is where we will write our test logic
        //test contract gives asserteq
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); //the next line should revert.
        //assert(this tx fails / revert)
        fundMe.fund(); //send 0 value --less than min rate 5$
    }

    //testing if the s_addressToAmountFunded is updated correctly
    // we do fund enough and updates the data structure.
    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //the next Tx will be sent by user
        fundMe.fund{value: SEND_VALUE}();
        //and check addressToAmountFunded is getting updated
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    //we need to test that funders array is updated with msg.sender
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); //the next Tx will be sent by user
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunders(0); //this should be user - coz we only have 1 user
        assertEq(funder, USER);
    }

    //every time when we run any of our test -- setUp function will run and then test and sstart over.

    // instead of everytime when we fund - we just use once
    modifier funded() {
        vm.prank(USER); //the next Tx will be sent by user
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    //check onlyModifier piece
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); //it will ignore the vm stuff -- skips
        vm.prank(USER); //because user is not the owner
        fundMe.withdraw();
    }

    //lets test withdrawing and test withdrawing actually works.
    function testWithdDrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        //to see how much gas actually we gonna spend -- we need to calculate gas left before and after
        uint256 gasStart = gasleft(); // this will give us the gas left //1000 gas left

        vm.txGasPrice(GAS_PRICE); //now in test we have gas price
        vm.prank(fundMe.getOwner()); //costs 200 gas
        fundMe.withdraw(); //shud have spent gas

        uint256 gasEnd = gasleft(); //800 gas left
        //gas used from withdraw txn
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //200 * 1 = 200
        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0); //we withdraw all the money
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance //there is nothing to do with gas here
        );
        //here we withdrawn all the money from fundme contract and added to "endingOwnerBalance"
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10; //goes through loop and creating new addresses for this no of funders
        uint160 startingFunderIndex = 1; //starting addr is 1 , because  sometimes 0 addr reverts
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            //fund the fundMe
            fundMe.fund{value: SEND_VALUE}(); // this will go thru the loop and fund the fundMe contract
        }

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw(); //anything inbetween start and stop is gonna be sent by the address
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    //function with multiple funders
    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10; //goes through loop and creating new addresses for this no of funders
        uint160 startingFunderIndex = 1; //starting addr is 1 , because  sometimes 0 addr reverts
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE);
            //fund the fundMe
            fundMe.fund{value: SEND_VALUE}(); // this will go thru the loop and fund the fundMe contract
        }

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw(); //anything inbetween start and stop is gonna be sent by the address
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
