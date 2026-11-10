// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Treasury {
    address public owner;
    constructor() { owner = msg.sender; }

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }

    function sweep(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }
}
