// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenBridge is Ownable {
    
    using SafeERC20 for IERC20;
    
    struct ContractInfo {
            bool isAllowed;
            uint256 fee;
        }

    uint256 public constant source_chainid = 1; //change when deploy
    
    mapping(uint64 => bool) public destinationChainidAllowlist;
    
    mapping(address => ContractInfo) public sourceContractAllowlistAndFee;
    
    address public feeReceiverAddress = 0x0000000000000000000000000000000000000000;
    
    constructor(address _initialOwner) Ownable(_initialOwner) {
        feeReceiverAddress = _initialOwner;  
    }

    function setFeeReceiver(
        address _feeReceiverAddress
    ) external onlyOwner {
        feeReceiverAddress = _feeReceiverAddress;
    }
    function setSourceContractAllowlistAndFee(
        address contractAddress,
        bool isAllowed,
        uint256 fee
    ) external onlyOwner {
        sourceContractAllowlistAndFee[contractAddress] = ContractInfo(isAllowed, fee);
    }
    

    function setDestinationChainIdAllowlist(uint64 _destinationChainid, bool _allowed) external onlyOwner {
        destinationChainidAllowlist[_destinationChainid] = _allowed;
    }

    function bridge(
        uint64 destinationChainid,
        address senderAddress,
        address receiverAddress,
        address sourceContractAddress,
        address destinationContractAddress,
        uint256 amount
    ) external {
        require(destinationChainidAllowlist[destinationChainid], "The destination chain id is not supported");
        require(sourceContractAllowlistAndFee[sourceContractAddress].isAllowed, "This source contract doesnt is not support");
        require(senderAddress == msg.sender, "Sender must be address owner");
        require(isTokenAllowed(sourceContractAddress, amount), "Insufficient allowance");
        uint256 fee = sourceContractAllowlistAndFee[sourceContractAddress].fee;
        amount-=fee;
        IERC20(sourceContractAddress).safeTransferFrom(senderAddress, address(this), amount);
        IERC20(sourceContractAddress).safeTransferFrom(senderAddress, feeReceiverAddress, fee);
        emit Bridge(
            destinationChainid,
            senderAddress,
            receiverAddress,
            sourceContractAddress,
            destinationContractAddress,
            amount
        );
    }

    function isTokenAllowed(address token, uint256 amount) internal view returns (bool) {
        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        return allowance >= amount;
    }

    event Bridge(
        uint64 destinationChainid,
        address indexed senderAddress,
        address indexed receiverAddress,
        address sourceContractAddress,
        address destinationContractAddress,
        uint256 amount
    );

    function cashOut(
        address senderAddress,
        address receiverAddress,
        address sourceContractAddress,
        address destinationContractAddress,
        bytes32 sourceTransactionHash,
        uint256 amount
    ) external {
        IERC20(sourceContractAddress).safeTransferFrom(address(this), receiverAddress, amount);
        emit CashOut(
            senderAddress,
            receiverAddress,
            sourceContractAddress,
            destinationContractAddress,
            sourceTransactionHash,
            amount
        );
    }

    event CashOut(
        address indexed senderAddress,
        address indexed receiverAddress,
        address sourceContractAddress,
        address destinationContractAddress,
        bytes32 sourceTransactionHash,
        uint256 amount
    );
}
