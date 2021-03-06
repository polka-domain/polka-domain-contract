// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

contract Airdrop is OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;
    using SafeMathUpgradeable for uint;

    IERC20Upgradeable public nameToken;
    uint public amount;
    address public signer;
    mapping(address => bool) public claimed;
    address public from;
    uint public startAt;
    uint public duration;

    function initialize(address signer_, address nameAddress_, address from_, uint amount_, uint startAt_) public initializer {
        super.__Ownable_init();
        signer = signer_;
        nameToken = IERC20Upgradeable(nameAddress_);
        from = from_;
        amount = amount_;
        startAt = startAt_;
        duration = 48 hours;
    }

    function claim(bytes memory signature) external checkClaim checkSign(signature) {
        require(startAt <= block.timestamp, "CLAIM NOT OPEN");
        require(block.timestamp < startAt.add(duration), "CLAIM CLOSED");
        claimed[msg.sender] = true;
        nameToken.transferFrom(from, msg.sender, amount);
    }

    function changeSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function changeFrom(address from_) external onlyOwner {
        from = from_;
    }

    function changeStartAt(uint startAt_) external onlyOwner {
        startAt = startAt_;
    }

    function changeDuration(uint duration_) external onlyOwner {
        duration = duration_;
    }

    modifier checkClaim() {
        require(!claimed[msg.sender], "CLAIMED");
        _;
    }

    modifier checkSign(bytes memory signature) {
        bytes32 message = keccak256(abi.encode(msg.sender));
        bytes32 hashMessage = message.toEthSignedMessageHash();
        require(signer == hashMessage.recover(signature), "INVALID SIGNATURE");
        _;
    }
}
