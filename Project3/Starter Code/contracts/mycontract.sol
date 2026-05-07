// SPDX-License-Identifier: UNLICENSED

// DO NOT MODIFY BELOW THIS
pragma solidity ^0.8.17;

import "forge-std/console.sol";

contract Splitwise {
// DO NOT MODIFY ABOVE THIS

// ADD YOUR CONTRACT CODE BELOW
    event IOU_added(address indexed debtor, address indexed creditor, uint32 amount);
    mapping(address => mapping(address => uint32)) public ious;

    function addIOU(address creditor, uint32 amount, address[] calldata path) external {
        require(amount > 0, "Amount must be greater than zero");
        require(creditor != msg.sender, "Creditor cannot be the same as debtor");
        ious[msg.sender][creditor] += amount;
        resolveIOU(path, creditor);
        emit IOU_added(msg.sender, creditor, amount);
    }
    
    function resolveIOU(address[] calldata path, address creditor) internal {
        if (path.length > 0) {
            require(path[0] == creditor, "Path must start with the creditor");
            require(path[path.length - 1] == msg.sender, "Path must end with the sender");
            uint32 minDebt = ious[msg.sender][creditor];
            for (uint i = 0; i < path.length - 1; i++) {
                require(ious[path[i]][path[i+1]] > 0, "Invalid path: no debt between these users");
                if(minDebt > ious[path[i]][path[i+1]]) { minDebt = ious[path[i]][path[i+1]]; }
                for (uint j = i + 1; j < path.length; j++) { require(path[i] != path[j], "Duplicate address in path"); }
            }
            for (uint i = 0; i < path.length - 1; i++) { ious[path[i]][path[i+1]] -= minDebt; }
            ious[msg.sender][creditor] -= minDebt;
        }
    }

    function lookup(address debtor, address creditor) public view returns (uint32 ret){
        return ious[debtor][creditor];
    }
}
