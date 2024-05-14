//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
/**
 * @title A sample Raffle Contract
 * @author Eshan Sharma
 * @notice This contract is for creating a sample raffle
 * @dev This contract implements Chainlink VRF and Chainlink Automation
 */

contract Raffle is VRFConsumerBaseV2 {
    //Custom Errors
    error Raffle__NotEnoughETHSent();
    error Raffle__TransactionFailed();
    error Raffle__RaffleNotOpen();

    // Type declarations
    enum RaffleState {
        Open,
        Calculating
    }

    // State Variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    ///@dev Duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane; //keyHash
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    RaffleState private s_raffleState;

    // Events
    event EnteredRaffle(address indexedPlayer);
    event WinnerPicked(address winner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_raffleState = RaffleState.Open;
    }

    function enterRaffle() external payable {
        if (s_raffleState != RaffleState.Open) {
            revert Raffle__RaffleNotOpen();
        }
        if (msg.value <= i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // 1. Get a random number
    // 2. Use the random number to pick a players
    // 3. Pick a winner after a set period of time
    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.Calculating;
        // Here means enough time has passed
        // Get a random number - Chainlink is a 2 step process
        //      1. Request the Random Number Generator
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
        //      2. Get the random number
    }

    // CEI design patter:Checks, Effects, Interactions
    function fulfillRandomWords(uint256 _requestId, uint256[] memory randomWords) internal override {
        // Checks
        // Effects (own contract)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.Open;
        s_players = new address payable[](0); // Reset the players
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);
        // Interactions (other contract)
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransactionFailed();
        }
    }

    /**
     * Getter functions
     */
    function getEntranceFee() external view returns (uint256) {}
}
