// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";

contract Airdrop is OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    IERC20Upgradeable public nameToken;
    uint public amount;
    address public signer;
    mapping(address => bool) public claimed;

    function initialize(address signer_, address nameAddress_, uint amount_) public initializer {
        super.__Ownable_init();
        signer = signer_;
        nameToken = IERC20Upgradeable(nameAddress_);
        amount = amount_;
    }

    function claim(bytes memory signature) external checkClaim checkSign(signature) {
        claimed[msg.sender] = true;
        nameToken.transfer(msg.sender, amount);
    }

    function changeSigner(address signer_) external onlyOwner {
        signer = signer_;
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
