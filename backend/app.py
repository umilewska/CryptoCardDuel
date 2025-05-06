from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # pozwala na połączenie z frontendu React

@app.route("/api/cards", methods=["GET"])
def get_cards():
    # Na start: zwróć przykładowe dane kart
    sample_cards = [
        {"id": 1, "name": "Flametail", "attack": 12, "defense": 8, "rarity": "Rare"},
        {"id": 2, "name": "Aqualord", "attack": 10, "defense": 10, "rarity": "Epic"}
    ]
    return jsonify(sample_cards)

@app.route("/api/mint", methods=["POST"])
def mint_card():
    data = request.json
    # Tutaj możesz później dodać kod do interakcji z blockchainem
    return jsonify({"message": f"Card {data['name']} minted!"})

if __name__ == "__main__":
    app.run(debug=True)
