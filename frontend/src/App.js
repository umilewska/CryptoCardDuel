import React, { useEffect, useState } from 'react';

function App() {
  const [cards, setCards] = useState([]);

  useEffect(() => {
    fetch("http://localhost:5000/api/cards")
      .then(res => res.json())
      .then(data => setCards(data));
  }, []);

  return (
    <div style={{ padding: '20px' }}>
      <h1>My NFT Cards</h1>
      <ul>
        {cards.map(card => (
          <li key={card.id}>
            <strong>{card.name}</strong> (ATK: {card.attack}, DEF: {card.defense}, Rarity: {card.rarity})
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
