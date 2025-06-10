// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CardGame.sol";

contract DeployAndMint is Script {
    address constant PLAYER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function run() external {
        vm.startBroadcast();

        // Deploy kontraktu
        CardGame game = new CardGame();

        // Mint Starter Pack (3 karty) dla gracza
        game.mintStarterPack(PLAYER);

        console2.log("CardGame deployed at:", address(game));
        console2.log("Starter Pack minted for:", PLAYER);

        vm.stopBroadcast();
    }
}