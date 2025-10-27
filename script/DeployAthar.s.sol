// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AtharRegistry.sol";
import "../src/AtharLicense.sol";

contract DeployAthar is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address admin = vm.envAddress("ADMIN_ADDRESS");

        AtharRegistry registry = new AtharRegistry(admin);
        AtharLicense license = new AtharLicense(address(registry));

        registry.grantValidator(admin);

        vm.stopBroadcast();

        console2.log(" AtharRegistry deployed at:", address(registry));
        console2.log(" AtharLicense deployed at:", address(license));
    }
}

