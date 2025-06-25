// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CardGame.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract BattleSimulator is VRFConsumerBaseV2 {
    CardGame public cardGame;
    VRFCoordinatorV2Interface private COORDINATOR;

    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 200000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 2;

    mapping(uint256 => address) public requestIdToPlayer;
    mapping(uint256 => address[]) public requestIdToPlayerPool;

    event BattleResolved(address indexed player1, address indexed player2, address winner);
    event RewardGiven(address winner, uint256 tokenId);


    constructor(
        address _cardGame,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        cardGame = CardGame(_cardGame);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

     function requestOpponent(address[] calldata knownPlayers) external {
        require(cardGame.balanceOf(msg.sender) >= 3, "Need at least 3 cards");
        require(knownPlayers.length > 0, "Opponent pool is empty");
        
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            uint64(subscriptionId),
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        requestIdToPlayer[requestId] = msg.sender;
        requestIdToPlayerPool[requestId] = knownPlayers;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address challenger = requestIdToPlayer[requestId];
        address[] memory pool = requestIdToPlayerPool[requestId];
        address opponent = selectRandomOpponentFromPool(randomWords[0], challenger, pool);

        if (opponent == address(0) || cardGame.balanceOf(opponent) < 3) return;

        uint256[] memory challengerCards = cardGame.tokensOfOwner(challenger);
        uint256[] memory opponentCards = cardGame.tokensOfOwner(opponent);

        uint256 total = challengerCards.length + opponentCards.length;
        uint256[] memory combined = new uint256[](total);

        for (uint i = 0; i < challengerCards.length; i++) {
            combined[i] = challengerCards[i];
        }
        for (uint i = 0; i < opponentCards.length; i++) {
            combined[challengerCards.length + i] = opponentCards[i];
        }

        uint256[] memory shuffled = shuffle(combined, randomWords[0]);

        uint256[] memory cSet = new uint256[](3);
        uint256[] memory oSet = new uint256[](3);

        for (uint i = 0; i < 3; i++) {
            cSet[i] = shuffled[i];
            oSet[i] = shuffled[i + 3];
        }

        address winner = simulateBattle(challenger, cSet, opponent, oSet);
        emit BattleResolved(challenger, opponent, winner);

        if (winner != address(0)) {
            uint256 rewardTokenId = mintRewardCard(winner, randomWords[1]);
            emit RewardGiven(winner, rewardTokenId);
        }
    }

    function selectRandomOpponentFromPool(
        uint256 rand,
        address exclude,
        address[] memory pool
    ) internal view returns (address) {
        if (pool.length < 2) return address(0);

        for (uint i = 0; i < pool.length; i++) {
            uint256 idx = (rand + i) % pool.length;
            address candidate = pool[idx];
            if (candidate != exclude && cardGame.balanceOf(candidate) >= 3) {
                return candidate;
            }
        }

        return address(0);
    }

    function shuffle(uint256[] memory array, uint256 rand) internal pure returns (uint256[] memory) {
        for (uint i = array.length - 1; i > 0; i--) {
            uint256 j = rand % (i + 1);
            (array[i], array[j]) = (array[j], array[i]);
            rand = uint256(keccak256(abi.encode(rand, i)));
        }
        return array;
    }

    function simulateBattle(
        address player1,
        uint256[] memory cards1,
        address player2,
        uint256[] memory cards2
    ) internal view returns (address) {
        uint256 alive1 = 3;
        uint256 alive2 = 3;

        uint256 i = 0; // player1 index
        uint256 j = 0; // player2 index

        uint256 leftHpA = 0;
        uint256 leftHpB = 0;

        CardGame.CardStats[3] memory team1;
        CardGame.CardStats[3] memory team2;

        for (uint256 k = 0; k < 3; k++) {
            team1[k] = cardGame.getCardStats(cards1[k]);
            team2[k] = cardGame.getCardStats(cards2[k]);
        }

        while (i < 3 && j < 3) {
            CardGame.CardStats memory a = team1[i];
            CardGame.CardStats memory b = team2[j];

            uint256 attackA = a.attack;
            uint256 attackB = b.attack;

            uint256 hpA = leftHpA != 0 ? leftHpA : a.defense;
            uint256 hpB = leftHpB != 0 ? leftHpB : b.defense;

            // Elemental advantage
            if (hasElementalAdvantage(a.element, b.element)) {
                attackA *= 2;
            }
            if (hasElementalAdvantage(b.element, a.element)) {
                attackB *= 2;
            }

            // Class advantage
            if (hasClassAdvantage(a.classType, b.classType)) {
                attackA = (attackA * 3) / 2;
            }
            if (hasClassAdvantage(b.classType, a.classType)) {
                attackB = (attackB * 3) / 2;
            }

            // Simulate the duel
            while (hpA > 0 && hpB > 0) {
                if (attackB >= hpA) {
                    hpA = 0;
                } else {
                    hpA -= attackB;
                }

                if (attackA >= hpB) {
                    hpB = 0;
                } else {
                    hpB -= attackA;
                }
            }

            if (hpA <= 0 && hpB > 0) {
                // player1 card dies
                i++;
                alive1--;
                leftHpA = 0;
                leftHpB = hpB;
            } else if (hpB <= 0 && hpA > 0) {
                // player2 card dies
                j++;
                alive2--;
                leftHpB = 0;
                leftHpA = hpA;
            } else {
                // both die
                i++;
                alive1--;
                j++;
                alive2--;
                leftHpA = 0;
                leftHpB = 0;
            }
        }

        if (alive1 > alive2) return player1;
        if (alive2 > alive1) return player2;
        return address(0); // draw
    }

    function hasElementalAdvantage(CardGame.Element a, CardGame.Element b) internal pure returns (bool) {
        // Natura > Woda > Ogień > Natura
        if (a == CardGame.Element.Nature && b == CardGame.Element.Water) return true;
        if (a == CardGame.Element.Water && b == CardGame.Element.Fire) return true;
        if (a == CardGame.Element.Fire && b == CardGame.Element.Nature) return true;
        return false;
    }

    function hasClassAdvantage(CardGame.Class a, CardGame.Class b) internal pure returns (bool) {
        // Łowca > Wojownik > Mag > Łowca
        if (a == CardGame.Class.Hunter && b == CardGame.Class.Warrior) return true;
        if (a == CardGame.Class.Warrior && b == CardGame.Class.Mage) return true;
        if (a == CardGame.Class.Mage && b == CardGame.Class.Hunter) return true;
        return false;
    }

    function mintRewardCard(address to, uint256 pureRand) internal returns (uint256) {
        uint8 rarity = uint8((pureRand % 3) + 1); // Rare (1) to Legendary (3)
        uint256 tokenId = cardGame.mintCardWithForcedRarity(to, pureRand, rarity);
        return tokenId;
    }

}
