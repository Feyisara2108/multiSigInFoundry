// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/MultiSig.sol";

contract MultiSigBehaviorTest is Test {
    MultiSig multiSig;
    address[] public owners;

    address owner1 = address(1);
    address owner2 = address(2);
    address owner3 = address(3);
    address nonOwner = address(4);
    address recipient = address(99);

    function setUp() public {
        owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        multiSig = new MultiSig(owners, 2);

        vm.deal(address(multiSig), 10 ether);
    }

    function testNonOwnerCannotSubmit() public {
        vm.prank(nonOwner);
        vm.expectRevert(MultiSig.NotOwner.selector);
        multiSig.submit(recipient, 1 ether);
    }

    function testOwnerCanApprove() public {
        vm.prank(owner1);
        multiSig.submit(recipient, 1 ether);

        vm.prank(owner1);
        multiSig.approve(0);

        (,,, uint256 approvalCount) = multiSig.transactions(0);
        assertEq(approvalCount, 1);
    }

    function testCannotApproveTwice() public {
        vm.startPrank(owner1);
        multiSig.submit(recipient, 1 ether);
        multiSig.approve(0);

        vm.expectRevert(MultiSig.TxAlreadyApproved.selector);
        multiSig.approve(0);
        vm.stopPrank();
    }

    function testCannotExecuteWithoutEnoughApprovals() public {
        vm.startPrank(owner1);
        multiSig.submit(recipient, 1 ether);
        multiSig.approve(0);
        vm.stopPrank();

        vm.prank(owner1);
        vm.expectRevert(MultiSig.NotEnoughApprovals.selector);
        multiSig.execute(0);
    }

    function testExecuteAfterEnoughApprovals() public {
        vm.startPrank(owner1);
        multiSig.submit(recipient, 1 ether);
        multiSig.approve(0);
        vm.stopPrank();

        vm.prank(owner2);
        multiSig.approve(0);

        uint256 balanceBefore = recipient.balance;

        vm.prank(owner1);
        multiSig.execute(0);

        assertEq(recipient.balance, balanceBefore + 1 ether);
    }

    function testOwnerCanRevokeApproval() public {
        vm.startPrank(owner1);
        multiSig.submit(recipient, 1 ether);
        multiSig.approve(0);
        multiSig.revoke(0);
        vm.stopPrank();

        (,,, uint256 approvalCount) = multiSig.transactions(0);
        assertEq(approvalCount, 0);
    }
}
