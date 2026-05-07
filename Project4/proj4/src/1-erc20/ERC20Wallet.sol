// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "src/1-erc20/interfaces/IERC20Wallet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Wallet is IERC20Wallet {
    address public owner;

    // ... your code here
    constructor() {
        owner = msg.sender;
    }

    error NotAuthorized();

    function transferEth(address payable recipient, uint256 amount) external {
        // ... your code here
        if (msg.sender != owner) revert NotAuthorized();
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function transferERC20(
        address token,
        address recipient,
        uint256 amount
    ) external {
        // ... your code here
        if (msg.sender != owner) revert NotAuthorized();
        IERC20 erc20 = IERC20(token);
        if (erc20.balanceOf(address(this)) < amount) revert FailedTransfer();
        require(amount > 0, "Amount must be greater than zero");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );
        require(success, "transfer failed");
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "transfer returned false");
        }
    }

    function approveERC20(
        address token,
        address spender,
        uint256 amount
    ) external {
        // ... your code here
        if (msg.sender != owner) revert NotAuthorized();
        IERC20(token).approve(spender, 0);
        if (amount > 0) {
            IERC20(token).approve(spender, amount);
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
