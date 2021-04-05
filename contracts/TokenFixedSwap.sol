// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./Whitelist.sol";
import "./PoolToken.sol";
import "./PoolTime.sol";

contract TokenFixedSwap is OwnableUpgradeable, Whitelist, PoolToken, PoolTime {
    using SafeMathUpgradeable for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Pool {
        // token receiver
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
        uint maxAllocToken1;
        // the timestamp in seconds the pool will open
        uint openAt;
        // the timestamp in seconds the pool will be closed
        uint closeAt;
        // the delay timestamp in seconds when buyers can claim after pool filled
        uint claimAt;
        // whether or not whitelist is enable
        bool enableWhiteList;
    }

    // team address => pool index => whether or not pool has been claimed
    mapping(address => mapping(uint => bool)) public poolClaimed;
    // user address => pool index => whether or not my pool has been claimed
    mapping(address => mapping(uint => bool)) public myClaimed;
    // user address => pool index => swapped amount of token0
    mapping(address => mapping(uint => uint)) public myAmountSwapped0;
    // user address => pool index => swapped amount of token1
    mapping(address => mapping(uint => uint)) public myAmountSwapped1;

    event Created(uint indexed index, address indexed sender, Pool pool);
    event Swapped(uint indexed index, address indexed sender, uint amount0, uint amount1);
    event PoolClaimed(uint indexed index, address indexed sender, uint amount0);
    event UserClaimed(uint indexed index, address indexed sender, uint amount0);

    function initialize() public {
        super.__Ownable_init();
    }

    function create(Pool memory pool, address[] memory whitelist_) public onlyOwner {
        // transfer amount of token0 to this contract
        IERC20Upgradeable _token0 = IERC20Upgradeable(pool.token0);
        uint token0BalanceBefore = _token0.balanceOf(address(this));
        _token0.safeTransferFrom(pool.creator, address(this), pool.amountTotal0);
        require(
            _token0.balanceOf(address(this)).sub(token0BalanceBefore) == pool.amountTotal0,
            "DON'T SUPPORT DEFLATIONARY TOKEN"
        );
        // reset allowance to 0
        _token0.safeApprove(address(this), 0);

        uint index = getPoolCount();
        if (pool.enableWhiteList) {
            super._setEnableWhiteList(index);
            super._addWhitelist(index, whitelist_);
        }
        super._setPoolToken(pool.creator, pool.token0, pool.token1, pool.amountTotal0, pool.amountTotal1, pool.maxAllocToken1);
        super._setPoolTime(index, pool.openAt, pool.closeAt, pool.claimAt);

        emit Created(index, msg.sender, pool);
    }

    function swap(uint index, uint amount1) external payable poolShouldExist(index) poolShouldOpen(index) checkInWhitelist(index, msg.sender) {
        TokenInfo memory tokenInfo = tokenInfos[index];
        require(tokenInfo.amountTotal1 > tokenInfo.amountSwap1, "INSUFFICIENT SWAP AMOUNT");

        // check if amount1 is exceeded
        uint excessAmount1 = 0;
        uint _amount1 = tokenInfo.amountTotal1.sub(tokenInfo.amountSwap1);
        if (_amount1 < amount1) {
            excessAmount1 = amount1.sub(_amount1);
        } else {
            _amount1 = amount1;
        }

        // check if amount0 is exceeded
        uint amount0 = _amount1.mul(tokenInfo.amountTotal0).div(tokenInfo.amountTotal1);
        uint _amount0 = tokenInfo.amountTotal0.sub(tokenInfo.amountSwap0);
        if (_amount0 > amount0) {
            _amount0 = amount0;
        }

        tokenInfos[index].amountSwap0 = tokenInfo.amountSwap0.add(_amount0);
        tokenInfos[index].amountSwap1 = tokenInfo.amountSwap1.add(_amount1);
        myAmountSwapped0[msg.sender][index] = myAmountSwapped0[msg.sender][index].add(_amount0);
        // check if swapped amount of token1 is exceeded maximum allowance
        if (tokenInfo.maxAllocToken1 != 0) {
            require(
                myAmountSwapped1[msg.sender][index].add(_amount1) <= tokenInfo.maxAllocToken1,
                "SWAP AMOUNT EXCEEDED"
            );
            myAmountSwapped1[msg.sender][index] = myAmountSwapped1[msg.sender][index].add(_amount1);
        }

        // transfer amount of token1 to this contract
        if (tokenInfo.token1 == address(0)) {
            require(msg.value == amount1, "INVALID MSG.VALUE");
        } else {
            require(msg.value == 0, "MSG.VALUE SHOULD BE ZERO");
            IERC20Upgradeable(tokenInfo.token1).safeTransferFrom(msg.sender, address(this), amount1);
        }

        if (super._isInstantClaim(index)) {
            if (_amount0 > 0) {
                // send token0 to sender
                if (tokenInfo.token0 == address(0)) {
                    msg.sender.transfer(_amount0);
                } else {
                    IERC20Upgradeable(tokenInfo.token0).safeTransfer(msg.sender, _amount0);
                }
            }
        }
        if (excessAmount1 > 0) {
            // send excess amount of token1 back to sender
            if (tokenInfo.token1 == address(0)) {
                msg.sender.transfer(excessAmount1);
            } else {
                IERC20Upgradeable(tokenInfo.token1).safeTransfer(msg.sender, excessAmount1);
            }
        }

        // send token1 to creator
        if (_amount1 > 0) {
            if (tokenInfo.token1 == address(0)) {
                tokenInfo.creator.transfer(_amount1);
            } else {
                IERC20Upgradeable(tokenInfo.token1).safeTransfer(tokenInfo.creator, _amount1);
            }
        }

        emit Swapped(index, msg.sender, _amount0, _amount1);
    }

    function poolClaim(uint index) external poolShouldExist(index) poolShouldClose(index) canClaim(index) {
        TokenInfo memory tokenInfo = tokenInfos[index];
        require(!poolClaimed[tokenInfo.creator][index], "POOL CLAIMED");
        poolClaimed[tokenInfo.creator][index] = true;

        uint unSwapAmount0 = tokenInfo.amountTotal0.sub(tokenInfo.amountSwap0);
        if (unSwapAmount0 > 0) {
            IERC20Upgradeable(tokenInfo.token0).safeTransfer(tokenInfo.creator, unSwapAmount0);
        }

        emit PoolClaimed(index, msg.sender, unSwapAmount0);
    }

    function userClaim(uint index) external poolShouldExist(index) poolShouldClose(index) canClaim(index) {
        TokenInfo memory tokenInfo = tokenInfos[index];
        require(!super._isInstantClaim(index), "NOT DELAYED CLAIM");
        require(!myClaimed[msg.sender][index], "USER CLAIMED");
        myClaimed[msg.sender][index] = true;

        if (myAmountSwapped0[msg.sender][index] > 0) {
            // send token0 to sender
            if (tokenInfo.token0 == address(0)) {
                msg.sender.transfer(myAmountSwapped0[msg.sender][index]);
            } else {
                IERC20Upgradeable(tokenInfo.token0).safeTransfer(msg.sender, myAmountSwapped0[msg.sender][index]);
            }
        }
        emit UserClaimed(index, msg.sender, myAmountSwapped0[msg.sender][index]);
    }

    function addWhitelist(uint index, address[] memory whitelist_) public onlyOwner {
        super._addWhitelist(index, whitelist_);
    }

    function removeWhitelist(uint index, address[] memory whitelist_) external onlyOwner {
        super._removeWhitelist(index, whitelist_);
    }
}
