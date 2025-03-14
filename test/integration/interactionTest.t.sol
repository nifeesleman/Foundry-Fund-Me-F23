//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/interaction.s.sol";

contract interactionTest is Test {
    FundMe fundMe;
    // address priceFeedAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // ✅ Sepolia ETH/USD Price Feed Address
    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.01 ether;
    uint256 constant STARTING_BALANCE = 200 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
        // // ✅ Correct Price Feed Address
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        // vm.prank(USER);
        // vm.deal(USER, 1e18);
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);

        // address funder = fundMe.getFunder(0);
        // assertEq(funder, USER);
    }
}
