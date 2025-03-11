// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IManager {
    function rebalancePosition(
        address user,
        int256 amount,
        uint256 gas,
        address coin,
        uint256 fee
    ) external;
}
