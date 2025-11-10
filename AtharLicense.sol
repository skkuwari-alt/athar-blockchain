// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AtharLicense is Ownable {
    struct License {
        uint256 artifactId;       // Linked artifact (from AtharRegistry)
        address licensor;         // Creator or owner issuing license
        address licensee;         // Person receiving license
        uint256 royaltyPercent;   // Royalty percentage (e.g. 5 means 5%)
        uint256 issuedAt;         // Timestamp of issuance
        bool active;              // Whether the license is active
    }

    uint256 public totalLicenses;
    mapping(uint256 => License) public licenses;

    event LicenseIssued(
        uint256 indexed licenseId,
        uint256 indexed artifactId,
        address indexed licensee,
        uint256 royaltyPercent
    );

    event LicenseTransferred(
        uint256 indexed licenseId,
        address indexed oldLicensee,
        address indexed newLicensee
    );

    constructor() Ownable(msg.sender) {}

    // Issue a new license to a user
    function issueLicense(
        uint256 _artifactId,
        address _licensee,
        uint256 _royaltyPercent
    ) external {
        require(_licensee != address(0), "Invalid licensee");
        require(_royaltyPercent <= 100, "Invalid royalty");

        totalLicenses++;
        licenses[totalLicenses] = License({
            artifactId: _artifactId,
            licensor: msg.sender,
            licensee: _licensee,
            royaltyPercent: _royaltyPercent,
            issuedAt: block.timestamp,
            active: true
        });

        emit LicenseIssued(totalLicenses, _artifactId, _licensee, _royaltyPercent);
    }

    // Transfer a license to another user (reassign rights)
    function transferLicense(uint256 _licenseId, address _newLicensee) external {
        License storage lic = licenses[_licenseId];
        require(lic.active, "License not active");
        require(msg.sender == lic.licensee, "Only current licensee can transfer");
        require(_newLicensee != address(0), "Invalid new licensee");

        address oldLicensee = lic.licensee;
        lic.licensee = _newLicensee;

        emit LicenseTransferred(_licenseId, oldLicensee, _newLicensee);
    }

    // Deactivate a license (only owner or licensor)
    function revokeLicense(uint256 _licenseId) external {
        License storage lic = licenses[_licenseId];
        require(lic.active, "License already inactive");
        require(
            msg.sender == owner() || msg.sender == lic.licensor,
            "Not authorized"
        );

        lic.active = false;
    }

    // View active license info
    function getLicense(uint256 _licenseId)
        external
        view
        returns (
            uint256 artifactId,
            address licensor,
            address licensee,
            uint256 royaltyPercent,
            bool active
        )
    {
        License memory lic = licenses[_licenseId];
        return (
            lic.artifactId,
            lic.licensor,
            lic.licensee,
            lic.royaltyPercent,
            lic.active
        );
    }
}