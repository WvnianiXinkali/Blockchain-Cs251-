// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {IERC20Wallet} from "src/1-erc20/interfaces/IERC20Wallet.sol";
import {BasicERC20} from "src/1-erc20/BasicERC20.sol";

contract USDTMock {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    constructor(uint256 initialBalance) {
        balanceOf[msg.sender] = initialBalance;
    }

    /// @notice does not return anything on transfer
    function transfer(address to, uint256 amount) public {
        require(amount <= balanceOf[msg.sender], "USDTMock: transfer failed");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    /// prevents the famous approval race condition by requiring the allowance
    /// to be reset to 0 before approving another amount
    function approve(address spender, uint256 amount) public returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((amount != 0) && (allowance[msg.sender][spender] != 0)));

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

abstract contract ERC20WalletTestBase1 is Test {
    IERC20Wallet public wallet;
    BasicERC20 public token;
    USDTMock public usdtMock;

    address public owner;
    address public donator;
    address public attacker;
    address payable public recipient;

    function setUp() public virtual {
        owner = makeAddr("owner");
        donator = makeAddr("donator");
        attacker = makeAddr("attacker");
        recipient = payable(makeAddr("recipient"));

        uint256 initialBalance = 100 * 10 ** 18;

        token = new BasicERC20();
        token.mint(owner, initialBalance);
        token.mint(donator, initialBalance);

        usdtMock = new USDTMock(100 * 10 ** 6);
    }

    function test_can_receive_and_send_erc20_token() public {
        vm.prank(donator);
        uint256 amount_in = 10 * 10 ** 18;
        token.transfer(address(wallet), amount_in);

        // when the owner transfers the token
        vm.prank(owner);
        uint256 amount_out = 5 * 10 ** 18;
        wallet.transferERC20(address(token), recipient, amount_out);

        // then the transfer succeeds and the recipient is credited
        assertEq(token.balanceOf(recipient), amount_out);
        assertEq(token.balanceOf(address(wallet)), amount_in - amount_out);
    }

    function test_only_owner_can_transfer_erc20_token() public {
        vm.prank(donator);
        uint256 amount_in = 10 * 10 ** 18;
        token.transfer(address(wallet), amount_in);

        // when the attacker tries to transfer the token, then it reverts with NotAuthorized
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        wallet.transferERC20(address(token), recipient, 10 * 10 ** 18);
    }

    function test_can_approve_erc20_token() public {
        // when the owner approves the token
        vm.prank(owner);
        uint256 approve_amount = 42 * 10 ** 18;
        wallet.approveERC20(address(token), recipient, approve_amount);

        // then the approval succeeds and the allowance is reflected
        assertEq(token.allowance(address(wallet), recipient), approve_amount);
    }

    function test_only_owner_can_approve_erc20_token() public {
        // when the attacker tries to approve the token, then it reverts with NotAuthorized
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        wallet.approveERC20(address(token), attacker, 0);
    }

    function test_handles_usdt_like_token_transfers() public {
        // seed the wallet with 100 USDT
        usdtMock.transfer(address(wallet), 100 * 10 ** 6);

        // when the owner transfers the token
        vm.prank(owner);
        uint256 amount = 42 * 10 ** 6;
        wallet.transferERC20(address(usdtMock), recipient, amount);

        // then the transfer succeeds and the recipient is credited
        assertEq(usdtMock.balanceOf(recipient), amount);
    }

    function test_handles_usdt_like_token_approvals(uint256 amount1, uint256 amount2) public {
        // when the owner approves the token
        vm.prank(owner);
        wallet.approveERC20(address(usdtMock), recipient, amount1);

        // then the approval succeeds and the allowance is reflected
        assertEq(usdtMock.allowance(address(wallet), recipient), amount1);

        // when the owner approves a different amount
        vm.prank(owner);
        wallet.approveERC20(address(usdtMock), recipient, amount2);

        console.log("amount2", amount2);

        // then the approval succeeds and the allowance is reflected
        assertEq(usdtMock.allowance(address(wallet), recipient), amount2);
    }
}

