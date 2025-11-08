// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AtharRegistry
 * @notice Proof-of-concept cultural artifact registry for the Athar blockchain.
 * @dev Stores artifacts, supports validator attestations, optional ERC721 minting.
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract AtharRegistry is AccessControl, Pausable, ERC721URIStorage {
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Artifact {
        address creator;
        string metadataURI;
        uint64 attestations;
        bool attested;
        bool exists;
    }

    uint256 public nextId;
    uint64 public attestThreshold = 2;
    mapping(uint256 => Artifact) public artifacts;
    mapping(string => bool) private registeredMetadata;

    event Registered(uint256 indexed id, address indexed creator, string metadataURI);
    event Attested(uint256 indexed id, address indexed validator, uint64 count, bool thresholdReached);
    event Revoked(uint256 indexed id, address indexed operator);
    event ThresholdUpdated(uint64 newThreshold);
    event PausedSet(bool isPaused);

    error NotRegistered();
    error AlreadyAttested();
    error AlreadyRegistered();
    error ThresholdInvalid();

    constructor(address admin) ERC721("Athar Artifact", "ATHAR") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
    }

    // ----- Admin -----
    function setPaused(bool p) external onlyRole(OPERATOR_ROLE) {
        if (p) _pause();
        else _unpause();
        emit PausedSet(p);
    }

    function setAttestThreshold(uint64 t) external onlyRole(OPERATOR_ROLE) {
        if (t == 0) revert ThresholdInvalid();
        attestThreshold = t;
        emit ThresholdUpdated(t);
    }

    function grantValidator(address v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VALIDATOR_ROLE, v);
    }

    // ----- Core -----
    function register(string calldata metadataURI) external whenNotPaused returns (uint256 id) {
        require(bytes(metadataURI).length != 0, "metadataURI cannot be empty");
        if (registeredMetadata[metadataURI]) revert AlreadyRegistered();
        id = nextId++;
        if (artifacts[id].exists) revert AlreadyRegistered();

        artifacts[id] =
            Artifact({creator: msg.sender, metadataURI: metadataURI, attestations: 0, attested: false, exists: true});
        registeredMetadata[metadataURI] = true;

        _safeMint(msg.sender, id);
        _setTokenURI(id, metadataURI);
        emit Registered(id, msg.sender, metadataURI);
    }

    function attest(uint256 id) external whenNotPaused onlyRole(VALIDATOR_ROLE) {
        Artifact storage a = artifacts[id];
        if (!a.exists) revert NotRegistered();
        if (a.attested) revert AlreadyAttested();

        a.attestations += 1;
        bool reached = false;
        if (a.attestations >= attestThreshold) {
            a.attested = true;
            reached = true;
        }
        emit Attested(id, msg.sender, a.attestations, reached);
    }

    function revoke(uint256 id) external onlyRole(OPERATOR_ROLE) {
        if (!artifacts[id].exists) revert NotRegistered();
        artifacts[id].attested = false;
        emit Revoked(id, msg.sender);
    }

    // ----- Overrides -----
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
