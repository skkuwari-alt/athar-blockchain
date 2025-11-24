// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../contracts/AtharLicense.sol";

contract AtharLicenseTest is Test {
    AtharLicense license;
    address creator = address(0xA11CE);
    address licensee = address(0xB0B);
    address newLicensee = address(0xC0C);

    function setUp() public {
        // Deploy the contract before each test
        license = new AtharLicense();
        // Make `creator` the owner so they can issue licenses
        vm.prank(creator);
    }

    function testIssueLicense() public {
        vm.startPrank(creator);

        // Call the function
        license.issueLicense(1, licensee, 5);

        // Check storage variables
        (uint256 artifactId, address licensor, address _licensee, uint256 royalty, bool active) =
            license.getLicense(1);

        assertEq(artifactId, 1);
        assertEq(licensor, creator);
        assertEq(_licensee, licensee);
        assertEq(royalty, 5);
        assertTrue(active);

        vm.stopPrank();
    }

    function testTransferLicense() public {
        vm.startPrank(creator);
        license.issueLicense(1, licensee, 5);
        vm.stopPrank();

        vm.startPrank(licensee);
        license.transferLicense(1, newLicensee);
        vm.stopPrank();

        (, , address currentLicensee, , ) = license.getLicense(1);
        assertEq(currentLicensee, newLicensee);
    }

    function testRevokeLicense() public {
        vm.startPrank(creator);
        license.issueLicense(1, licensee, 5);
        license.revokeLicense(1);
        vm.stopPrank();

        (, , , , bool active) = license.getLicense(1);
        assertFalse(active);
    }

    function testFailInvalidLicensee() public {
        // This should fail because licensee address = 0
        vm.startPrank(creator);
        license.issueLicense(1, address(0), 5);
        vm.stopPrank();
    }

    function testFailUnauthorizedTransfer() public {
        vm.startPrank(creator);
        license.issueLicense(1, licensee, 5);
        vm.stopPrank();

        // Another random person trying to transfer license
        vm.startPrank(address(0xD1E));
        license.transferLicense(1, newLicensee);
        vm.stopPrank();
    }
}