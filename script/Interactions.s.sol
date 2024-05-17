//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {VRFCoordinatorV2} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFCoordinatorV2.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";

contract CreateSubscription is Script {
    function run() external returns (uint64, address) {
        return createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint64, address) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,,,, uint256 deployerKey) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(address _vrfCoordinatorV2Address, uint256 _deployerKey)
        public
        returns (uint64, address)
    {
        if (block.chainid == 31337) {
            console.log("Creating subscription on ChainId:", block.chainid);

            vm.startBroadcast(_deployerKey);
            uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinatorV2Address).createSubscription();
            vm.stopBroadcast();
            console.log("Your sub id is:", subId);
            console.log("Please update your config file with your sub id");
            return (subId, _vrfCoordinatorV2Address);
        } else {
            console.log("DeployerKey:", _deployerKey);
            vm.startBroadcast(_deployerKey);
            console.log("Script is about to create a subscription on chain", block.chainid);
            console.log("Using vrfCoordinator: ", _vrfCoordinatorV2Address);
            uint64 subId = VRFCoordinatorV2(_vrfCoordinatorV2Address).createSubscription();
            console.log("Subscription have been successfully created and your id is", subId);
            vm.stopBroadcast();
            return (subId, _vrfCoordinatorV2Address);
        }
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundScribscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId, //Need to update this
            ,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint64 updatedSubId, address updatedVRFv2) = createSub.run();
            subscriptionId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
            console.log("New SubId Created! ", subscriptionId, "VRF Address: ", vrfCoordinator);
        }
        fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionId, address link, uint256 deployerKey)
        public
    {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainId: ", block.chainid);
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundScribscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address raffle, address vrfCoordinator, uint64 subscriptionId, uint256 deployerKey) public {
        console.log("Adding consumer on ChainId:", block.chainid);
        console.log("Using VRF vrfCoordinator: ", vrfCoordinator);
        console.log("Adding consumer contract: ", raffle);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId, //Need to update this
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subscriptionId, deployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(("Raffle"), block.chainid);
        addConsumerUsingConfig(raffle);
    }
}
