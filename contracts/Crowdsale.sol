// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";

contract Crowdsale {
    address public owner;
    Token public token;
    uint256 public price;
    uint256 public maxTokens;
    uint256 public tokensSold;
    uint256 public startTime; // Timestamp d'ouverture du crowdsale

    mapping(address => bool) private whitelist;

    event Buy(uint256 amount, address buyer);
    event Finalize(uint256 tokensSold, uint256 ethRaised);
    event Whitelisted(address indexed user);
    event StartTimeUpdated(uint256 newStartTime);

    constructor(
        Token _token,
        uint256 _price,
        uint256 _maxTokens,
        uint256 _startTime // Nouvelle variable pour définir l'heure d'ouverture
    ) {
        owner = msg.sender;
        token = _token;
        price = _price;
        maxTokens = _maxTokens;
        startTime = _startTime; // Initialisation de l'heure d'ouverture
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Caller is not whitelisted");
        _;
    }

    modifier isOpen() {
        require(block.timestamp >= startTime, "Crowdsale has not opened yet");
        _;
    }

    // Modifier l'heure d'ouverture (seulement par l'owner)
    function updateStartTime(uint256 _startTime) public onlyOwner {
        require(_startTime > block.timestamp, "Start time must be in the future");
        startTime = _startTime;
        emit StartTimeUpdated(_startTime);
    }

    // Ajouter un utilisateur à la whitelist
    function addToWhitelist(address _user) public onlyOwner {
        require(!whitelist[_user], "User is already whitelisted");
        whitelist[_user] = true;
        emit Whitelisted(_user);
    }

    // Vérifier si une adresse est whitelisted
    function isWhitelisted(address _user) public view returns (bool) {
        return whitelist[_user];
    }

    // Acheter des tokens (restreint aux utilisateurs whitelistés et si le crowdsale est ouvert)
    function buyTokens(uint256 _amount) public payable onlyWhitelisted isOpen {
        require(msg.value == (_amount / 1e18) * price, "Incorrect Ether value sent");
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens available");
        require(token.transfer(msg.sender, _amount), "Token transfer failed");

        tokensSold += _amount;

        emit Buy(_amount, msg.sender);
    }

    // Permettre l'achat direct via l'envoi d'Ether
    receive() external payable onlyWhitelisted isOpen {
        uint256 amount = msg.value / price;
        buyTokens(amount * 1e18);
    }

    // Modifier le prix des tokens
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // Finaliser la vente
    function finalize() public onlyOwner {
        require(token.transfer(owner, token.balanceOf(address(this))), "Token transfer to owner failed");

        uint256 value = address(this).balance;
        (bool sent, ) = owner.call{value: value}("");
        require(sent, "Ether transfer to owner failed");

        emit Finalize(tokensSold, value);
    }
}
