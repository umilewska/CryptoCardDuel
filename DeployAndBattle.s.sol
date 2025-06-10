// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CardGame.sol";
import "../src/BattleSimulator.sol";

contract DeployAndBattle is Script {
    address constant PLAYER1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant PLAYER2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() external {
        vm.startBroadcast();

        // Deploy CardGame
        CardGame cardGame = new CardGame();

        // Mint Starter Pack dla obu graczy
        cardGame.mintStarterPack(PLAYER1); // tokeny: 1, 2, 3
        cardGame.mintStarterPack(PLAYER2); // tokeny: 4, 5, 6

        // Deploy BattleSimulator
        BattleSimulator simulator = new BattleSimulator(address(cardGame));

        // Rozegraj bitwę między 3 kartami każdego gracza
        uint256[3] memory player1Cards = [uint256(1), 2, 3];
        uint256[3] memory player2Cards = [uint256(4), 5, 6];

        string memory result = simulator.battle(player1Cards, player2Cards);

        console2.log("CardGame deployed at:", address(cardGame));
        console2.log("BattleSimulator deployed at:", address(simulator));
        console2.log("Battle result:", result);

        vm.stopBroadcast();
    }
}
