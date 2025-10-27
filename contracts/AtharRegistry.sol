// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AtharRegistry is ERC721, Ownable {
    struct Artifact {
        string ipfsHash;        // points to metadata on IPFS
        address creator;        // original creator of the artifact
        bool verified;          // whether the artifact has been verified
    }

    uint256 public total;
    mapping(uint256 => Artifact) public artifacts;

    event Registered(uint256 indexed tokenId, address indexed creator, string ipfsHash);
    event Verified(uint256 indexed tokenId, bool verified);
    event Attested(uint256 indexed tokenId, address indexed validator);

    constructor() ERC721("AtharRegistry", "ATHAR") Ownable(msg.sender) {}

    // Register a new artifact with its IPFS hash
    function register(string memory _ipfsHash) external {
        total++;
        _mint(msg.sender, total);
        artifacts[total] = Artifact(_ipfsHash, msg.sender, false);
        emit Registered(total, msg.sender, _ipfsHash);
    }

    // Owner (admin) can manually verify any artifact
    function verifyArtifact(uint256 _tokenId) external onlyOwner {
        require(_tokenId > 0 && _tokenId <= total, "Invalid ID");
        artifacts[_tokenId].verified = true;
        emit Verified(_tokenId, true);
    }

    // Validators can attest (temporarily verify) artifacts
    function attest(uint256 _tokenId) external {
        require(_tokenId > 0 && _tokenId <= total, "Invalid ID");
        artifacts[_tokenId].verified = true;
        emit Attested(_tokenId, msg.sender);
    }
}