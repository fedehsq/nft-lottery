// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./NFT.sol";

/*
Before operating the lottery, the lottery manager buys a batch of collectibles,
and mints a Non Fungible Token (NFT) for each of them.
A new round may only be opened by the lottery operator.
Opening a new round is allowed the first time, when the contract has 
been deployed, or when a previous round is finished.
*/
contract Lottery {
    address public manager;
    uint public roundDuration;
    uint public startBlockNumber;
    uint constant ACTIVE = 1;
    uint constant FINISHED = 0;
    uint public roundStatus = FINISHED;
    NFT public nft;

    // an user buys a set of tickets and picks six numbers per ticket. The
    // first five numbers are standard numbers from 1- 69, and the sixth number is a
    // special Powerball number from 1 - 26 that offers extra rewards.
    // Each ticket has a fixed price.
    struct Ticket {
        uint256 id;
        uint256[5] numbers;
        uint256 powerball;
        address owner;
    }

    // batch of collectibles and mints a Non Fungible Token (NFT) for each of them and defines the value rank of that collectible.
    // The collectibles are divided into eight classes (not eleven), each class corresponding to the matches of numbers in a draw.
    // The assignment of the collectibles to the classes is random
    struct Collectible {
        string image;
        uint256 class;
    }

    // Array of collectibles 
    Collectible[] collectibles;

    // Mapping between the id of the ticket and the owner of the ticket
    mapping(uint256 => address) ticketsOwners;

    // Mapping between the id of the ticket and the ticket
    mapping(uint256 => Ticket) tickets;

    /// @notice msg.sender is the owner of the contract
    /// @param _startBlockNumber The block number when the contract starts.
    /// @param _roundDuration The duration of the round in block numbers.
    constructor(address _t, uint _roundDuration, uint _startBlockNumber) {
        manager = msg.sender;
        nft = NFT(_t);
        roundDuration = _roundDuration;
        startBlockNumber = _startBlockNumber;
    }

    
    /// @notice The lottery operator can open a new round.
    /// The lottery operator can only open a new round if the previous round is finished.
    /// @dev Throws unless `msg.sender` is the current owner or the lottery is not finished
    function openRound() public {
        require(msg.sender == manager);
        require(roundStatus == FINISHED, "Previous round is not finished");
        roundStatus = ACTIVE;
    }


    /// @notice The lottery operator can mint new token.
    /// @dev Throws unless `msg.sender` is the current owner or the class (rank) is not valid
    function mint(string memory _image, uint256 _class) public {
        require(msg.sender == manager);
        require(_class >= 1 && _class <= 8);
        collectibles.push(Collectible(_image, _class));
        // id of the collectible is the index of the collectible in the array
        uint256 id = collectibles.length;
        nft.mint(id);
    }

    /// @notice The user can buy a ticket.
    /// @dev Throws unless `one`, `two`, `three`, `four`, `five`, `six` are valid numbers
    /// @dev Throws unless `msg.sender` has enough ether to buy the ticket
    /// @dev Throws unless `ticket` is unique
    function buy(uint256 one, uint256 two, uint256 three, uint256 four, uint256 five, uint256 six) public payable {
        require(roundStatus == ACTIVE, "Round is not active");
        require(msg.value >= 1, "You need to send at least 1 wei");
        require(one >= 1 && one <= 69, "Invalid number");
        require(two >= 1 && two <= 69, "Invalid number");
        require(three >= 1 && three <= 69, "Invalid number");
        require(four >= 1 && four <= 69, "Invalid number");
        require(five >= 1 && five <= 69, "Invalid number");
        require(six >= 1 && six <= 26, "Invalid number");
        uint256 id = one + two + three + four + five + six;
        require(ticketsOwners[id] == address(0), "Ticket already bought");
        ticketsOwners[id] = msg.sender;
        tickets[id] = Ticket({
            id: id,
            numbers: [one, two, three, four, five],
            powerball: six,
            owner: msg.sender
        });
    }

}
