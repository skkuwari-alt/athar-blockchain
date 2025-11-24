// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AtharRegistry.sol";

contract AtharRegistryTest is Test {
    AtharRegistry public registry;

    // We make this test contract the admin
    address qmValidator  = address(0xB0B);
    address mocValidator = address(0xC0C);
    address stranger     = address(0xE0E);

    function setUp() public {
        // This contract is admin
        registry = new AtharRegistry(address(this));

        // Grant validator roles
        registry.grantRole(registry.QM_VALIDATOR(), qmValidator);
        registry.grantRole(registry.MOC_VALIDATOR(), mocValidator);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Constructor                                  */
    /* -------------------------------------------------------------------------- */

    function test_Constructor_SetsAdminOperatorAndThreshold() public {
        assertTrue(
            registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), address(this)),
            "this contract should be DEFAULT_ADMIN_ROLE"
        );
        assertTrue(
            registry.hasRole(registry.OPERATOR_ROLE(), address(this)),
            "this contract should be OPERATOR_ROLE"
        );
        assertEq(registry.attestThreshold(), 2);
    }

    /* -------------------------------------------------------------------------- */
    /*                           setAttestThreshold                               */
    /* -------------------------------------------------------------------------- */

    function test_SetAttestThreshold_HappyPath() public {
        registry.setAttestThreshold(1);
        assertEq(registry.attestThreshold(), 1);
    }

    function test_SetAttestThreshold_ZeroReverts() public {
        vm.expectRevert(AtharRegistry.InvalidThreshold.selector);
        registry.setAttestThreshold(0);
    }

    function test_SetAttestThreshold_AboveTwoReverts() public {
        vm.expectRevert(AtharRegistry.InvalidThreshold.selector);
        registry.setAttestThreshold(3);
    }

    function test_SetAttestThreshold_NonAdminReverts() public {
        vm.prank(stranger);
        vm.expectRevert(); // AccessControlUnauthorizedAccount
        registry.setAttestThreshold(1);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Register                                  */
    /* -------------------------------------------------------------------------- */

    function test_Register_HappyPath() public {
        string memory uri = "ipfs://artifact-1";

        uint256 id = registry.register(uri);
        assertEq(id, 0);

        (
            address creator,
            string memory storedUri,
            bool exists,
            bool qmApproved,
            bool mocApproved,
            bool qmRejected,
            bool mocRejected,
            string memory qmRejectReason,
            string memory mocRejectReason,
            uint256 createdAt
        ) = registry.artifacts(id);

        assertEq(creator, address(this));
        assertEq(storedUri, uri);
        assertTrue(exists);
        assertFalse(qmApproved);
        assertFalse(mocApproved);
        assertFalse(qmRejected);
        assertFalse(mocRejected);
        assertEq(bytes(qmRejectReason).length, 0);
        assertEq(bytes(mocRejectReason).length, 0);
        assertTrue(createdAt > 0);
    }

    function test_Register_IncrementsIds() public {
        uint256 id1 = registry.register("ipfs://a");
        uint256 id2 = registry.register("ipfs://b");

        assertEq(id1, 0);
        assertEq(id2, 1);
    }

    function test_Register_EmptyUriReverts() public {
        vm.expectRevert(bytes("metadataURI cannot be empty"));
        registry.register("");
    }

    function test_Register_DuplicateUriReverts() public {
        string memory uri = "ipfs://dup";

        registry.register(uri);

        vm.expectRevert(AtharRegistry.AlreadyRegistered.selector);
        registry.register(uri);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Approve                                   */
    /* -------------------------------------------------------------------------- */

    function test_Approve_ByQmValidatorSetsFlags() public {
        uint256 id = registry.register("ipfs://qm");

        vm.prank(qmValidator);
        registry.approve(id);

        (
            ,
            ,
            ,
            bool qmApproved,
            bool mocApproved,
            bool qmRejected,
            bool mocRejected,
            ,
            ,
            
        ) = registry.artifacts(id);

        assertTrue(qmApproved);
        assertFalse(mocApproved);
        assertFalse(qmRejected);
        assertFalse(mocRejected);
    }

    function test_Approve_ByMocValidatorSetsFlags() public {
        uint256 id = registry.register("ipfs://moc");

        vm.prank(mocValidator);
        registry.approve(id);

        (
            ,
            ,
            ,
            bool qmApproved,
            bool mocApproved,
            bool qmRejected,
            bool mocRejected,
            ,
            ,
            
        ) = registry.artifacts(id);

        assertFalse(qmApproved);
        assertTrue(mocApproved);
        assertFalse(qmRejected);
        assertFalse(mocRejected);
    }

    function test_Approve_NonValidatorReverts() public {
        uint256 id = registry.register("ipfs://c");

        vm.prank(stranger);
        vm.expectRevert(bytes("Not authorized validator"));
        registry.approve(id);
    }

    function test_Approve_NonExistingIdReverts() public {
        vm.prank(qmValidator);
        vm.expectRevert(bytes("Not registered"));
        registry.approve(999);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Reject                                   */
    /* -------------------------------------------------------------------------- */

    function test_Reject_ByQmValidatorSetsFlagsAndReason() public {
        uint256 id = registry.register("ipfs://d");
        string memory reason = "bad quality";

        vm.prank(qmValidator);
        registry.reject(id, reason);

        (
            ,
            ,
            ,
            bool qmApproved,
            bool mocApproved,
            bool qmRejected,
            bool mocRejected,
            string memory qmRejectReason,
            string memory mocRejectReason,
            
        ) = registry.artifacts(id);

        assertFalse(qmApproved);
        assertFalse(mocApproved);
        assertTrue(qmRejected);
        assertFalse(mocRejected);
        assertEq(qmRejectReason, reason);
        assertEq(bytes(mocRejectReason).length, 0);
    }

    function test_Reject_ByMocValidatorSetsFlagsAndReason() public {
        uint256 id = registry.register("ipfs://e");
        string memory reason = "not compliant";

        vm.prank(mocValidator);
        registry.reject(id, reason);

        (
            ,
            ,
            ,
            bool qmApproved,
            bool mocApproved,
            bool qmRejected,
            bool mocRejected,
            string memory qmRejectReason,
            string memory mocRejectReason,
            
        ) = registry.artifacts(id);

        assertFalse(qmApproved);
        assertFalse(mocApproved);
        assertFalse(qmRejected);
        assertTrue(mocRejected);
        assertEq(bytes(qmRejectReason).length, 0);
        assertEq(mocRejectReason, reason);
    }

    function test_Reject_NonValidatorReverts() public {
        uint256 id = registry.register("ipfs://f");

        vm.prank(stranger);
        vm.expectRevert(bytes("Not authorized validator"));
        registry.reject(id, "nope");
    }

    function test_Reject_NonExistingIdReverts() public {
        vm.prank(qmValidator);
        vm.expectRevert(bytes("Not registered"));
        registry.reject(999, "nope");
    }

    /* -------------------------------------------------------------------------- */
    /*                               isFullyApproved                              */
    /* -------------------------------------------------------------------------- */

    function test_IsFullyApproved_FalseWhenNotExists() public {
        assertFalse(registry.isFullyApproved(12345));
    }

    function test_IsFullyApproved_RequiresBothApprovals() public {
        uint256 id = registry.register("ipfs://g");

        assertFalse(registry.isFullyApproved(id));

        vm.prank(qmValidator);
        registry.approve(id);
        assertFalse(registry.isFullyApproved(id));

        vm.prank(mocValidator);
        registry.approve(id);
        assertTrue(registry.isFullyApproved(id));
    }

    function test_IsFullyApproved_TurnsFalseAfterReject() public {
        uint256 id = registry.register("ipfs://h");

        vm.prank(qmValidator);
        registry.approve(id);
        vm.prank(mocValidator);
        registry.approve(id);
        assertTrue(registry.isFullyApproved(id));

        vm.prank(qmValidator);
        registry.reject(id, "illetigemate artifact");
        assertFalse(registry.isFullyApproved(id));
    }
}
