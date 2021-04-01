// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Whitelist {

    // pool index => whether or not whitelist is enabled
    mapping(uint => bool) public enable;

    // pool index => account => whether or not in white list
    mapping(uint => mapping(address => bool)) public whitelist;

    function _setEnableWhiteList(uint index) internal {
        enable[index] = true;
    }

    function _addWhitelist(uint index, address[] memory whitelist_) internal {
        for (uint i = 0; i < whitelist_.length; i++) {
            whitelist[index][whitelist_[i]] = true;
        }
    }

    function _removeWhitelist(uint index, address[] memory whitelist_) internal {
        for (uint i = 0; i < whitelist_.length; i++) {
            delete whitelist[index][whitelist_[i]];
        }
    }

    function _isWhitelistEnabled(uint index) internal view returns (bool) {
        return enable[index];
    }

    function _inWhitelist(uint index, address target) internal view returns (bool) {
        return whitelist[index][target];
    }

    modifier checkInWhitelist(uint index, address target) {
        if (_isWhitelistEnabled(index)) {
            require(_inWhitelist(index, target), "ADDRESS SHOULD IN WHITELIST");
        }
        _;
    }
}
