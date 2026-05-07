// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "src/3-aave/interfaces/IAaveSupplier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "src/3-aave/AaveAddresses.sol";
import "src/3-aave/interfaces/IWETH.sol";
import "src/3-aave/interfaces/IPool.sol";

contract AaveSupplier is IAaveSupplier {
    constructor() {
        // ...
    }

    function depositERC20(address asset, uint256 amount) external {
        // ...
        IERC20(asset).approve(address(AaveAddresses.POOL), amount);
        IPool(AaveAddresses.POOL).supply(asset, amount, address(this), 0);
    }

    function withdrawERC20(
        address asset,
        uint256 amount,
        address recipient
    ) external {
        // ...
        IPool(AaveAddresses.POOL).withdraw(asset, amount, recipient);
    }

    function depositEth() external payable {
        // ...
        uint256 balance = address(this).balance;
        IWETH(AaveAddresses.WETH).deposit{value: balance}();
        IERC20(AaveAddresses.WETH).approve(AaveAddresses.POOL, balance);
        IPool(AaveAddresses.POOL).supply(
            AaveAddresses.WETH,
            balance,
            address(this),
            0
        );
    }

    function withdrawEth(address recipient) external returns (uint256) {
        // ...
        uint256 withdrawn = IPool(AaveAddresses.POOL).withdraw(
            AaveAddresses.WETH,
            type(uint256).max,
            address(this)
        );
        IWETH(AaveAddresses.WETH).withdraw(withdrawn);
        (bool ok, ) = recipient.call{value: withdrawn}("");
        require(ok, "eth send failed");
        return withdrawn;
    }

    receive() external payable {}

    fallback() external payable {}
}
