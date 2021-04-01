// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract PoolTime {
    struct TimeInfo {
        // timestamp when the pool will open
        uint openAt;
        // timestamp when the pool will close
        uint closeAt;
        // timestamp when users can claim their tokens
        uint claimAt;
    }

    mapping(uint => TimeInfo) public timeInfos;

    function _setPoolTime(uint index, uint openAt, uint closeAt, uint claimAt) internal returns (TimeInfo memory) {
        require(openAt >= block.timestamp, "INVALID OPEN_AT");
        require(closeAt >= openAt, "INVALID CLOSE_AT");
        require(claimAt >= closeAt, "INVALID CLAIM_AT");

        TimeInfo memory timeInfo;
        timeInfo.openAt = openAt;
        timeInfo.closeAt = closeAt;
        timeInfo.claimAt = claimAt;
        timeInfos[index] = timeInfo;

        return timeInfo;
    }

    function _isInstantClaim(uint index) internal view returns (bool) {
        return timeInfos[index].claimAt == 0;
    }

    modifier poolShouldClose(uint index) {
        require(timeInfos[index].closeAt <= block.timestamp, "POOL SHOULD BE CLOSED");
        _;
    }

    modifier poolShouldOpen(uint index) {
        require(
            timeInfos[index].openAt <= block.timestamp && block.timestamp < timeInfos[index].closeAt,
            "POOL SHOULD BE OPENED"
        );
        _;
    }
}
