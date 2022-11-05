// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
NOTE: cannot use blockhash in Remix so use ganache-cli

npm i -g ganache-cli
ganache-cli
In remix switch environment to Web3 provider
*/

/*
GuessTheRandomNumber is a game where you win 1 Ether if you can guess the
pseudo random number generated from block hash and timestamp.

At first glance, it seems impossible to guess the correct number.
But let's see how easy it is win.

1. Alice deploys GuessTheRandomNumber with 1 Ether
2. Eve deploys Attack
3. Eve calls Attack.attack() and wins 1 Ether

What happened?
Attack computed the correct answer by simply copying the code that computes the random number.
*/

//in order to remove this vulnerability we should not generate random numbers on the blockchain
//we have to get them from outside with oracle (ProvableAPI)

import "./provableAPI_0.5.sol";

contract GuessTheRandomNumber is usingProvable {
    constructor() payable {}

    function guess(uint _guess) public {
        //generate a query id that can be use for checking and proving validity
        uint QUERY_EXECUTION_DELAY = 0;
        uint NUM_RANDOM_BYTES_REQUESTED = 64;
        uint GAS_FOR_CALLBACK = 200000;
        bytes32 queryId = provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );
        //ceiling can be calculated
        //uint ceiling = (MAX_INT_FROM_BYTE ** NUM_RANDOM_BYTES_REQUESTED) - 1;
        uint ceiling = 1;
        string memory seed = "21ct43rjhnb32ds";

        uint answer = uint(
            uint(keccak256(abi.encodePacked(seed))) % ceiling
        );

        if (_guess == answer) {
            (bool sent, ) = msg.sender.call{value: 1 ether}("");
            require(sent, "Failed to send Ether");
        }
    }
}

contract Attack {
    receive() external payable {}

    function attack(GuessTheRandomNumber guessTheRandomNumber) public {
        uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))
        );

        guessTheRandomNumber.guess(answer);
    }

    // Helper function to check balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
