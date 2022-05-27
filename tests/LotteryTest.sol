// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "hardhat/console.sol";
import "../contracts/Lottery.sol";

contract LotteryTest {
    bytes32[] proposalNames;

    Lottery lottery;

    function beforeAll(address nftAddress) public {
        lottery = new Lottery(nftAddress, 50);
    }

    function mint() public {
        console.log("Minting 50 tokens");
        for (uint i = 0; i < 50; i++) {
            lottery.mint();
        }
    }

    function buyTickets() public {
        console.log("Buying 50 tickets");
        for (uint i = 0; i < 50; i++) {
            uint256 one = lottery.generateRandomNumber() % 69 + 1;
            uint256 two = lottery.generateRandomNumber() % 69 + 1;
            uint256 three = lottery.generateRandomNumber() % 69 + 1;
            uint256 four = lottery.generateRandomNumber() % 69 + 1;
            uint256 five = lottery.generateRandomNumber() % 69 + 1;
            uint256 six = lottery.generateRandomNumber() % 26 + 1;
            lottery.buy(one, two, three, four, five, six);
        }
    }

    function draw() public {
        console.log("Drawing a number");
        lottery.drawNumbers();
    }

    function givePrizes() public {
        console.log("Giving prizes");
        lottery.givePrizes();
    }

}
