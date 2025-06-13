// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./CardGame.sol";

// contract BattleSimulator {
//     CardGame public cardGame;

//     constructor(address _cardGameAddress) {
//         cardGame = CardGame(_cardGameAddress);
//     }

// function battle(
//     uint256[3] calldata player1Cards,
//     uint256[3] calldata player2Cards
// ) external view returns (string memory winner) {
//     uint alive1 = 3;
//     uint alive2 = 3;

//     uint i = 0; // indeks gracza 1
//     uint j = 0; // indeks gracza 2

//     uint leftHpA = 0;
//     uint leftHpB = 0;

//     // kopiujemy statystyki kart
//     CardGame.CardStats[3] memory team1;
//     CardGame.CardStats[3] memory team2;

//     for (uint k = 0; k < 3; k++) {
//         team1[k] = cardGame.getCardStats(player1Cards[k]);
//         team2[k] = cardGame.getCardStats(player2Cards[k]);
//     }

//     while (i < 3 && j < 3) {
//         CardGame.CardStats memory a = team1[i];
//         CardGame.CardStats memory b = team2[j];

//         uint attackA = a.attack;
//         uint attackB = b.attack;
//         uint hpA = 0;
//         uint hpB = 0;

//         if (leftHpA != 0){
//             hpA = leftHpA;
//         }
//         else{
//             hpA = a.defense;
//         }
//         if (leftHpB != 0){
//             hpB = leftHpB;
//         }
//         else{
//             hpB = b.defense;
//         }

//         // zastosuj premie gracza 1
//         if (hasElementalAdvantage(a.element, b.element)) {
//             attackA = attackA * 2;
//         }
//         if (hasClassAdvantage(a.classType, b.classType)) {
//             attackA = attackA * 3 / 2;
//         }

//         // premie gracza 2
//         if (hasElementalAdvantage(b.element, a.element)) {
//             attackB = attackB * 2;
//         }
//         if (hasClassAdvantage(b.classType, a.classType)) {
//             attackB = attackB * 3 / 2;
//         }

//         while (hpA > 0 && hpB > 0){
//             hpA -= attackB;
//             hpB -= attackA;
//         }

//         if (hpA <= 0 && hpB > 0){
//             // ginie jednostka 1. gracza
//             i += 1;
//             alive1 -= 1;
//             leftHpA = 0;
//             leftHpB = hpB;
//         }
//         else if (hpB <= 0 && hpA > 0){
//             // ginie jednostka 2. gracza
//             i += 1;
//             alive1 -= 1;
//             leftHpB = 0;
//             leftHpA = hpA;
//         }
//         else{
//             i += 1;
//             alive1 -= 1; 
//             j += 1;
//             alive2 -= 1;
//             leftHpB = 0;
//             leftHpA = 0;
//         }
//     }

//     // określenie zwycięzcy
//     if (alive1 > alive2) return "Player 1 wins";
//     if (alive2 > alive1) return "Player 2 wins";
//     return "Draw";
// }


//     function hasElementalAdvantage(CardGame.Element a, CardGame.Element b) internal pure returns (bool) {
//         // Natura > Woda > Ogień > Natura
//         if (a == CardGame.Element.Nature && b == CardGame.Element.Water) return true;
//         if (a == CardGame.Element.Water && b == CardGame.Element.Fire) return true;
//         if (a == CardGame.Element.Fire && b == CardGame.Element.Nature) return true;
//         return false;
//     }

//     function hasClassAdvantage(CardGame.Class a, CardGame.Class b) internal pure returns (bool) {
//         // Łowca > Wojownik > Mag > Łowca
//         if (a == CardGame.Class.Hunter && b == CardGame.Class.Warrior) return true;
//         if (a == CardGame.Class.Warrior && b == CardGame.Class.Mage) return true;
//         if (a == CardGame.Class.Mage && b == CardGame.Class.Hunter) return true;
//         return false;
//     }
// }
