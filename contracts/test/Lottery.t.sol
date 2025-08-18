// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "../src/IQryptoLottery.sol";
import {LotteryUtils} from "../lib/LotteryUtils.sol";
import {MockStorageNumber, MockERC20} from "./mocks/MockStorageNumber.sol";
import {Currency} from "../src/LotteryTypes.sol";
import "forge-std/Vm.sol";

contract LotteryTest is Test {
    Lottery lottery;
    MockStorageNumber mockStorage;
    MockERC20 mockToken;
    uint256 QRN_PRICE;

    function setUp() public {
        mockStorage = new MockStorageNumber();
        mockToken = new MockERC20();
        QRN_PRICE = mockStorage.QRN_PRICE();
        lottery = new Lottery(address(mockStorage), address(mockToken));
        mockToken.mint(address(lottery), 100 ether);
        mockToken.mint(address(this), 100 ether);
        vm.deal(address(lottery), 100 ether);
        vm.deal(address(this), 100 ether);
    }

    receive() external payable {}

    function testRevertOnEmptySelection() public {
        vm.expectRevert(Lottery.NoNumber.selector);
        uint8[] memory picks;
        uint256 value = 0.01 ether;
        lottery.generateLotteryNumbers{value: value + QRN_PRICE}(
            picks,
            0,
            Currency.Ether
        );
    }

    function testNotEnoughEtherBet() public {
        uint8[] memory picks = new uint8[](2);
        picks[0] = 5;
        picks[1] = 6;

        uint256 tooSmallBet = (lottery.MIN_BET_VALUE() - 1 wei) * picks.length;
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.InvalidBetRange.selector,
                tooSmallBet
            )
        );
        lottery.generateLotteryNumbers{value: tooSmallBet + QRN_PRICE}(
            picks,
            0,
            Currency.Ether
        );
    }

    function testNotEnoughYptoBet() public {
        uint8[] memory picks = new uint8[](2);
        picks[0] = 5;
        picks[1] = 6;

        uint256 tooSmallBet = (lottery.MIN_BET_VALUE() - 1 wei) * picks.length;
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.InvalidBetRange.selector,
                tooSmallBet
            )
        );

        lottery.generateLotteryNumbers{value: QRN_PRICE}(
            picks,
            tooSmallBet,
            Currency.Ypto
        );
    }

    function testTooMuchEtherBet() public {
        uint8[] memory picks = new uint8[](2);
        picks[0] = 5;
        picks[1] = 6;

        uint256 tooLargeBet = (lottery.MAX_BET_VALUE() + 1 wei) * picks.length;
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.InvalidBetRange.selector,
                tooLargeBet
            )
        );
        lottery.generateLotteryNumbers{value: tooLargeBet + QRN_PRICE}(
            picks,
            0,
            Currency.Ether
        );
    }

    function testTooMuchYptoBet() public {
        uint8[] memory picks = new uint8[](2);
        picks[0] = 5;
        picks[1] = 6;

        uint256 tooLargeBet = (lottery.MAX_BET_VALUE() + 1 wei) * picks.length;
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.InvalidBetRange.selector,
                tooLargeBet
            )
        );

        lottery.generateLotteryNumbers{value: QRN_PRICE}(
            picks,
            tooLargeBet,
            Currency.Ypto
        );
    }

    function testCorrectRewardCalculation() public {
        mockStorage.setNextRandomNumber(0xF8329A47); // Drawn numbers: [8,19,7,6]
        uint8[] memory picks = new uint8[](4);
        picks[0] = 8;
        picks[1] = 19;
        picks[2] = 7;
        picks[3] = 6;

        uint256 betValue = lottery.MIN_BET_VALUE() * picks.length;

        uint256 initialBalance = address(this).balance;

        lottery.generateLotteryNumbers{value: betValue + QRN_PRICE}(
            picks,
            0,
            Currency.Ether
        );
        uint256 finalBalance = address(this).balance;
        uint256 reward = finalBalance + betValue + QRN_PRICE - initialBalance;

        assertEq(reward, 250 * betValue);
    }

    function testYptoCorrectRewardCalculation() public {
        mockStorage.setNextRandomNumber(0xF8329A47); // Drawn numbers: [8,19,7,6]
        uint8[] memory picks = new uint8[](4);
        picks[0] = 8;
        picks[1] = 19;
        picks[2] = 7;
        picks[3] = 6;

        uint256 betValue = lottery.MIN_BET_VALUE() * picks.length;
        mockToken.approve(address(lottery), betValue);

        uint256 initialBalance = mockToken.balanceOf(address(this));

        lottery.generateLotteryNumbers{value: QRN_PRICE}(
            picks,
            betValue,
            Currency.Ypto
        );

        uint256 finalBalance = mockToken.balanceOf(address(this));
        uint256 reward = finalBalance + betValue - initialBalance;

        assertEq(reward, 250 * betValue);
    }

    function testNoRewardIfNoMatches() public {
        mockStorage.setNextRandomNumber(0xF8329A47); // Drawn numbers: [8,19,7,6]
        uint8[] memory picks = new uint8[](4);
        picks[0] = 1;
        picks[1] = 2;
        picks[2] = 3;
        picks[3] = 4;

        uint256 initialBalance = address(this).balance;
        uint256 betValue = 0.0403 ether;
        lottery.generateLotteryNumbers{value: betValue}(
            picks,
            0,
            Currency.Ether
        );

        uint256 finalBalance = address(this).balance;
        assertEq(finalBalance, initialBalance - 0.0403 ether); // No reward
    }

    function testEventEmittedCorrectly() public {
        mockStorage.setNextRandomNumber(0xF8329A47); // Drawn numbers: [8,19,7,6]

        uint8[] memory picks = new uint8[](4);
        picks[0] = 8;
        picks[1] = 19;
        picks[2] = 7;
        picks[3] = 6;

        vm.recordLogs();
        uint256 betValue = 0.0403 ether;
        lottery.generateLotteryNumbers{value: betValue}(
            picks,
            0,
            Currency.Ether
        );
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Check that the WinningNumbersGenerated event was emitted
        bytes32 expectedSig = keccak256(
            "WinningNumbersGenerated(address,uint8[],uint8[],uint8[],uint256,uint8)"
        );
        bool found = false;
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == expectedSig) {
                found = true;
                break;
            }
        }
        assertTrue(found);
    }

    function testExtractLotteryNumbers() public pure {
        uint256 input = 0x1E242B5;

        uint8[] memory result = LotteryUtils.extractLotteryNumbers(input, 4);
        assertEq(result.length, 4);

        assertEq(result[0], 22);
        assertEq(result[1], 17);
        assertEq(result[2], 5);
        assertEq(result[3], 31);

        // Uniqueness check
        for (uint8 i = 0; i < 4; i++) {
            for (uint8 j = i + 1; j < 4; j++) {
                assert(result[i] != result[j]);
            }
        }
    }
}
