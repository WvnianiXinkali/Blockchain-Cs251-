// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {IAaveSupplier} from "src/3-aave/interfaces/IAaveSupplier.sol";
import {AaveAddresses} from "src/3-aave/AaveAddresses.sol";

// Minimal interfaces for Aave V3 and ERC20
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

abstract contract AaveSupplierTestBase is Test {
    uint256 constant TOLERANCE = 1e10; // 0.0001%

    using AaveAddresses for address;

    IAaveSupplier public aaveSupplier;

    address public owner;
    address public recipient;

    function setUp() public virtual {
        // Fork mainnet at a recent block
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 20_000_000);
        

        owner = makeAddr("owner");
        recipient = makeAddr("recipient");
    }

    function formatValue(uint256 value, uint256 decimals) internal pure returns (string memory) {
        uint256 integralPart = value / 10 ** decimals;
        uint256 residualPart = value - integralPart * 10 ** decimals;
        uint256 fractionalPart = residualPart / 10 ** (decimals - 2); // 2 decimal places
        return string(abi.encodePacked(vm.toString(integralPart), ".", vm.toString(fractionalPart)));
    }

    function deploySupplier() public virtual returns (IAaveSupplier);

    function test_deposit_usdc_to_aave() public {
        // 1000 USDC (6 decimals)
        uint256 depositAmount = 1000e6;

        // Set USDC balance using deal
        deal(AaveAddresses.USDC, address(aaveSupplier), depositAmount);

        // Check initial balances
        assertEq(IERC20(AaveAddresses.aUSDC).balanceOf(address(aaveSupplier)), 0);
        assertEq(IERC20(AaveAddresses.USDC).balanceOf(address(aaveSupplier)), depositAmount);

        // Deposit to Aave
        vm.prank(owner);
        aaveSupplier.depositERC20(AaveAddresses.USDC, depositAmount);

        // Verify we received aTokens
        // Note: Aave V3 uses RAY precision (1e27) internally, causing minor rounding
        // The rounding error is proportional to the amount: typically a few wei
        uint256 aTokenBalance = IERC20(AaveAddresses.aUSDC).balanceOf(address(aaveSupplier));
        assertApproxEqRel(aTokenBalance, depositAmount, TOLERANCE);

        // Verify USDC was transferred out
        uint256 usdcBalance = IERC20(AaveAddresses.USDC).balanceOf(address(aaveSupplier));
        assertEq(usdcBalance, 0);
    }

    function test_withdraw_usdc_plus_yield_from_aave() public {
        uint256 initialBalance = 1000e6;
        deal(AaveAddresses.USDC, address(aaveSupplier), initialBalance);

        vm.prank(owner);
        aaveSupplier.depositERC20(AaveAddresses.USDC, initialBalance);

        vm.warp(block.timestamp + 30 days);
        uint256 balanceAfter30Days = IERC20(AaveAddresses.aUSDC).balanceOf(address(aaveSupplier));

        assertGt(balanceAfter30Days, initialBalance);

        vm.prank(owner);
        aaveSupplier.withdrawERC20(AaveAddresses.USDC, balanceAfter30Days, recipient);

        uint256 usdcBalance = IERC20(AaveAddresses.USDC).balanceOf(recipient);
        uint256 yieldEarned = usdcBalance - initialBalance;
        uint256 apyBasisPoints = (yieldEarned * 12 * 100 * 1e6) / initialBalance;

        // Log the yield for visibility
        console.log("=== Yield Test Results ===");
        console.log("Initial USDC balance:   ", formatValue(initialBalance, 6));
        console.log("USDC balance after 30d: ", formatValue(balanceAfter30Days, 6));
        console.log("Yield earned (USDC):    ", formatValue(yieldEarned, 6));
        console.log("Estimated APY (%):     ", formatValue(apyBasisPoints, 6));

        assertGt(yieldEarned, 0);
    }

    function test_deposit_native_eth() public {
        // give some initial ETH to the supplier contract
        uint256 initialBalance = 2 ether;
        vm.deal(address(aaveSupplier), initialBalance);

        uint256 depositAmount = 1 ether;

        // transfer ETH to the owner, who transfers it to the supplier contract
        hoax(owner);
        aaveSupplier.depositEth{value: depositAmount}();

        // Verify we received aTokens (allowing for Aave's rounding)
        uint256 aTokenBalance = IERC20(AaveAddresses.aWETH).balanceOf(address(aaveSupplier));
        assertApproxEqRel(aTokenBalance, depositAmount + initialBalance, TOLERANCE);

        // Verify that AaveSupplier's ETH/WETH balance is 0
        assertEq(address(aaveSupplier).balance, 0);
        assertEq(IERC20(AaveAddresses.WETH).balanceOf(address(aaveSupplier)), 0);
    }

    function test_withdraw_native_eth_plus_yield() public {
        // Deposit a significant amount to see meaningful yield
        uint256 initialBalance = 100 ether;

        hoax(owner);
        aaveSupplier.depositEth{value: initialBalance}();

        // Simulate 30 days passing
        vm.warp(block.timestamp + 30 days);

        // Check balance after time has passed
        uint256 balanceAfter30Days = IERC20(AaveAddresses.aWETH).balanceOf(address(aaveSupplier));

        // aToken balance should have increased due to yield
        assertGt(balanceAfter30Days, initialBalance);

        // Withdraw everything (principal + yield)
        vm.prank(owner);
        aaveSupplier.withdrawEth(recipient);

        // Verify that AaveSupplier's WETH+aWETH balance is 0
        assertEq(IERC20(AaveAddresses.WETH).balanceOf(address(aaveSupplier)), 0);
        assertEq(IERC20(AaveAddresses.aWETH).balanceOf(address(aaveSupplier)), 0);

        assertApproxEqRel(recipient.balance, balanceAfter30Days, TOLERANCE);

        uint256 yieldEarned = recipient.balance - initialBalance;
        uint256 apyBasisPoints = (yieldEarned * 12 * 100 * 1e18) / initialBalance;

        // Log the yield for visibility
        console.log("=== Yield Test Results ===");
        console.log("Initial ETH balance:   ", formatValue(initialBalance, 18));
        console.log("ETH balance after 30d: ", formatValue(balanceAfter30Days, 18));
        console.log("Yield earned (ETH):    ", formatValue(yieldEarned, 18));
        console.log("Estimated APY (%):     ", formatValue(apyBasisPoints, 18));

        assertGt(yieldEarned, 0);
    }
}

