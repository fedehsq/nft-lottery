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
contract CollectibleNFT is ERC721 {
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
    mapping(uint256 => address) collectibleOwners;

    // owner of the token - number of nfts owned by the owner
    mapping(address => uint256) collectibleBalances;

    // delegate someone else to send the nft
    mapping(uint256 => address) collectibleApproved;

    function addCollectible(
        uint256 _rank,
        string memory _image,
        uint256 _class
    ) public {
        require(_rank > 0);
        require(_class > 0);
        require(_class <= 8);
        collectibles.push(Collectible(_rank, _image, _class));
        // id of the collectible is the index of the collectible in the array
        uint256 id = collectibles.length - 1;
        collectibleOwners[id] = msg.sender;
        collectibleBalances[msg.sender]++;
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        return collectibleOwners[_tokenId];
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return collectibleBalances[_owner];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable override {
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
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId)
        external
        payable
        override
    {
        require(msg.sender == collectibleOwners[_tokenId]);
        require(_tokenId > 0);
        require(_tokenId <= collectibles.length);
        collectibleApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getApproved(uint _tokenId) public view override returns (address) {
        require(_tokenId > 0 && _tokenId <= collectibles.length, "tokenId is not valid");
        return collectibleApproved[_tokenId];
    }
}
