// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

// Inheriting from ERC20 and Ownable
contract CryptoDevToken is ERC20, Ownable {
    // price of one crypto dev token
    uint256 public constant tokenPrice = 0.001 ether;

    // Number of tokens per NFT.
    uint256 public constant tokensPerNFT = 10 * (10**18);

    // The max total supply is 1000 for Crypto Dev Tokens
    uint256 public constant maxTotalSupply =  10000 * 10**18;

    // CryptoDevNFT contract instance
    ICryptoDevs CryptoDevsNFT;

    // Mapping to keep track of which tokens (with their ids) have been claimed.
    mapping(uint256 => bool) public tokenIdsClaimed;

    // Here in the contructor we are assigning CryptoDevsNFT to an instance of ICryptoDevs by passing and address
    constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD") {
        CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
    }

    // A function that mints the 'amount' number of CryptoDevTokens
    // Requirements
    // msg.value should be => tokenPrice * amount
    function mint(uint256 amount) public payable {
        // The required amount of the transaction
        uint256 _requiredAmount = tokenPrice * amount;
        require(msg.value >= _requiredAmount, "Ether sent is incorrect");
        // amount of tokens in decimals
        uint256 amountWithDecimals = amount * (10**18);

        // If the total supply of tokens + amount <= maxTotalSupply then continue otherwise revert the transaction.
        require(
            totalSupply() + amountWithDecimals <= maxTotalSupply,
            "Exceeds the max total supply available"
        );

        // calling the internal mint function from the Openzeppelin ERC20 contract
        // mint (amount * 10) tokens for each NFT.
        _mint(msg.sender, amount * tokensPerNFT);
    }

    // function that mints tokens based on the number of NFTs send by the user.
    // Requirements -> balance of CryptoDev NFT owned by the sender should be greater than 0.
    // Tokens should not have been claimed for all the NFTs owned by the sender.
    function claim() public {
        address sender = msg.sender;
        // Get the number of cyptoDev NFTs held by the senders address.
        uint256 balance = CryptoDevsNFT.balanceOf(sender);
        // if the balance is zero, revert the transaction.
        require(balance > 0, "You don't own any CryptoDev NFT's");

        // amount keeps the track of the number of unclaimed tokenIds.
        uint256 amount = 0;

        // loop over the balance and get the token ID owned by the 'sender' at a given 'index' of its token list.
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);

            // if the tokenId has not been claimed, increase the amount.
            if (!tokenIdsClaimed[tokenId]) {
                amount++;
                tokenIdsClaimed[tokenId] = true;
            }

            // If all the token Ids have been claimed, revert the transaction.
            require(amount > 0, "You have already claimed all the tokens");
            _mint(msg.sender, amount * tokensPerNFT);
        }
    }

    // function to withdraw all eth sent to the contract
    // Requirements -> wallet connected must be owner's address.
    function withDraw() public onlyOwner {
        // getting the address of the owner of the contract.
        address _owner = owner();
        // getting the amount sent in 'this' smart contract address.
        uint256 amount = address(this).balance;
        // sending money to the owner's address.
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to sent ether to the owner's account");
    }

    // function to receive ether, msg.data must be empty.
    receive() external payable {}

    // fallback function is called when msg.data is not empty.
    fallback() external payable {}
}
