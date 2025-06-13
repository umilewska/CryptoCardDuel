// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CardGame.sol"; // adjust import path if needed

contract BattleSimulator {
    CardGame public cardGame;

    constructor(address _cardGameAddress) {
        cardGame = CardGame(_cardGameAddress);
    }

    struct BattleCard {
        uint8 attack;
        uint8 defense;
        uint8 rarityBonus;
    }

    // ========== PvP Support ==========

    struct BattleRequest {
        address player;
        uint256[] cardIds;
    }

    mapping(address => BattleRequest) public pendingBattles;
    mapping(bytes32 => bool) public resolvedBattles;

    event BattleCompleted(address indexed player1, address indexed player2, address winner);

    function initiatePvPBattle(address opponent, uint256[] calldata cardIds) external {
        require(cardIds.length == 3, "Must select exactly 3 cards");
        require(opponent != msg.sender, "Can't battle yourself");

        // Save sender's request
        pendingBattles[msg.sender] = BattleRequest(msg.sender, cardIds);

        // If opponent already submitted
        if (pendingBattles[opponent].player == opponent) {
            uint256[] memory opponentCards = pendingBattles[opponent].cardIds;
            uint256[] memory challengerCards = cardIds;

            // Simulate battle
            address winner = _simulateBattle(msg.sender, challengerCards, opponent, opponentCards);

            emit BattleCompleted(msg.sender, opponent, winner);

            // Mark battle as resolved
            bytes32 battleId = keccak256(abi.encodePacked(msg.sender, opponent));
            resolvedBattles[battleId] = true;

            // Clear battle state
            delete pendingBattles[msg.sender];
            delete pendingBattles[opponent];
        }
    }

    function _simulateBattle(
        address player1,
        uint256[] memory cards1,
        address player2,
        uint256[] memory cards2
    ) internal view returns (address) {
        BattleCard[3] memory p1;
        BattleCard[3] memory p2;

        for (uint i = 0; i < 3; i++) {
            CardGame.CardStats memory stats1 = cardGame.getCardStats(cards1[i]);
            CardGame.CardStats memory stats2 = cardGame.getCardStats(cards2[i]);

            p1[i] = BattleCard(stats1.attack, stats1.defense, getRarityBonus(stats1.rarity));
            p2[i] = BattleCard(stats2.attack, stats2.defense, getRarityBonus(stats2.rarity));
        }

        uint score1 = 0;
        uint score2 = 0;

        for (uint i = 0; i < 3; i++) {
            uint power1 = p1[i].attack + p1[i].defense + p1[i].rarityBonus;
            uint power2 = p2[i].attack + p2[i].defense + p2[i].rarityBonus;

            if (power1 > power2) score1++;
            else if (power2 > power1) score2++;
        }

        if (score1 > score2) return player1;
        if (score2 > score1) return player2;
        return address(0); // draw
    }

    // ========== Existing Computer Battle ==========

    function getRarityBonus(CardGame.Rarity rarity) internal pure returns (uint8) {
        if (rarity == CardGame.Rarity.Common) return 1;
        if (rarity == CardGame.Rarity.Rare) return 2;
        if (rarity == CardGame.Rarity.Epic) return 3;
        if (rarity == CardGame.Rarity.Legendary) return 5;
        return 0;
    }

    function battleAgainstComputer(
        uint256[3] calldata playerCards,
        CardGame.CardStats[3] calldata computerCards
    ) external view returns (string memory winner) {
        BattleCard[3] memory user;
        BattleCard[3] memory computer;

        for (uint i = 0; i < 3; i++) {
            require(uint8(computerCards[i].classType) <= 2, "Invalid classType");
            require(uint8(computerCards[i].element) <= 2, "Invalid element");
            require(uint8(computerCards[i].rarity) <= 3, "Invalid rarity");
        }

        for (uint i = 0; i < 3; i++) {
            CardGame.CardStats memory stats = cardGame.getCardStats(playerCards[i]);
            user[i] = BattleCard(stats.attack, stats.defense, getRarityBonus(stats.rarity));
        }

        for (uint i = 0; i < 3; i++) {
            CardGame.CardStats memory stats = computerCards[i];
            computer[i] = BattleCard(stats.attack, stats.defense, getRarityBonus(stats.rarity));
        }

        uint userScore = 0;
        uint computerScore = 0;

        for (uint i = 0; i < 3; i++) {
            uint userPower = user[i].attack + user[i].defense + user[i].rarityBonus;
            uint computerPower = computer[i].attack + computer[i].defense + computer[i].rarityBonus;

            if (userPower > computerPower) userScore++;
            else if (computerPower > userPower) computerScore++;
        }

        if (userScore > computerScore) return "Player";
        if (computerScore > userScore) return "Computer";
        return "Draw";
    }
}
