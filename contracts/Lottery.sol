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
    address[] public winners;

    uint256 public roundDuration;
    uint256 public endRoundBlock;

    bool public lotteryActive;
    bool public numbersExtracted;
    bool public roundFinished;

    uint256 public constant TICKET_PRICE = 1 gwei;
    NFT public nft;

    // an user buys a set of boughtTickets and picks six numbers per ticket. The
    // first five numbers are standard numbers from 1- 69, and the sixth number is a
    // special Powerball number from 1 - 26 that offers extra rewards.
    // Each ticket has a fixed price.
    struct Ticket {
        uint8[5] numbers;
        uint8 powerball;
        address owner;
    }

    // batch of collectibles and mints a Non Fungible Token (NFT) for each of them and defines the value rank of that collectible.
    // The collectibles are divided into eight classes (not eleven), each class corresponding to the matches of numbers in a draw.
    // The assignment of the collectibles to the classes is random
    struct Collectible {
        uint256 id;
        string image;
    }

    // Mapping between the class that the collectible belongs to and the collectible
    mapping(uint8 => Collectible[]) collectibles;

    Ticket[] public tickets;

    Ticket public winningTicket;

    /// @notice msg.sender is the owner of the contract
    /// @param _nftAddress address of the nft contract
    /// @param _roundDuration The duration of the round in block numbers.
    constructor(address _nftAddress, uint256 _roundDuration) payable {
        manager = msg.sender;
        nft = NFT(_nftAddress);
        roundDuration = _roundDuration;
        lotteryActive = true;
        // Open the furst new round
        endRoundBlock = block.number + roundDuration;
    }

    /// @notice The lottery operator can open a new round.
    /// The lottery operator can only open a new round if the previous round is finished.
    /// @dev Throws unless `msg.sender` is the current owner or the lottery is not finished
    /// @dev Throws unless the lottery is active
    /// @dev Throws if the round is yet open
    function openRound() public {
        require(lotteryActive, "Lottery is not active");
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(!isRoundActive(), "Round is already active");
        require(numbersExtracted, "Numbers have not been extracted yet");
        require(roundFinished, "Round is not finished yet");
        delete tickets;
        delete winningTicket;
        roundFinished = false;
        numbersExtracted = false;
        endRoundBlock = block.number + roundDuration;
    }

    /// @notice The lottery operator can close the contract.
    /// If the round is active, refunds the users who bought tickets.
    /// @dev Throws unless `msg.sender` is the current owner or the lottery is not finished
    /// @dev Throws unless the lottery is active
    function closeLottery() public {
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(lotteryActive, "Lottery is not active");
        if (isRoundActive()) {
            for (uint256 i = 0; i < tickets.length; i++) {
                payable(tickets[i].owner).transfer(TICKET_PRICE);
            }
        }
        lotteryActive = false;
    }

    /// @notice The lottery operator can mint new token.
    /// @dev Throws unless `msg.sender` is the current owner or the class (rank) is not valid
    /// @dev Throws unless the lottery is active
    /// @param _image The image of the collectible
    function mint(string memory _image) public {
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(lotteryActive, "Lottery is not active");
        uint8 class = uint8((generateRandomNumber() % 8) + 1);
        // id of the collectible is the index of the collectible in the array
        uint256 id = collectibles[class].length + 1;
        collectibles[class].push(Collectible(id, _image));
        nft.mint(id, _image);
    }

    /// @notice The user can buy a ticket.
    /// @dev Throws unless `one`, `two`, `three`, `four`, `five`, `six` are valid numbers
    /// @dev Throws unless `msg.sender` has enough ether to buy the ticket
    /// @dev Throws unless `ticket` is unique
    /// @dev Throws unless the lottery is active
    /// @param _one The first number of the ticket
    /// @param _two The second number of the ticket
    /// @param _three The third number of the ticket
    /// @param _four The fourth number of the ticket
    /// @param _five The fifth number of the ticket
    /// @param _powerball The special powerball number of the ticket
    function buy(
        uint8 _one,
        uint8 _two,
        uint8 _three,
        uint8 _four,
        uint8 _five,
        uint8 _powerball
    ) public payable {
        require(lotteryActive, "Lottery is not active");
        require(isRoundActive(), "Round is not active");
        require(msg.value == TICKET_PRICE, "You need to send 1 gwei");
        require(_one >= 1 && _one <= 69, "Invalid number");
        require(_two >= 1 && _two <= 69, "Invalid number");
        require(_three >= 1 && _three <= 69, "Invalid number");
        require(_four >= 1 && _four <= 69, "Invalid number");
        require(_five >= 1 && _five <= 69, "Invalid number");
        require(_powerball >= 1 && _powerball <= 26, "Invalid number");
        //uint16 id = _one + _two + _three + _four + _five + _powerball;
        tickets.push(
            Ticket(
                sortTicketNumbers(_one, _two, _three, _four, _five),
                _powerball,
                msg.sender
            )
        );
    }

    /// @notice Check if the round is active.
    /// The round is active if the current block number < endRoundBlock
    /// @return True if the round is active, false otherwise.
    function isRoundActive() public view returns (bool) {
        return endRoundBlock >= block.number;
    }

    /// @notice Generate a random int starting from the block number.
    /// @return A random int.
    function generateRandomNumber() public view returns (uint256) {
        bytes32 bhash = blockhash(block.number + 1);
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = bhash[i];
        }
        bytes32 rand = keccak256(bytesArray);
        return uint256(rand);
    }

    /// @notice Draw winning numbers of the current lottery round
    /// @dev Throws unless `msg.sender` is the lottery operator
    /// @dev Throws unless `winner` is not defined
    /// @dev Throws unless `winningTicket` is not defined
    /// @dev Throws unless the lottery is active
    function drawNumbers() public {
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(lotteryActive, "Lottery is not active");
        require(!isRoundActive(), "Round is not yet finished");
        require(!roundFinished, "Round is already finished");
        require(!numbersExtracted, "Won numbers are already drawn");

        uint8 one = uint8((generateRandomNumber() % 69) + 1);
        uint8 two = uint8((generateRandomNumber() % 69) + 1);
        uint8 three = uint8((generateRandomNumber() % 69) + 1);
        uint8 four = uint8((generateRandomNumber() % 69) + 1);
        uint8 five = uint8((generateRandomNumber() % 69) + 1);
        uint8 six = uint8((generateRandomNumber() % 26) + 1);
        //uint16 id = one + two + three + four + five + six;
        winningTicket = Ticket(
            sortTicketNumbers(one, two, three, four, five),
            six,
            address(0)
        );
        numbersExtracted = true;
    }

    /// @notice Distribute the prizes of the current lottery round
    /// @dev Throws unless `msg.sender` is the lottery operator
    /// @dev Throws unless `winner` is not defined
    /// @dev Throws unless `winningTicket` is already drawn
    /// @dev Throws unless the lottery is active
    function givePrizes() public {
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(lotteryActive, "Lottery is not active");
        require(!isRoundActive(), "Round is not yet finished");
        require(numbersExtracted, "Won numbers are not drawn");
        for (uint256 i = 0; i < tickets.length; i++) {
            // Check how many numbers count the winning ticket numbers
            uint8 count = 0;
            bool found = false;
            bool powerballMatch = false;
            for (uint256 j = 0; j < 5; j++) {
                if (tickets[i].numbers[j] == winningTicket.numbers[j]) {
                    found = true;
                    count++;
                }
                // Check if the powerball matches the winning ticket powerball
                if (tickets[i].powerball == winningTicket.powerball) {
                    found = true;
                    powerballMatch = true;
                }
                if (found) {
                    winners.push(tickets[i].owner);
                    uint8 classPrize = getClassPrize(count, powerballMatch);
                    uint256 collectibleIndex = generateRandomNumber() %
                        collectibles[classPrize].length;
                    nft.transferFrom(
                        msg.sender,
                        tickets[i].owner,
                        collectibles[classPrize][collectibleIndex].id
                    );
                }
            }
        }
        roundFinished = true;
        sendCoin();
    }

    /// @notice Send the prize to one random winner if it exists otherwise send it to the a random user
    function sendCoin() internal {
        if (winners.length > 0) {
            // Send the prize to one winner in a random way
            uint256 winnerIndex = generateRandomNumber() % winners.length;
            payable(winners[winnerIndex]).transfer(
                tickets.length * TICKET_PRICE
            );
        } else {
            // Send the prize to one user in a random way
            uint256 winnerIndex = generateRandomNumber() % tickets.length;
            payable(tickets[winnerIndex].owner).transfer(
                tickets.length * TICKET_PRICE
            );
        }
    }

    /// @notice Get the class prize of the current lottery round based on the number of matching numbers
    /// @param _count The number of matching numbers
    /// @param _powerballMatch True if the powerball matches the winning ticket powerball, false otherwise
    /// @dev Throws unless the lottery is active
    /// @return The class prize
    function getClassPrize(uint8 _count, bool _powerballMatch)
        internal
        view
        returns (uint8)
    {
        require(lotteryActive, "Lottery is not active");
        if (_count == 5) {
            if (_powerballMatch) {
                return 1;
            }
            return 2;
        } else if (_count == 4) {
            if (_powerballMatch) {
                return 3;
            }
            return 4;
        } else if (_count == 3) {
            if (_powerballMatch) {
                return 4;
            }
            return 5;
        } else if (_count == 2) {
            if (_powerballMatch) {
                return 5;
            }
            return 6;
        } else if (_count == 1) {
            if (_powerballMatch) {
                return 6;
            }
            return 7;
        } else if (_powerballMatch) {
            return 8;
        }
        return 0;
    }

    /// @notice Build the tickets number in ascending order
    /// @param _one The first number
    /// @param _two The second number
    /// @param _three The third number
    /// @param _four The fourth number
    /// @param _five The fifth number
    /// @return The ticket numbers in ascending order
    function sortTicketNumbers(
        uint8 _one,
        uint8 _two,
        uint8 _three,
        uint8 _four,
        uint8 _five
    ) internal pure returns (uint8[5] memory) {
        // Order the numbers in ascending order
        uint8[5] memory numbers = [_one, _two, _three, _four, _five];
        uint8 temp;
        for (uint256 i = 0; i < numbers.length; i++) {
            for (uint256 j = i + 1; j < numbers.length; j++) {
                if (numbers[i] > numbers[j]) {
                    temp = numbers[i];
                    numbers[i] = numbers[j];
                    numbers[j] = temp;
                }
            }
        }
        return numbers;
    }
}
