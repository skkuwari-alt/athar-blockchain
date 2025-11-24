// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AtharRegistry.sol";
import "../src/AtharLicense.sol";

/**
 * @title HappyPath
 * @notice Simulates the full lifecycle:
 * Creator registers → Museum & Culture approve → License granted
 */
contract HappyPath is Script {
    AtharRegistry registry;
    AtharLicense license;

    function setUp() public {
        registry = AtharRegistry(payable(vm.envAddress("REGISTRY_ADDRESS")));
        license = AtharLicense(payable(vm.envAddress("LICENSE_ADDRESS")));
    }

    function run() public {
        // Step 1: Creator registers artifact
        vm.startBroadcast();
        uint256 tokenId = registry.register("ipfs://athar-sadu-demo-metadata");
        console.log("Registered new artifact with ID:", tokenId);
        vm.stopBroadcast();

        // Step 2: Museum approves
        vm.startBroadcast(vm.envUint("MUSEUM_PK"));
        registry.approve(tokenId);
        console.log("Museum approved artifact");
        vm.stopBroadcast();

        // Step 3: Ministry of Culture approves
        vm.startBroadcast(vm.envUint("CULTURE_PK"));
        registry.approve(tokenId);
        console.log("Culture approved artifact");
        vm.stopBroadcast();

        // Step 4: Admin grants license
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        license.grantLicense(tokenId, vm.envAddress("ADMIN_ADDRESS"));
        console.log("License granted.");
        vm.stopBroadcast();
    }
}
