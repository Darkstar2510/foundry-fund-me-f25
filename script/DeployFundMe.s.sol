// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() public returns (FundMe) {
        //before broadCast we gonna create a mock
        HelperConfig helperConfig = new HelperConfig();
        //reason for this -- we dont have to spend the gas like this to deploy this on a real chain
        //anything before broadcast -- its not gonna send in real Txns -- its gonna simulates this in simulated environment

        // //we have now access to the activeNetworkConfig which when we deploy it -- it gonna be updated with the correct helperConfig here.

        //now we can get the right address by grabbing from the helperConfig
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        //anything after startBroadCast is real Txns.
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
