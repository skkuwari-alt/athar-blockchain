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
        address museum = vm.envAddress("MUSEUM_ADDRESS");
        address culture = vm.envAddress("CULTURE_ADDRESS");

        // Deploy both contracts
        AtharRegistry registry = new AtharRegistry(admin);
        AtharLicense license = new AtharLicense(address(registry));

        // Assign roles properly
        registry.grantRole(registry.QM_VALIDATOR(), museum);
        registry.grantRole(registry.MOC_VALIDATOR(), culture);
        registry.grantRole(registry.OPERATOR_ROLE(), admin);

        vm.stopBroadcast();

        console2.log("AtharRegistry deployed at:", address(registry));
        console2.log("AtharLicense deployed at:", address(license));
        console2.log("QM Validator:", museum);
        console2.log("MoC Validator:", culture);
        console2.log("Admin:", admin);
    }
}
