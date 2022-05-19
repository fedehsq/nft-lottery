// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";

/*
Before operating the lottery, the lottery manager buys a batch of collectibles,
and mints a Non Fungible Token (NFT) for each of them.
A new round may only be opened by the lottery operator.
Opening a new round is allowed the first time, when the contract has 
been deployed, or when a previous round is finished.
*/
contract Lottery is ERC721 {
    address public manager;

    // an user buys a set of tickets and picks six numbers per ticket. The
    // first five numbers are standard numbers from 1- 69, and the sixth number is a
    // special Powerball number from 1 - 26 that offers extra rewards.
    // Each ticket has a fixed price.
    struct Ticket {
        uint256[5] numbers;
        uint256 powerball;
        uint256 price;
        address owner;
    }

    // batch of collectibles and mints a Non Fungible Token (NFT) for each of them and defines the value rank of that collectible.
    // The collectibles are divided into eight classes (not eleven), each class corresponding to the matches of numbers in a draw.
    // The assignment of the collectibles to the classes is random
    struct Collectible {
        uint256 rank;
        string image;
        uint256 class;
    }

    // Array of collectibles 
    Collectible[] collectibles;

    // tokenId - owner of the token 
    mapping(uint => address) collectibleOwners;

    // owner of the token - number of nfts owned by the owner
    mapping(address => uint) collectibleBalances;

    // delegate someone else to send the nft
    mapping(uint => address) collectibleApproved;

    // array of tickets
    Ticket[] tickets;

    constructor() {
        manager = msg.sender;
    }

    function mint(uint256 _rank, string memory _image, uint256 _class) public {
        require(msg.sender == manager);
        require(_rank > 0);
        require(_class > 0);
        require(_class <= 8);
        collectibles.push(Collectible(_rank, _image, _class));
        // id of the collectible is the index of the collectible in the array
        uint id = collectibles.length - 1;
        collectibleOwners[id] = msg.sender;
        collectibleBalances[msg.sender]++;
    }

    function ownerOf(uint256 _tokenId) public override view returns (address) {
        return collectibleOwners[_tokenId];
    }

    function balanceOf(address _owner) public override view returns (uint256) {
        return collectibleBalances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override payable {
        //require(msg.sender == manager);
        require(_from == msg.sender || _from == collectibleApproved[_tokenId]);
        require(_to != _from);
        require(_tokenId > 0);
        require(_tokenId <= collectibles.length);
        require(collectibleOwners[_tokenId] == _from);
        require(collectibleBalances[_from] > 0);
        collectibleOwners[_tokenId] = _to;
        collectibleBalances[_from]--;
        collectibleBalances[_to]++;
    }

      function approve(address _approved, uint256 _tokenId) external override payable {
        require(msg.sender == collectibleOwners[_tokenId]);
        require(_tokenId > 0);
        require(_tokenId <= collectibles.length);
        collectibleApproved[_tokenId] = _approved;
      }

}
