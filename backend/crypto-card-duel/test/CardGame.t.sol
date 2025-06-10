// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CardGame.sol";

contract CardGameTest is Test {
    CardGame public cardGame;
    address public player = address(1);

    function setUp() public {
        vm.prank(address(0)); // ustaw deployera jako owner
        cardGame = new CardGame();
    }

    function testClaimStarterPackOnce() public {
        vm.prank(player);
        cardGame.claimStarterPack();

        assertEq(cardGame.balanceOf(player), 5);

        // próbujemy drugi raz — powinno się nie udać
        vm.prank(player);
        vm.expectRevert("Starter pack already claimed");
        cardGame.claimStarterPack();
    }

    function testCardStatsAssigned() public {
        vm.prank(player);
        cardGame.claimStarterPack();

        for (uint i = 1; i <= 5; i++) {
            CardGame.CardStats memory stats = cardGame.getCardStats(i);
            assertGe(stats.attack, 5);
            assertLe(stats.attack, 7);
            assertGe(stats.defense, 5);
            assertLe(stats.defense, 7);
        }
    }

    function testOnlyGeneratesCommonCards() public {
        vm.prank(player);
        cardGame.claimStarterPack();

        for (uint i = 1; i <= 5; i++) {
            CardGame.CardStats memory stats = cardGame.getCardStats(i);
            assertEq(uint8(stats.rarity), uint8(CardGame.Rarity.Common));
        }
    }
}
