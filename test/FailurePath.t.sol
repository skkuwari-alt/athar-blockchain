// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AtharLicense.sol";
import "../src/AtharRegistry.sol";

contract FailurePathTest is Test {
    AtharLicense license;
    AtharRegistry registry;

    address public admin = address(0x123);
    address public nonAdmin = address(0x456);

    function setUp() public {
        // deploy registry and license contracts as admin
        vm.startPrank(admin);
        registry = new AtharRegistry(admin);
        license = new AtharLicense(address(registry));
        vm.stopPrank();
    }

    // 1️ Non-admin trying to call admin-only function
    function test_RevertWhen_SetAttestThresholdByNonAdmin() public {
        vm.startPrank(nonAdmin);
        vm.expectRevert();
        registry.setAttestThreshold(1); // should revert
        vm.stopPrank();
    }

    // 2️ Register twice with the same metadata (should revert)
    function test_RevertWhen_DuplicateRegistration() public {
        vm.startPrank(admin);
        registry.register("ipfs://same-metadata");
        vm.expectRevert();
        registry.register("ipfs://same-metadata"); // expect revert
        vm.stopPrank();
    }

    // 3️ Register with empty metadata (should revert)
    function test_RevertWhen_RegisterWithEmptyMetadata() public {
        vm.startPrank(admin);
        vm.expectRevert();
        registry.register(""); // expect revert
        vm.stopPrank();
    }
}