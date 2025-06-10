// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract CardGame is ERC721URIStorage, Ownable(msg.sender) {
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

    constructor() ERC721("BattleCard", "BCRD") {}

    function claimStarterPack() external {
        require(!hasClaimedStarterPack[msg.sender], "Already claimed");
        hasClaimedStarterPack[msg.sender] = true;

        for (uint i = 0; i < 5; i++) {
            _mintRandomCard(msg.sender);
        }
    }

    function _mintRandomCard(address to) internal {
        uint256 tokenId = nextTokenId++;
        CardStats memory stats = generateCard(tokenId, Rarity.Common);
        cardStats[tokenId] = stats;

        _safeMint(to, tokenId);
        string memory uri = string(abi.encodePacked("ipfs://Qm.../", tokenId.toString(), ".json"));
        _setTokenURI(tokenId, uri);
    }

    function generateCard(uint seed, Rarity rarity) internal pure returns (CardStats memory) {
        uint rand = uint(keccak256(abi.encodePacked(seed)));
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
}