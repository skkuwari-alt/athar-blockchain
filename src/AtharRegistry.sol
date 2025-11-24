// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract AtharRegistry is AccessControl, Pausable {
    bytes32 public constant QM_VALIDATOR = keccak256("QM_VALIDATOR");
    bytes32 public constant MOC_VALIDATOR = keccak256("MOC_VALIDATOR");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

     error AlreadyRegistered();
     error InvalidThreshold();
     error EmptyMetadata();
     error NotRegistered();
     error NotAuthorizedValidator();

    struct Artifact {
        address creator;
        string metadataURI;
        bool exists;

        // validation states (per institution)
        bool qmApproved;
        bool mocApproved;

        bool qmRejected;
        bool mocRejected;

        string qmRejectReason;
        string mocRejectReason;

        uint256 createdAt;
    }

    uint256 public nextId;
    mapping(uint256 => Artifact) public artifacts;
    mapping(bytes32=> bool) public registeredMetadata;  // changed this line for gas optimization 

    // Number of approvals required for an artifact to be considered fully approved, With QM + MOC we currently have a max of 2.
    uint256 public attestThreshold;

    event Registered(uint256 indexed id, address indexed creator, string uri);
    event Approved(uint256 indexed id, address indexed validator, string institution);
    event Rejected(uint256 indexed id, address indexed validator, string institution, string reason);
    event AttestThresholdUpdated(uint256 newThreshold);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
        attestThreshold = 2;
    }

    function setAttestThreshold(uint256 newThreshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (newThreshold == 0 || newThreshold > 2) {
        revert InvalidThreshold();
    }
    attestThreshold = newThreshold;
}

    // ----- Register -----
    function register(string calldata metadataURI) external whenNotPaused returns (uint256 id) {
        if (bytes(metadataURI).length == 0) revert EmptyMetadata(); 
        bytes32 uriHash = keccak256(bytes(metadataURI));

        if (registeredMetadata[uriHash]) revert AlreadyRegistered();
            // the above two lines were also changed during gas optimization 
        id = nextId++;
        artifacts[id] = Artifact({
            creator: msg.sender,
            metadataURI: metadataURI,
            exists: true,
            qmApproved: false,
            mocApproved: false,
            qmRejected: false,
            mocRejected: false,
            qmRejectReason: "",
            mocRejectReason: "",
            createdAt: block.timestamp
        });
        registeredMetadata[uriHash] = true; // this line got chnage during gas optimization 
        emit Registered(id, msg.sender, metadataURI);
    }

    // ----- Approvals -----
    function approve(uint256 id) external whenNotPaused {
        Artifact storage a = artifacts[id];
        if (!a.exists) revert NotRegistered(); // changed for gas optimization 

        if (hasRole(QM_VALIDATOR, msg.sender)) {
            a.qmApproved = true;
            a.qmRejected = false;
            emit Approved(id, msg.sender, "Qatar Museums");
        } 
        else if (hasRole(MOC_VALIDATOR, msg.sender)) {
            a.mocApproved = true;
            a.mocRejected = false;
            emit Approved(id, msg.sender, "Ministry of Culture");
        } 
        else {
            revert NotAuthorizedValidator(); // changed for gas optimization 
        }
    }

    // ----- Reject -----
    function reject(uint256 id, string calldata reason) external whenNotPaused {
        Artifact storage a = artifacts[id];
        if (!a.exists) revert NotRegistered();

        if (hasRole(QM_VALIDATOR, msg.sender)) {
            a.qmRejected = true;
            a.qmApproved = false;
            a.qmRejectReason = reason;

            emit Rejected(id, msg.sender, "Qatar Museums", reason);
        } 
        else if (hasRole(MOC_VALIDATOR, msg.sender)) {
            a.mocRejected = true;
            a.mocApproved = false;
            a.mocRejectReason = reason;

            emit Rejected(id, msg.sender, "Ministry of Culture", reason);
        } 
        else {
            revert NotAuthorizedValidator();
        }
    }

    // ----- View combined status -----
    function isFullyApproved(uint256 id) external view returns (bool) {
        Artifact storage a = artifacts[id];
        return a.exists && a.qmApproved && a.mocApproved;
    }
}
