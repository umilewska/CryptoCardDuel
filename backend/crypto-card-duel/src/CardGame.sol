// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract CardGame is ERC721URIStorage, VRFConsumerBaseV2, Ownable(msg.sender) {
    using Strings for uint256;

    uint256 public nextTokenId = 1;

    enum Class { Warrior, Mage, Hunter }
    enum Element { Fire, Water, Nature }
    enum Rarity { Common, Rare, Epic, Legendary }

    struct CardStats {
        Class classType;
        Element element;
        Rarity rarity;
        uint8 attack;
        uint8 defense;
    }

    mapping(uint256 => CardStats) public cardStats;
    mapping(address => bool) public hasClaimedStarterPack;
    mapping(uint256 => address) public requestToSender;

    // Player tracking
    mapping(address => bool) public isPlayer;
    address[] public allPlayers;

    // Chainlink VRF config
    VRFCoordinatorV2Interface COORDINATOR;
    uint256 public subscriptionId = 47028878480498157709256904961738289457614625757591967344804338002370054140593;
    bytes32 public keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 public callbackGasLimit = 250000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 5;

    constructor() 
        ERC721("BattleCard", "BCRD") 
        VRFConsumerBaseV2(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) 
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B);
    }

    event StarterPackRequested(address indexed player, uint256 requestId);
    event CardMinted(address indexed to, uint256 tokenId, CardStats stats);

    function claimStarterPack() external {
        require(!hasClaimedStarterPack[msg.sender], "Already claimed");
        hasClaimedStarterPack[msg.sender] = true;

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            uint64(subscriptionId),
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        requestToSender[requestId] = msg.sender;
        emit StarterPackRequested(msg.sender, requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address to = requestToSender[requestId];

        for (uint i = 0; i < randomWords.length; i++) {
            _mintCardWithRandomness(to, randomWords[i]);
        }
    }

    function _mintCardWithRandomness(address to, uint rand) internal {
        uint256 tokenId = nextTokenId++;

        CardStats memory stats = _generateStats(rand, Rarity.Common);
        cardStats[tokenId] = stats;

        _safeMint(to, tokenId);
        string memory uri = string(abi.encodePacked("ipfs://Qm.../", tokenId.toString(), ".json"));
        _setTokenURI(tokenId, uri);

        _trackPlayer(to);
        emit CardMinted(to, tokenId, stats);
    }

    function mintCardWithForcedRarity(address to, uint256 seed, uint8 rarityIndex) external returns (uint256) {
        require(rarityIndex >= 1 && rarityIndex <= 3, "Invalid rarity");

        Class classType = Class(seed % 3);
        Element element = Element((seed / 10) % 3);
        Rarity rarity = Rarity(rarityIndex); // Rare or higher
        uint8 attack = uint8((seed / 100) % 100);
        uint8 defense = uint8((seed / 10000) % 100);

        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);

        cardStats[tokenId] = CardStats(classType, element, rarity, attack, defense);

        _trackPlayer(to);
        return tokenId;
    }

    function _trackPlayer(address player) internal {
        if (!isPlayer[player]) {
            isPlayer[player] = true;
            allPlayers.push(player);
        }
    }

    function getAllPlayers() external view returns (address[] memory) {
        return allPlayers;
    }

    function _generateStats(uint rand, Rarity rarity) internal pure returns (CardStats memory) {
        Class classType = Class(rand % 3);
        Element element = Element((rand / 10) % 3);
        uint8 base = 5;
        uint8 atk = uint8(base + (rand % 3));
        uint8 def = uint8(base + ((rand / 100) % 3));
        return CardStats(classType, element, rarity, atk, def);
    }

    function getCardStats(uint256 tokenId) external view returns (CardStats memory) {
        return cardStats[tokenId];
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        uint256 found = 0;
        uint256 maxId = nextTokenId - 1;

        for (uint256 tokenId = 1; tokenId <= maxId && found < balance; tokenId++) {
            try this.ownerOf(tokenId) returns (address tokenOwner) {
                if (tokenOwner == owner) {
                    tokens[found++] = tokenId;
                }
            } catch {}
        }

        return tokens;
    }
}
