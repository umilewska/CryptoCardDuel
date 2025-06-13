/* global BigInt */

// src/BattleArena.js
import React, { useState } from "react";
// import { ethers } from "ethers";

function BattleArena({ cards, battleContract, account }) {
  const [result, setResult] = useState(null);
  const [selectedCards, setSelectedCards] = useState([]);

  const pickRandomCards = (allCards, n = 3) => {
    const shuffled = [...allCards].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, n);
  };

  const startBattle = async () => {
    if (cards.length < 3) {
      setResult("You need at least 3 cards.");
      return;
    }

    const selected = pickRandomCards(cards);
    setSelectedCards(selected);

    const tokenIds = selected.map(c => c.tokenId);
    const compDeck = generateComputerDeck(); // same as before

    try {
      const winner = await battleContract.battleAgainstComputer(tokenIds, compDeck);
      setResult(`Winner: ${winner}`);
    } catch (err) {
      console.error(err);
      setResult("Battle failed.");
    }
  };

  const generateComputerDeck = () => {
    const ethers = require("ethers");
    const deck = [];
    for (let i = 0; i < 3; i++) {
      const seed = Date.now() + Math.floor(Math.random() * 10000) + i;
      const hash = ethers.keccak256(ethers.toUtf8Bytes(seed.toString()));
      const rand = BigInt(hash);
      deck.push({
        classType: Number(rand % 3n),
        element: Number((rand / 10n) % 3n),
        rarity: 0, // Common
        attack: 5 + Number(rand % 3n),
        defense: 5 + Number((rand / 100n) % 3n),
      });
    }
    return deck;
  };

  return (
    <div className="battle-arena">
      <h2>⚔️ Auto Card Battle</h2>
      <button onClick={startBattle} disabled={cards.length < 3}>
        🎲 Start Random Battle
      </button>

      {selectedCards.length > 0 && (
        <div>
          <h3>Your Randomly Selected Cards:</h3>
          <ul>
            {selectedCards.map((card, i) => (
              <li key={i}>Card #{card.tokenId.toString()}</li>
            ))}
          </ul>
        </div>
      )}

      {result && <p>{result}</p>}
    </div>
  );
}

export default BattleArena;
