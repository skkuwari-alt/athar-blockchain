// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AtharLicense.sol";

contract FailurePathTest is Test {
    AtharLicense license;

    address public admin = address(0x123);
    address public nonAdmin = address(0x456);

    function setUp() public {
        // deploy a new contract and pretend `admin` deployed it
        vm.startPrank(admin);
        license = new AtharLicense();
        vm.stopPrank();
    }

    // 1️ Non-admin trying to call admin-only function
    function testFail_SetAttestThresholdByNonAdmin() public {
        vm.startPrank(nonAdmin);
        license.setAttestThreshold(1); // should revert
        vm.stopPrank();
    }

    // 2️ Register twice with the same metadata (should revert)
    function testFail_DuplicateRegistration() public {
        vm.startPrank(admin);
        license.register("ipfs://same-metadata");
        license.register("ipfs://same-metadata"); // expect revert
        vm.stopPrank();
    }

    // 3️ Register with empty metadata (should revert)
    function testFail_RegisterWithEmptyMetadata() public {
        vm.startPrank(admin);
        license.register(""); // expect revert
        vm.stopPrank();
    }
}