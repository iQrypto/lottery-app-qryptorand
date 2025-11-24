// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LotteryInterface} from "./interfaces/LotteryInterface.sol";
import {
    StorageNumber
} from "../lib/QryptoRand/contracts/src/IQryptoStorageNumber.sol";
import {
    Ownable
} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {
    IERC20
} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
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

    /// @notice Owner address for iQrypto operator (receives protocol fees, if any).
    address payable public iQrypto;

    // Number of random numbers drawn per game.
    uint8 private constant drawnAmount = 1;

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
   @notice Requests a single quantum random number and returns it.
   @dev Requires msg.value == storageNumber.QRN_PRICE(); forwards it to the QRNG contract.
   @return randomNumber The 256bit random value produced by the QRNG backend.
   @custom:reverts If this contract’s balance is less than storageNumber.QRN_PRICE() or if the QRNG call reverts.
    */
    function generateNumber() public payable returns (uint256) {
        require(msg.value == storageNumber.QRN_PRICE(), "QRN fee required");
        uint256 randomNumber = storageNumber.askRandomNumber{
            value: storageNumber.QRN_PRICE()
        }(true);

        return randomNumber;
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
    function withdraw(uint256 amount, Currency currency) external onlyOwner {
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
            require(yptoToken.transfer(owner(), amount), "Withdraw failed");
        } else {
            revert InvalidCurrency();
        }
    }
}
