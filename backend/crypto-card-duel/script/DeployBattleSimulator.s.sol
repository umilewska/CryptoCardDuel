// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BattleSimulator.sol";

contract DeployBattleSimulator is Script {
    //adres contraktu CardGame
    address constant CARD_GAME_ADDRESS = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519; 
    function run() external {
        vm.startBroadcast();
        BattleSimulator sim = new BattleSimulator(CARD_GAME_ADDRESS);
        console2.log("BattleSimulator deployed at:", address(sim));
        vm.stopBroadcast();
    }
}