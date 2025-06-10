import { useEffect, useState } from "react";
import { ethers } from "ethers";
import "./App.css";
import CardGameABI from "./CardGame.json";

const CARD_GAME_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

const ABI = CardGameABI.abi;

const classNames = ["Warrior", "Mage", "Hunter"];
const elementNames = ["Fire", "Water", "Nature"]; 
const rarityNames = ["Common", "Rare", "Epic", "Legendary"];

function App() {
  const [account, setAccount] = useState(null);
  const [cardGame, setCardGame] = useState(null);
  const [cards, setCards] = useState([]);
  const [claimed, setClaimed] = useState(false);

  const connectWallet = async () => {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);
  
      const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
      const target = accounts.find(a => a.toLowerCase() === "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266".toLowerCase());
  
      if (!target) {
        alert("Account 2 is not connected in MetaMask.");
        return;
      }
  
      const signer = await provider.getSigner(target);
      const address = await signer.getAddress();
      console.log("Using signer address:", address);
  
      setAccount(address);
  
      const contract = new ethers.Contract(CARD_GAME_ADDRESS, ABI, signer);
      setCardGame(contract);
    }
  };
  // inicjalizacja kontraktu po zalogowaniu
  useEffect(() => {
    const setup = async () => {
      if (!account) return;

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(CARD_GAME_ADDRESS, ABI, signer);
      setCardGame(contract);

      const alreadyClaimed = await contract.hasClaimedStarterPack(account);
      setClaimed(alreadyClaimed);

      const balance = await contract.balanceOf(account);
      const userCards = [];

      for (let i = 0; i < balance; i++) {
        const tokenId = await contract.tokenOfOwnerByIndex(account, i);
        const stats = await contract.getCardStats(tokenId);
        userCards.push({ tokenId, stats });
      }

      setCards(userCards);
    };

    setup();
  }, [account]);

  const claimStarterPack = async () => {
    if (!cardGame) return;
    const tx = await cardGame.claimStarterPack();
    await tx.wait();
    window.location.reload();
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
                return (
                  <div key={i} className="card">
                    <h3>Card #{card.tokenId}</h3>
                    <p><b>Class:</b> {classNames[s.classType]}</p>
                    <p><b>Element:</b> {elementNames[s.element]}</p>
                    <p><b>Rarity:</b> {rarityNames[s.rarity]}</p>
                    <p><b>Attack:</b> {s.attack.toString()}</p>
                    <p><b>Defense:</b> {s.defense.toString()}</p>
                  </div>
                );
              })}
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default App;
