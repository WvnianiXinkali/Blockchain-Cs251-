// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "src/0-basic/interfaces/IBasicWallet.sol";

contract BasicWallet is IBasicWallet {
    address public owner;

    // ... your code here
    constructor() {
        owner = msg.sender;
    }


    function transferEth(address payable recipient, uint256 amount) external {
        // ... your code here
        if (msg.sender != owner) revert NotAuthorized();
        if (address(this).balance < amount) revert FailedTransfer();
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {}

    fallback() external payable {}
}
