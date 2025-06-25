import { useEffect, useState } from "react";
import { ethers } from "ethers";
import "./App.css";
import CardGameABI from "./CardGame.json";
import BattleArena from "./BattleArena";
import BattleSimulatorABI from "./BattleSimulator.json";
import { CARD_GAME_ADDRESS, BATTLE_SIMULATOR_ADDRESS } from "./contractsConfig";

const ABI = CardGameABI.abi;

const classNames = ["Warrior", "Mage", "Hunter"];
const elementNames = ["Fire", "Water", "Nature"];
const rarityNames = ["Common", "Rare", "Epic", "Legendary"];

function App() {
  const [account, setAccount] = useState(null);
  const [cardGame, setCardGame] = useState(null);
  const [cards, setCards] = useState([]);
  const [claimed, setClaimed] = useState(false);
  const [battleContract, setBattleContract] = useState(null);

  const connectWallet = async () => {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);

      // Get the network to confirm the connection
      const network = await provider.getNetwork();
      console.log('Connected to network:', network);

      try {
        // Request accounts from MetaMask
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        console.log("Accounts from MetaMask:", accounts);

        if (accounts && accounts.length > 0) {
          const account = accounts[0];
          setAccount(account);
          console.log("Connected to account:", account);

          // set up the contract instance
          const signer = await provider.getSigner();
          const contract = new ethers.Contract(CARD_GAME_ADDRESS, ABI, signer);
          setCardGame(contract);
        } else {
          console.error("No accounts found in MetaMask.");
        }
      } catch (error) {
        console.error("Error connecting to MetaMask:", error);
      }
    }
  };

  // inicjalizacja kontraktu po zalogowaniu
  useEffect(() => {
    const setup = async () => {
      if (!account) return;

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CARD_GAME_ADDRESS, ABI, signer);
      const battle = new ethers.Contract(BATTLE_SIMULATOR_ADDRESS, BattleSimulatorABI.abi, signer);

      setCardGame(contract);
      setBattleContract(battle);

      const alreadyClaimed = await contract.hasClaimedStarterPack(account);
      console.log("Already claimed:", alreadyClaimed); 
      setClaimed(alreadyClaimed);

      if (alreadyClaimed) {
        const tokenIds = await contract.tokensOfOwner(account);
        const userCards = [];

        for (const tokenId of tokenIds) {
          const stats = await contract.getCardStats(tokenId);
          userCards.push({ tokenId, stats });
        }

        setCards(userCards);
      }
    };

    setup();
  }, [account]);


  const claimStarterPack = async () => {
    if (!cardGame || !account) return;

    try {
      // Claim the starter pack
      const tx = await cardGame.claimStarterPack();
      console.log("Transaction sent:", tx);
      const receipt = await tx.wait();
      console.log("Transaction mined, receipt:", receipt);

      console.log("Starter pack claimed!");
      console.log("account:", account);

      // After the transaction is complete, re-fetch the balance and cards
      const balance = await cardGame.balanceOf(account);
      console.log("Balance of account after claiming:", balance.toString());

      // Fetch the user's cards
      const tokenIds = await cardGame.tokensOfOwner(account);
      const userCards = [];

      for (const tokenId of tokenIds) {
        const stats = await cardGame.getCardStats(tokenId);
        userCards.push({ tokenId, stats });
      }

      // Update the state to reflect the user's cards
      setCards(userCards);

      console.log("Starter pack claimed successfully!");

    } catch (error) {
      console.error("Error claiming starter pack:", error);
    }
  };

  
  return (
    <div className="App">
      <h1>Crypto Card Duel</h1>

      {!account ? (
        <button onClick={connectWallet}>Connect Wallet</button>
      ) : (
        <>
          <p>Connected as: {account}</p>

          {!claimed && (
            <button onClick={claimStarterPack}>🎁 Claim Starter Pack (5 Cards)</button>
          )}

          <h2>Your Cards:</h2>
          {cards.length === 0 ? (
            <p>No cards yet.</p>
          ) : (
            <div className="card-grid">
              {cards.map((card, i) => {
                const s = card.stats;
                const imageUrl = `/images/card-${s.classType}-${s.element}.jpg`;

                return (
                  <div
                    key={i}
                    className="card"
                    style={{ backgroundImage: `url(${imageUrl})` }}
                    data-rarity={rarityNames[s.rarity]}
                  >
                    <div className="card-content">
                      <h3>Card #{card.tokenId.toString()}</h3>
                      <p><b>Class:</b> {classNames[s.classType]}</p>
                      <p><b>Element:</b> {elementNames[s.element]}</p>
                      <p><b>Rarity:</b> {rarityNames[s.rarity]}</p>
                      <p><b>Attack:</b> {s.attack.toString()}</p>
                      <p><b>Defense:</b> {s.defense.toString()}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          <div style={{ marginTop: "3rem", marginBottom: "4rem" }}>
            <BattleArena cards={cards} battleContract={battleContract} cardGame={cardGame} account={account} />
          </div>

        </>
      )}
    </div>
  );
}

export default App;
