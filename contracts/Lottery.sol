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
    uint256 public startingBlock;
    bool public firstRound;
    bool public prizeAssigned;
    bool public lotteryActive;
    uint256 public constant TICKET_PRICE = 1 gwei;
    NFT public nft;

    // an user buys a set of boughtTickets and picks six numbers per ticket. The
    // first five numbers are standard numbers from 1- 69, and the sixth number is a
    // special Powerball number from 1 - 26 that offers extra rewards.
    // Each ticket has a fixed price.
    struct Ticket {
        uint16 id;
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

    // Mapping between the id of the ticket and the ticket
    mapping(uint16 => bool) boughtTickets;

    Ticket[] tickets;

    Ticket winningTicket;

    /// @notice msg.sender is the owner of the contract
    /// @param _roundDuration The duration of the round in block numbers.
    constructor(
        address _t,
        uint256 _roundDuration
    ) payable {
        manager = msg.sender;
        nft = NFT(_t);
        roundDuration = _roundDuration;
        firstRound = true;
        prizeAssigned = false;
        lotteryActive = true;
    }

    /// @notice The lottery operator can open a new round.
    /// The lottery operator can only open a new round if the previous round is finished.
    /// @dev Throws unless `msg.sender` is the current owner or the lottery is not finished
    /// @dev Throws unless the lottery is active
    function openRound() public {
        require(msg.sender == manager);
        require(lotteryActive, "Lottery is not active");
        // Check if the contract is just deployed
        if (!firstRound) {
            require(!isRoundActive(), "Previous round is not finished");
            prizeAssigned = false;
            delete tickets;
            delete winningTicket;
        } else {
            firstRound = false;
        }
        startingBlock = block.number;
        //winningTicket = Ticket(
        //    0,
        //    [uint8(0), uint8(0), uint8(0), uint8(0), uint8(0)],
        //    uint8(0),
        //    address(0)
        //);
    }

    /// @notice The lottery operator can close the contract.
    /// If the round is active, refunds the users who bought tickets.
    /// @dev Throws unless `msg.sender` is the current owner or the lottery is not finished
    /// @dev Throws unless the lottery is active
    function closeLottery() public {
        require(msg.sender == manager);
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
        require(msg.sender == manager);
        require(lotteryActive, "Lottery is not active");
        uint8 class = uint8((generateRandomNumber() % 8) + 1);
        uint256 id = collectibles[class].length + 1;
        collectibles[class].push(Collectible(id, _image));
        // id of the collectible is the index of the collectible in the array
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
        require(isRoundActive(), "Round is not active");
        require(lotteryActive, "Lottery is not active");
        require(msg.value == TICKET_PRICE, "You need to send at least 1 wei");
        require(_one >= 1 && _one <= 69, "Invalid number");
        require(_two >= 1 && _two <= 69, "Invalid number");
        require(_three >= 1 && _three <= 69, "Invalid number");
        require(_four >= 1 && _four <= 69, "Invalid number");
        require(_five >= 1 && _five <= 69, "Invalid number");
        require(_powerball >= 1 && _powerball <= 26, "Invalid number");
        uint16 id = _one + _two + _three + _four + _five + _powerball;
        require(boughtTickets[id] == false, "Ticket already bought");
        tickets.push(
            Ticket(
                id,
                buildAscendingTicketNumbers(_one, _two, _three, _four, _five),
                _powerball,
                msg.sender
            )
        );
        payable(address(this)).transfer(TICKET_PRICE);
    }

    /// @notice Check if the round is active.
    /// The round is active if:
    ///     1. The current block number minus startingBlock % roundDuration != 0.
    ///     2. The winning ticket has not been drawn yet.
    ///     3. The prizes have not been assigned.
    /// @return True if the round is active, false otherwise.
    function isRoundActive() public view returns (bool) {
        return
            block.number - (startingBlock % roundDuration) != 0 &&
            winningTicket.id == 0 &&
            !prizeAssigned;
    }

    /// @notice Generate a random int starting from the block number.
    /// @return A random int.
    function generateRandomNumber() public view returns (uint256) {
        bytes32 bhash = blockhash(block.number - 1);
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
        require(msg.sender == manager);
        require(!isRoundActive(), "Round is not yet finished");
        require(lotteryActive, "Lottery is not active");
        uint8 one = uint8((generateRandomNumber() % 69) + 1);
        uint8 two = uint8((generateRandomNumber() % 69) + 1);
        uint8 three = uint8((generateRandomNumber() % 69) + 1);
        uint8 four = uint8((generateRandomNumber() % 69) + 1);
        uint8 five = uint8((generateRandomNumber() % 69) + 1);
        uint8 six = uint8((generateRandomNumber() % 26) + 1);
        uint16 id = one + two + three + four + five + six;
        winningTicket = Ticket(
            id,
            buildAscendingTicketNumbers(one, two, three, four, five),
            six,
            address(0)
        );
    }

    /// @notice Distribute the prizes of the current lottery round
    /// @dev Throws unless `msg.sender` is the lottery operator
    /// @dev Throws unless `winner` is not defined
    /// @dev Throws unless `winningTicket` is already drawn
    /// @dev Throws unless the lottery is active
    function givePrizes() public {
        require(msg.sender == manager);
        require(!isRoundActive(), "Round is not yet finished");
        require(lotteryActive, "Lottery is not active");
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
        prizeAssigned = true;
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
        public
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
    function buildAscendingTicketNumbers(
        uint8 _one,
        uint8 _two,
        uint8 _three,
        uint8 _four,
        uint8 _five
    ) internal pure returns (uint8[5] memory) {
        uint8 tmp;
        if (_one > _two) {
            tmp = _one;
            _one = _two;
            _two = tmp;
        }

        if (_one > _three) {
            tmp = _one;
            _one = _three;
            _three = tmp;
        } else if (_two > _three) {
            tmp = _two;
            _two = _three;
            _three = tmp;
        }

        if (_one > _four) {
            tmp = _one;
            _one = _four;
            _four = tmp;
        } else if (_two > _four) {
            tmp = _two;
            _two = _four;
            _four = tmp;
        } else if (_three > _four) {
            tmp = _three;
            _three = _four;
            _four = tmp;
        }

        if (_one > _five) {
            tmp = _one;
            _one = _five;
            _five = tmp;
        } else if (_two > _five) {
            tmp = _two;
            _two = _five;
            _five = tmp;
        } else if (_three > _five) {
            tmp = _three;
            _three = _five;
            _five = tmp;
        } else if (_four > _five) {
            tmp = _four;
            _four = _five;
            _five = tmp;
        }
        return [_one, _two, _three, _four, _five];
    }
}
