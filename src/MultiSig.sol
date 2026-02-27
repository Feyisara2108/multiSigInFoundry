// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MultiSig {
    error NotOwner();
    error InvalidOwner();
    error InvalidAddress();
    error InvalidRequirement();
    error TxDoesNotExist();
    error TxAlreadyExecuted();
    error TxAlreadyApproved();
    error TxNotApproved();
    error NotEnoughApprovals();

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId, address indexed to, uint256 value);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 approvalCount;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    constructor(address[] memory _owners, uint256 _required) {
        if (_owners.length == 0) revert InvalidOwner();
        if (_required == 0 || _required > _owners.length) revert InvalidRequirement();

        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) revert InvalidAddress();
            if (isOwner[owner]) revert InvalidOwner();

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) revert TxDoesNotExist();
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) revert TxAlreadyExecuted();
        _;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint256 _value) external onlyOwner returns (uint256 txId) {
        if (_to == address(0)) revert InvalidAddress();

        txId = transactions.length;

        transactions.push(Transaction({to: _to, value: _value, executed: false, approvalCount: 0}));

        emit Submit(txId, _to, _value);
    }

    function approve(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        if (approved[_txId][msg.sender]) revert TxAlreadyApproved();

        approved[_txId][msg.sender] = true;
        transactions[_txId].approvalCount++;

        emit Approve(msg.sender, _txId);
    }

    function revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        if (!approved[_txId][msg.sender]) revert TxNotApproved();

        approved[_txId][msg.sender] = false;
        transactions[_txId].approvalCount--;

        emit Revoke(msg.sender, _txId);
    }

    function execute(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        Transaction storage txn = transactions[_txId];

        if (txn.approvalCount < required) revert NotEnoughApprovals();

        txn.executed = true;

        (bool success,) = txn.to.call{value: txn.value}("");
        require(success, "Transfer failed");

        emit Execute(_txId);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
}
