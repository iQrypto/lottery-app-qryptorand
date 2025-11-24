// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Currency} from "../LotteryTypes.sol";


interface LotteryInterface {
    /**
     * @notice Runs a lottery draw for the caller with chosen numbers.
     * @dev Enforces min/max bet per number and ensures all logic is stateless.
     * @return RandomNumber The random numbers drawn for this game.
     * @custom:reverts NotEnoughEther if the bet is outside the allowed range.
     * @custom:reverts NoNumber if numbers is empty.
     * @custom:reverts "Not enough unique 5-bit values in input" if drawing quantum random numbers failed.
     */
    function generateNumber(
    ) external payable returns (uint256);
}
