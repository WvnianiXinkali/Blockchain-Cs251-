// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AaveSupplierTestBase} from "./AaveSupplierTestBase3.sol";
import {IAaveSupplier} from "src/3-aave/interfaces/IAaveSupplier.sol";
import {AaveSupplier} from "src/3-aave/AaveSupplier.sol";

contract AaveSupplierTestCheckpoint3 is AaveSupplierTestBase {
    function setUp() public override {
        super.setUp();

        vm.startPrank(owner);
        aaveSupplier = deploySupplier();
        vm.stopPrank();
    }

    function deploySupplier() public override returns (IAaveSupplier) {
        return new AaveSupplier();
    }
}
