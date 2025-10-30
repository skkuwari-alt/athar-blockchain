// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AtharRegistry.sol";
import "../src/AtharLicense.sol";

/**
 * @title HappyPath
 * @notice Simulates the full lifecycle:
 * Creator registers -> Validator attests -> License granted
 */
contract HappyPath is Script {
    AtharRegistry registry;
    AtharLicense license;

    function setUp() public {
        registry = AtharRegistry(payable(vm.envAddress("REGISTRY_ADDRESS")));
        license = AtharLicense(payable(vm.envAddress("LICENSE_ADDRESS")));
    }

    function run() public {
    vm.startBroadcast();

    // 1) Creator registers an artifact
    uint256 tokenId = registry.register("ipfs://sadu-metadata-example");
    console.log("Registered artifact tokenId:", tokenId);

    // ✅ Lower threshold so 1 attestation is enough for demo
    registry.setAttestThreshold(1);
    console.log("Threshold lowered to 1");

    // 2) Validator attests authenticity
    registry.attest(tokenId);
    console.log("Artifact attested by validator");

    // 3) License granted
    license.grantLicense(tokenId, msg.sender);
    console.log("License granted to:", msg.sender);

    // 4) State read
    (, , , bool verified,) = registry.artifacts(tokenId);
    console.log("Attested status:", verified);

    vm.stopBroadcast();
}

}
