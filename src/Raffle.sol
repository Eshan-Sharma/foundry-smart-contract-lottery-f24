//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

/**
 * @title A sample Raffle Contract
 * @author Eshan Sharma
 * @notice This contract is for creating a sample raffle
 * @dev This contract implements Chainlink VRF and Chainlink Automation
 */
contract Raffle {
    error Raffle__NotEnoughETHSent();

    uint256 private immutable i_entranceFee;

    constructor(uint256 _entranceFee) {
        i_entranceFee = _entranceFee;
    }

    function enterRaffle() external payable {
        if (msg.value <= i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
    }

    function pickWinner() public {}

    /**
     * Getter functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
