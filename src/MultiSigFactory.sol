// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./MultiSig.sol";

contract MultiSigFactory {
    address[] public allWallets;

    event WalletCreated(address indexed wallet, address[] owners, uint256 required);

    function createWallet(address[] memory _owners, uint256 _required) external returns (address wallet) {
        MultiSig newWallet = new MultiSig(_owners, _required);
        wallet = address(newWallet);

        allWallets.push(wallet);

        emit WalletCreated(wallet, _owners, _required);
    }

    function getWallets() external view returns (address[] memory) {
        return allWallets;
    }
}
