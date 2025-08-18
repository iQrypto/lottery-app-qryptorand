// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Currency} from "../LotteryTypes.sol";


interface LotteryInterface {
    /**
     * @notice Runs a lottery draw for the caller with chosen numbers.
     * @dev Enforces min/max bet per number and ensures all logic is stateless.
     *      Emits a {WinningNumbersGenerated} event after each draw.
     * @param numbers The numbers chosen by the player (up to 4).
     * @param betValue The value of the bet in smallest unit (1 token = 1e18 unit).
     * @param currency 0 = Ether, 1 = Ypto token
     * @return drawnNumbers The random numbers drawn for this game.
     * @custom:reverts NotEnoughEther if the bet is outside the allowed range.
     * @custom:reverts NoNumber if numbers is empty.
     * @custom:reverts "Not enough unique 5-bit values in input" if drawing quantum random numbers failed.
     */
    function generateLotteryNumbers(
        uint8[] memory numbers,
        uint256 betValue,
        Currency currency
    ) external payable returns (uint8[] memory);
}
