// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AtharLicense
 * @notice Simple on-chain license registry linked to AtharRegistry artifacts.
 * @dev For PoC: creator grants and revokes licenses; registry enforces attestation requirement.
 */

interface IAtharRegistry {
    function artifacts(uint256 id)
        external
        view
        returns (address creator, string memory metadataURI, uint64 attestations, bool attested, bool exists);
}

contract AtharLicense {
    IAtharRegistry public registry;

    struct License {
        address licensee;
        uint256 artifactId;
        bool active;
    }

    mapping(uint256 => License[]) public licenses;
    mapping(address => bool) public authorizedCreators;

    event LicenseRequested(uint256 indexed artifactId, address indexed licensee);
    event LicenseGranted(uint256 indexed artifactId, address indexed licensee);
    event LicenseRevoked(uint256 indexed artifactId, address indexed licensee);

    error NotCreator();
    error NotAttested();
    error NoActiveLicense();

    constructor(address _registry) {
        registry = IAtharRegistry(_registry);
    }

    function requestLicense(uint256 artifactId) external {
        licenses[artifactId].push(License(msg.sender, artifactId, false));
        emit LicenseRequested(artifactId, msg.sender);
    }

    function grantLicense(uint256 artifactId, address licensee) external {
        (address creator,,, bool attested, bool exists) = registry.artifacts(artifactId);
        if (!exists || !attested) revert NotAttested();
        if (msg.sender != creator) revert NotCreator();

        License[] storage list = licenses[artifactId];
        for (uint256 i; i < list.length; i++) {
            if (list[i].licensee == licensee) {
                list[i].active = true;
                emit LicenseGranted(artifactId, licensee);
                return;
            }
        }
        // If not previously requested, create directly
        list.push(License(licensee, artifactId, true));
        emit LicenseGranted(artifactId, licensee);
    }

    function revokeLicense(uint256 artifactId, address licensee) external {
        (address creator,,,, bool exists) = registry.artifacts(artifactId);
        if (!exists) revert NoActiveLicense();
        if (msg.sender != creator) revert NotCreator();

        License[] storage list = licenses[artifactId];
        for (uint256 i; i < list.length; i++) {
            if (list[i].licensee == licensee && list[i].active) {
                list[i].active = false;
                emit LicenseRevoked(artifactId, licensee);
                return;
            }
        }
        revert NoActiveLicense();
    }

    function getLicenses(uint256 artifactId) external view returns (License[] memory) {
        return licenses[artifactId];
    }
}

