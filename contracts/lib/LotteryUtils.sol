// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title LotteryUtils
 * @notice Utility library for lottery number extraction and validation.
 * @dev Provides extraction of unique lottery numbers from a single uint256 input.
 */
library LotteryUtils {
    /**
     * @notice Extracts a specified number of unique lottery numbers (in range 1-32) from a uint256 input.
     * @dev Each number is derived from non-overlapping 5-bit chunks of the input (with +1 offset to yield 1-32).
     *      Uniqueness is enforced; if not enough unique values exist in the input, the function reverts.
     * @param input The 256-bit source of entropy for extraction (e.g., output of a QRNG).
     * @param amount The number of unique lottery numbers to extract (must be <= 32).
     * @return result An array of unique numbers in the range 1-32, length == amount.
     * @custom:throws "Not enough unique 5-bit values in input" if uniqueness cannot be guaranteed.
     */
    function extractLotteryNumbers(
        uint256 input,
        uint8 amount
    ) internal pure returns (uint8[] memory) {
        uint8[] memory result = new uint8[](amount);
        uint8 extracted;
        uint8 count = 0;

        for (uint8 i = 0; count < amount && i < 51; i++) {
            extracted = uint8((input >> (i * 5)) & 0x1F) + 1; // Extract 5 bits (0-31) an add 1 (1-32)

            bool isDuplicate = false;
            for (uint8 j = 0; j < count; j++) {
                if (result[j] == extracted) {
                    isDuplicate = true;
                    break;
                }
            }

            if (!isDuplicate) {
                result[count] = extracted;
                count++;
            }
        }
        require(count == amount, "Not enough unique 5-bit values in input");

        return result;
    }
}

