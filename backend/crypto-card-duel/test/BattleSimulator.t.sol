// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/BattleSimulator.sol";
import "../src/CardGame.sol";

// Expose the internal function as public for testing
contract BattleSimulatorHarness is BattleSimulator {
    constructor(
        address _cardGame,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId
    ) BattleSimulator(_cardGame, _vrfCoordinator, _keyHash, _subscriptionId) {}

    function exposeSimulateBattle(
        address p1,
        uint256[] memory c1,
        address p2,
        uint256[] memory c2
    ) public view returns (address) {
        return simulateBattle(p1, c1, p2, c2);
    }
}


contract BattleSimulatorTest is Test {
    CardGame public cardGame;
    BattleSimulatorHarness public simulator;

    address player1 = address(0x1);
    address player2 = address(0x2);

    function setUp() public {
        cardGame = new CardGame();
        simulator = new BattleSimulatorHarness(
            address(cardGame),
            address(0), // dummy VRFCoordinator
            bytes32(0), // dummy keyHash
            0           // dummy subscriptionId
        );

        // Give players starter packs
        vm.prank(player1);
        cardGame.claimStarterPack();

        vm.prank(player2);
        cardGame.claimStarterPack();
    }

    function testSimulateBattle() public {
        // Get cards
        uint256[] memory cards1 = cardGame.tokensOfOwner(player1);
        uint256[] memory cards2 = cardGame.tokensOfOwner(player2);

        // Pick first 3 cards each
        uint256[] memory p1 = new uint256[](3);
        uint256[] memory p2 = new uint256[](3);

        for (uint i = 0; i < 3; i++) {
            p1[i] = cards1[i];
            p2[i] = cards2[i];
        }

        // Simulate battle
        address winner = simulator.exposeSimulateBattle(player1, p1, player2, p2);

        assertTrue(
            winner == player1 || winner == player2 || winner == address(0),
            "Invalid winner address"
        );

        emit log_named_address("Winner is", winner);
    }
}
