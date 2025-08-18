// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "../src/IQryptoLottery.sol";

contract DeployScript is Script {
    Lottery public lottery;
    address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
    address storageAddress = vm.envAddress("STORAGE_ADDRESS");

    function run() public {
        vm.startBroadcast();

        lottery = new Lottery(storageAddress, tokenAddress);

        vm.stopBroadcast();
    }
}
