// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/CardGame.sol";

contract DeployCardGame is Script {
    function run() external {
        vm.startBroadcast();

        CardGame cardGame = new CardGame();
        console2.log("CardGame deployed at:", address(cardGame));

        vm.stopBroadcast();
    }
}