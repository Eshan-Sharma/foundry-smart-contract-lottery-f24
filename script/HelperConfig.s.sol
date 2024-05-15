//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std//src/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            subscriptionId: 0,
            callbackGasLimit: 500000
        });
    }

    function getOrCreateAnvilEthConfig() public view returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            subscriptionId: 0,
            callbackGasLimit: 500000
        });
    }
}
