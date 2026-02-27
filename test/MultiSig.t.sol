// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/MultiSig.sol";
import "../src/MultiSigFactory.sol";

contract MultiSigTest is Test {
    MultiSig multiSig;
    MultiSigFactory factory;

    address owner1 = address(1);
    address owner2 = address(2);
    address owner3 = address(3);

    address recipient = address(99);

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        multiSig = new MultiSig(owners, 2);
        factory = new MultiSigFactory();

        vm.deal(address(multiSig), 10 ether);
    }

    function testSubmitTransaction() public {
        vm.prank(owner1);
        multiSig.submit(recipient, 1 ether);

        assertEq(multiSig.getTransactionCount(), 1);
    }

    function testApproveAndExecute() public {
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

    function testFactoryCreatesWallet() public {
        address;
        owners[0] = owner1;
        owners[1] = owner2;

        address wallet = factory.createWallet(owners, 2);

        assertTrue(wallet != address(0));
    }
}
