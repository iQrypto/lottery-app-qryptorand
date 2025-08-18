// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../lib/QryptoRand/contracts/src/IQryptoToken.sol";

contract FundLottery is Script {
    function run() external {
        address lotteryAddress = 0xe6b98F104c1BEf218F3893ADab4160Dc73Eb8367;
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        uint256 fundAmount = 1e20;

        // Start broadcasting (use owner PK)
        vm.startBroadcast();

        // Get contract
        Token token = Token(tokenAddress);

        // Transfer tokens from owner to lottery
        token.transfer(lotteryAddress, fundAmount);

        vm.stopBroadcast();
    }
}