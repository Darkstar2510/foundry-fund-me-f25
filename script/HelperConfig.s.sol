//deploy mocks when we are on local chain
//keep tract of contract addresses across different chains
//sepolia ETH/USD and Mainnet ETH/USD has different address
//if we setup helper config correctly - we be able to work with local chain with no problem and any chain no problem

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//importing script
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //if we are on local anvil, we deploy mocks
    //otherwise grab on existing address from live network
    //so that we dint have to hardcode the address on here - so the test will work no matter what we are on -- local chain or fork chain or real chain

    //how we push this in to the deployFundMe contract inside broadcast address
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    MockV3Aggregator mockPriceFeed;

    //how can we set this to whichever one of the config to these functions and DeployMe point to activeNetworkConfigs

    constructor() {
        if (block.chainid == 11155111) {
            //if we on chainId 11155111 -- use this sepoliaNetworkConfig
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    struct NetworkConfig {
        address priceFeed; //ETH/USD pricefeed address
        //now those both fun will return a networkConfig object with this priceFeed
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //this gonna return a configuration for everything we need in sepolia or any chain
        //all we need is == pricefeed address

        // what if we have lot of stuffs like pricefeed addr , vrf address , gas price -- what if we hve ton of stuff here
        //this is y its a good idea to turn config into own type with struct

        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //deploy contract by ourselves

        //1. deploy the mocks  -- fake contract or dummy contract -- it is like real contract but controlled by us
        //2. return the mock address

        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
            //reason we put here is --- if we call getAnvilEthConfig without this(if) -- we actually create a new price feed
            //however if we already deployed one -- we dont want to deploy our new one .
        }

        //this way we can actually deploy this mock contracts to the anvil chain
        vm.startBroadcast();
        //since using vm keyword cant use pure

        //in here we gonna deploy our own price feed -- we gonna need own priceFeed contract
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        ); //takes from constructor of MockV3Aggregator.sol
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
