// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/BattleSimulator.sol";

contract DeployBattleSimulator is Script {
    address constant CARD_GAME_ADDRESS = 0xc5a5C42992dECbae36851359345FE25997F5C42d;
    address constant VRF_COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 constant KEY_HASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint256 constant SUBSCRIPTION_ID = 47028878480498157709256904961738289457614625757591967344804338002370054140593;

    function run() external {
        vm.startBroadcast();
        BattleSimulator sim = new BattleSimulator(
            CARD_GAME_ADDRESS,
            VRF_COORDINATOR,
            KEY_HASH,
            SUBSCRIPTION_ID
        );
        console2.log("BattleSimulator deployed at:", address(sim));
        vm.stopBroadcast();
    }
}
