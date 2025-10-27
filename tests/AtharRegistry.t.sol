// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../contracts/AtharRegistry.sol";

contract RegistryTest is Test {
    AtharRegistry registry;

    function setUp() public {
        registry = new AtharRegistry();
    }

    function testRegisterArtifact() public {
        registry.register("ipfs://abc123");
        assertEq(registry.total(), 1);
        (string memory h, address c, bool v) = registry.artifacts(1);
        assertEq(h, "ipfs://abc123");
        assertEq(c, address(this));
        assertFalse(v);
    }
}