// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "src/2-multisig/interfaces/IMultisigWallet.sol";

contract MultisigWallet is IMultisigWallet {
    address[] public admins;
    uint256 public constant APPROVAL_TH = 2;
    mapping(bytes32 => mapping(address => bool)) public approvals;
    mapping(bytes32 => uint256) public approvalCount;

    constructor(address[] memory _admins) {
        // ... your code here
        if (_admins.length != 3) revert BadConfig();
        for (uint256 i = 0; i < _admins.length; i++) {
            if (_admins[i] == address(0)) revert BadConfig();
            for (uint256 j = 0; j < i; j++) {
                if (_admins[i] == _admins[j]) revert BadConfig();
            }
        }
        admins = _admins;
    }

    function isAdmin(address user) public view returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == user) {
                return true;
            }
        }
        return false;
    }

    function approve(bytes calldata action) external {
        // ... your code here
        if (!isAdmin(msg.sender)) revert NotAuthorized();
        bytes32 actionHash = keccak256(action);
        if (approvals[actionHash][msg.sender]) revert AlreadyApproved();
        approvals[actionHash][msg.sender] = true;
        approvalCount[actionHash]++;
        emit Approved(msg.sender, action);
    }

    function execute(bytes calldata action) external {
        // ... your code here
        bytes32 actionHash = keccak256(action);
        if (isAdmin(msg.sender) && !approvals[actionHash][msg.sender]) {
            approvalCount[actionHash]++;
        }
        if (approvalCount[actionHash] < APPROVAL_TH) revert NotAuthorized();
        // if multisig conditions are met, execute action
        approvalCount[actionHash] = 0;
        for (uint256 i = 0; i < admins.length; i++) {
            approvals[actionHash][admins[i]] = false;
        }
        (bool success, ) = address(this).call(action);
        require(success);

        emit Executed(msg.sender, action);
    }

    function transferEth(address payable recipient, uint256 amount) external {
        // ...
        if (msg.sender != address(this)) revert NotAuthorized();
        if (address(this).balance < amount) revert FailedTransfer();
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert FailedTransfer();
    }
}
