// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract PoolToken {

    struct TokenInfo {
        address payable creator;
        // address of token0
        address token0;
        // address of token1
        address token1;
        // total amount of token0
        uint amountTotal0;
        // total amount of token1
        uint amountTotal1;
        // maximum allocation amount of token1 per address
        uint maxAllocationToken1;
        // swapped amount of token0
        uint amountSwap0;
        // swapped amount of token1
        uint amountSwap1;
    }

    TokenInfo[] public tokenInfos;

    function getPoolCount() public view returns (uint) {
        return tokenInfos.length;
    }

    function _setPoolToken(
        address payable creator,
        address token0,
        address token1,
        uint amountTotal0,
        uint amountTotal1,
        uint maxAllocationToken1
    ) internal returns (TokenInfo memory) {
        require(token0 != token1, "TOKEN0 AND TOKEN1 SHOULD BE DIFFERENT");
        require(amountTotal0 != 0, "INVALID TOTAL AMOUNT OF TOKEN0");
        require(amountTotal1 != 0, "INVALID TOTAL AMOUNT OF TOKEN1");

        TokenInfo memory tokenInfo;
        tokenInfo.creator = creator;
        tokenInfo.token0 = token0;
        tokenInfo.token1 = token1;
        tokenInfo.amountTotal0 = amountTotal0;
        tokenInfo.amountTotal1 = amountTotal1;
        tokenInfo.maxAllocationToken1 = maxAllocationToken1;
        tokenInfo.amountSwap0 = 0;
        tokenInfo.amountSwap1 = 0;
        tokenInfos.push(tokenInfo);

        return tokenInfo;
    }

    modifier poolShouldExist(uint index) {
        require(index < tokenInfos.length, "POOL SHOULD EXIST");
        _;
    }
}
