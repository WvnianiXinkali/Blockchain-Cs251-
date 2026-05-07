// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAaveSupplier {
    // deposit ERC20 tokens owned by this contract to Aave
    function depositERC20(address asset, uint256 amount) external;

    // withdraw ERC20 tokens from Aave, send them to the recipient
    function withdrawERC20(address asset, uint256 amount, address recipient) external;

    // wraps the contract balance of ETH to WETH and deposits it to Aave
    function depositEth() external payable;

    // withdraws the contract balance of WETH from Aave, unwraps it to ETH
    // and sends it to the recipient
    function withdrawEth(address recipient) external returns (uint256);
}
