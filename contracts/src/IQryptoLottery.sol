// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LotteryInterface} from "./interfaces/LotteryInterface.sol";
import {StorageNumber} from "../lib/QryptoRand/contracts/src/IQryptoStorageNumber.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {LotteryUtils} from "../lib/LotteryUtils.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Currency} from "./LotteryTypes.sol";

/**
 * @title QryptoRand Lottery
 * @notice A quantum RNG-powered, decentralized lottery for a single player per round.
 * @dev Deploys with an external randomness provider (StorageNumber) and emits on-chain results.
 */
contract Lottery is LotteryInterface, Ownable {
    /// @notice External randomness source contract.
    StorageNumber public storageNumber;
    IERC20 public immutable yptoToken;

    using LotteryUtils for uint256;

    /// @notice Owner address for iQrypto operator (receives protocol fees, if any).
    address payable public iQrypto;

    // Number of random numbers drawn per game.
    uint8 private constant drawnAmount = 4;

    uint256 public constant MIN_BET_VALUE = 0.0001 ether;
    uint256 public constant MAX_BET_VALUE = 5 ether;

    /**
     * @notice Emitted after each game.
     * @param owner The player address.
     * @param inputNumbers The numbers selected by the player.
     * @param drawnRandomNumbers The random numbers drawn by quantum RNG.
     * @param _winningNumbers The numbers from inputNumbers that match the drawn numbers.
     * @param reward The total reward paid out, if any.
     * @param currency The currency used for the bet (Ether or YptoToken).
     */
    event WinningNumbersGenerated(
        address indexed owner,
        uint8[] inputNumbers,
        uint8[] drawnRandomNumbers,
        uint8[] _winningNumbers,
        uint reward,
        Currency currency
    );

    /// @notice Reverts if the total Ether sent is insufficient for the bet requirements.
    /// @param value The amount of Ether sent in the transaction.
    error InvalidBetRange(uint256 value);

    /// @notice Reverts if no numbers are provided as input.
    error NoNumber();

    ///@notice Reverts if there is not enough fund for the transaction.
    ///@param available balance of the wallet
    ///@param requested number of token to withdraw
    ///@param currency requested token (0 = Ether ; 1 = Ypto)
    error InsufficientFunds(
        uint256 available,
        uint256 requested,
        Currency currency
    );
    error InvalidCurrency();

    /**
     * @notice Deploys the lottery contract with a quantum RNG storage backend.
     * @param contractStorageNumber Address of the QryptoRand StorageNumber contract.
     * @param yptoTokenAddress Address of the ypto token contract.
     */
    constructor(
        address contractStorageNumber,
        address yptoTokenAddress
    ) payable Ownable(payable(msg.sender)) {
        storageNumber = StorageNumber(contractStorageNumber);
        iQrypto = payable(storageNumber.owner());
        yptoToken = IERC20(yptoTokenAddress);
    }

    /**
     * @notice Runs a lottery draw for the caller with chosen numbers.
     * @dev Enforces min/max bet per number and ensures all logic is stateless.
     *      Emits a {WinningNumbersGenerated} event after each draw.
     * @param numbers The numbers chosen by the player (up to 4).
     * @param betValue The value of the bet in smallest unit (1 token = 1e18 unit).
     * @param currency 0 = Ether, 1 = Ypto token
     * @return drawnNumbers The random numbers drawn for this game.
     * @custom:reverts InvalidBetRange if the bet is outside the allowed range.
     * @custom:reverts NoNumber if numbers is empty.
     * @custom:reverts "Not enough unique 5-bit values in input" if drawing quantum random numbers failed.
     */
    function generateLotteryNumbers(
        uint8[] memory numbers,
        uint256 betValue,
        Currency currency
    ) public payable returns (uint8[] memory) {
        if (numbers.length < 1) {
            revert NoNumber();
        }
        uint256 betPerNumber;
        if (currency == Currency.Ether) {
            betValue = msg.value - storageNumber.QRN_PRICE(); // retrieve QRNG cost
            betPerNumber = betValue / numbers.length;
            if (
                (betPerNumber < MIN_BET_VALUE || betPerNumber > MAX_BET_VALUE)
            ) {
                revert InvalidBetRange(betValue);
            }
        } else if (currency == Currency.Ypto) {
            betPerNumber = betValue / numbers.length; // QRNG cost as ether in msg.value
            if (
                (betPerNumber < MIN_BET_VALUE || betPerNumber > MAX_BET_VALUE)
            ) {
                revert InvalidBetRange(betValue);
            }
            require(
                yptoToken.transferFrom(msg.sender, address(this), betValue),
                "Ypto transfer failed"
            );
        } else {
            revert("Invalid currency");
        }

        uint256 drawnRawNumber = storageNumber.askRandomNumber{value: storageNumber.QRN_PRICE()}(false);

        // Extract 4 unique 5-bits numbers from a 256-bit quantum random number.
        // Revert if extraction failed.
        uint8[] memory drawnNumbers = drawnRawNumber.extractLotteryNumbers(
            drawnAmount
        );

        // Match check and collect winning numbers
        uint8[] memory tempWinning = new uint8[](drawnAmount);
        uint8 matchCount = 0;

        for (uint8 i = 0; i < drawnAmount; i++) {
            if (_checkNumber(numbers, drawnNumbers[i])) {
                tempWinning[matchCount] = drawnNumbers[i];
                matchCount++;
            }
        }

        // Resize winningNumbers to actual match count
        uint8[] memory winningNumbers = new uint8[](matchCount);
        for (uint8 i = 0; i < matchCount; i++) {
            winningNumbers[i] = tempWinning[i];
        }

        uint reward = calculateReward(matchCount, betValue);

        if (reward > 0) {
            if (currency == Currency.Ether) {
                (bool sent, ) = payable(msg.sender).call{value: reward}("");
                require(sent, "Failed to send Ether");
            } else if (currency == Currency.Ypto) {
                require(
                    yptoToken.transfer(msg.sender, reward),
                    "Ypto reward transfer failed"
                );
            } else {
                revert InvalidCurrency();
            }
        }

        emit WinningNumbersGenerated(
            msg.sender,
            numbers,
            drawnNumbers,
            winningNumbers,
            reward,
            currency
        );

        return drawnNumbers;
    }

    /**
     * @notice Calculates the reward based on how many numbers were selected and total bet.
     * @param matchCount The number of winning numbers matched by the player.
     * @param bet The total bet value sent with the transaction.
     * @return reward The payout to the player.
     */
    function calculateReward(
        uint8 matchCount,
        uint bet
    ) internal pure returns (uint) {
        if (matchCount == 1) return 2 * bet;
        if (matchCount == 2) return 5 * bet;
        if (matchCount == 3) return 30 * bet;
        if (matchCount == 4) return 250 * bet;
        return 0;
    }

    /**
     * @notice Checks if a drawn number is present in the user's selected numbers.
     * @param selectedNumbers The numbers chosen by the player.
     * @param drawnNumber The drawn number to check for a match.
     * @return True if drawnNumber is present in selectedNumbers.
     */
    function _checkNumber(
        uint8[] memory selectedNumbers,
        uint8 drawnNumber
    ) internal pure returns (bool) {
        for (uint8 i = 0; i < selectedNumbers.length; i++) {
            if (selectedNumbers[i] == drawnNumber) {
                return true;
            }
        }
        return false;
    }

    /**
    * @notice Withdraw Ether or YPTO tokens from the contract to the owner.
    * @dev Allows the contract owner to withdraw a specified amount of Ether or YPTO tokens.
    *      The function checks for zero withdrawal amounts, sufficient contract balance,
    *      and that the currency type is valid. For Ether withdrawals, it sends the specified
    *      amount to the owner and requires the transfer to succeed. For token withdrawals,
    *      it transfers the requested amount of YPTO tokens to the owner.
    * @param amount The amount to withdraw, in the smallest unit (wei for Ether, 1e-18 for YPTO token).
    * @param currency The currency to withdraw (Currency.Ether for Ether, Currency.YPTO for YPTO token).
    * @custom:reverts InsufficientFunds if the contract balance is less than the requested amount.
    * @custom:reverts InvalidCurrency if the provided currency is not supported.
    * @custom:reverts "Withdraw failed" if the transaction transfer fails.
    */
    function withdraw(
        uint256 amount,
        Currency currency
    ) external onlyOwner {
        uint256 balance;
        if (currency == Currency.Ether) {
            balance = address(this).balance;
            if (amount > balance) {
                revert InsufficientFunds(balance, amount, currency);
            }
            (bool sent, ) = owner().call{value: amount}("");
            require(sent, "Withdraw failed");
        } else if (currency == Currency.Ypto) {
            balance = yptoToken.balanceOf(address(this));
            if (amount > balance) {
                revert InsufficientFunds(balance, amount, currency);
            }
            require(
                yptoToken.transfer(owner(), amount),
                "Withdraw failed"
            );
        } else {
            revert InvalidCurrency();
        }
    }
}
