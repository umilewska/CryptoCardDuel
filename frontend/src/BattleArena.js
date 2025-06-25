import { useState, useEffect } from "react";
import { ethers } from "ethers";
import BattleSimulatorABI from "./BattleSimulator.json";
import CardGameABI from "./CardGame.json";
import { CARD_GAME_ADDRESS, BATTLE_SIMULATOR_ADDRESS } from "./contractsConfig";


export default function BattleArena({ account }) {
  const [status, setStatus] = useState("Idle");
  const [battleLog, setBattleLog] = useState("");

  const getContracts = async () => {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const battleContract = new ethers.Contract(BATTLE_SIMULATOR_ADDRESS, BattleSimulatorABI.abi, signer);
    const cardGameContract = new ethers.Contract(CARD_GAME_ADDRESS, CardGameABI.abi, signer);
    return { battleContract, cardGameContract };
  };

  const requestOpponent = async () => {
    setStatus("Requesting opponent...");
    setBattleLog("Battle requested against a random opponent!");
    try {
      const { battleContract, cardGameContract } = await getContracts();

      const balance = await cardGameContract.balanceOf(account);
      if (balance < 3) {
        setStatus("You need at least 3 cards to battle.");
        return;
      }

      const players = await cardGameContract.getAllPlayers();

      // exclude 
      const opponentPool = [];
      for (const addr of players) {
        if (addr.toLowerCase() === account.toLowerCase()) continue;
        const bal = await cardGameContract.balanceOf(addr);
        console.log(`Balance of ${addr}:`, bal.toString());
        if (bal >= 3) opponentPool.push(addr);
      }

      if (opponentPool.length === 0) {
        setStatus("No valid opponents with 3+ cards.");
        return;
      }

      const tx = await battleContract.requestOpponent(opponentPool);
      await tx.wait();
      setStatus("Opponent requested. Waiting for result...");
    } catch (err) {
      console.error(err);
      setStatus("Request failed.");
    }
  };

  useEffect(() => {
    let battleContract;
    let cardGameContract;

    const setupListener = async () => {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      battleContract = new ethers.Contract(BATTLE_SIMULATOR_ADDRESS, BattleSimulatorABI.abi, signer);
      cardGameContract = new ethers.Contract(CARD_GAME_ADDRESS, CardGameABI.abi, signer);

      battleContract.on("BattleResolved", (player1, player2, winner) => {
        console.log("🏆 BattleResolved:", { player1, player2, winner });

        if (winner === "0x0000000000000000000000000000000000000000") {
          setStatus("🤝 It's a draw!");
        } else if (winner.toLowerCase() === account.toLowerCase()) {
          setStatus("🎉 You won!");
        } else {
          setStatus("😞 You lose.");
        }
      });

      battleContract.on("RewardGiven", async (winner, tokenId) => {
        console.log("🎁 RewardGiven:", { winner, tokenId });

        if (winner.toLowerCase() === account.toLowerCase()) {
          const stats = await cardGameContract.cardStats(tokenId);

          const classTypes = ["Warrior", "Mage", "Hunter"];
          const elements = ["Fire", "Water", "Nature"];
          const rarities = ["Common", "Rare", "Epic", "Legendary"];

          const details = `
            🆕 You received a new card!
            Class: ${classTypes[stats[0]]}
            Element: ${elements[stats[1]]}
            Rarity: ${rarities[stats[2]]}
            Attack: ${stats[3]}
            Defense: ${stats[4]}
          `;

          setBattleLog(details);
        }
      });
    };

    setupListener();

    return () => {
      if (battleContract) {
        battleContract.removeAllListeners("BattleResolved");
        battleContract.removeAllListeners("RewardGiven");
      }
    };
  }, [account]);

  return (
    <div>
      <h2>Battle Arena</h2>
      <p>Status: {status}</p>
      <button onClick={requestOpponent}>🎲 Start Random Battle</button>
      <p>{battleLog}</p>
    </div>
  );
}
