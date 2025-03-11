//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address priceFeedAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // ✅ Sepolia ETH/USD Price Feed Address
    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.01 ether;
    uint256 constant STARTING_BALANCE = 200 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
        // // ✅ Correct Price Feed Address
    }

    function testMinimumDollar() public view {
        assertEq(fundMe.minimumUsd(), 5e18);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        console.log("Price Feed Version:", version); // Optional log
        assertEq(version, 4); // ✅ Chainlink Sepolia Version is 4
    }

    function testFundFailWithoutEnoughETH() public {
        vm.expectRevert("Did't send enough fund");
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFundesToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint256 startingFunderIndex = 2;
        for (uint256 i = startingFunderIndex; i < numberOfFunders; i++) {
            address funderAddress = address(uint160(i)); // Convert uint256 to address
            hoax(funderAddress, SEND_VALUE); // Use hoax to set funder address and value
            fundMe.fund{value: SEND_VALUE}(); // Fund the contract
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        console.log(
            "Contract balance before withdraw:",
            address(fundMe).balance
        );
        console.log(
            "Owner balance before withdraw:",
            fundMe.getOwner().balance
        );

        // Act
        vm.startPrank(fundMe.getOwner()); // Impersonate the owner
        fundMe.withdraw(); // Withdraw funds from the contract
        vm.stopPrank(); // Stop impersonation

        console.log(
            "Contract balance after withdraw:",
            address(fundMe).balance
        );
        console.log("Owner balance after withdraw:", fundMe.getOwner().balance);

        // Assert
        assert(address(fundMe).balance == 0); // Ensure contract balance is 0 after withdraw
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        ); // Ensure the owner's balance increased by the contract balance
    }
}
//     function testWithDrawWithASingleFunder() public funded {
//         // Arrange
//         uint256 startingOwnerBalance = fundMe.getOwner().balance;
//         uint256 startingFundMeBalance = address(fundMe).balance;

//         // Ensure the contract has funds to withdraw
//         require(startingFundMeBalance > 0, "Contract balance should be > 0");

//         // Act
//         vm.prank(fundMe.getOwner()); // Impersonate the owner
//         fundMe.withdraw(); // Withdraw the funds

//         // Assert
//         uint256 endingOwnerBalance = fundMe.getOwner().balance;
//         uint256 endingFundMeBalance = address(fundMe).balance;

//         // Ensure the contract's balance is 0 after withdrawal
//         assertEq(endingFundMeBalance, 0);

//         // The owner's balance should have increased by the contract's starting balance
//         assertEq(
//             endingOwnerBalance,
//             startingOwnerBalance + startingFundMeBalance
//         );
//     }
// }
