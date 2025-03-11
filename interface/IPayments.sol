// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPayments {
    struct Coins {
        string name;
        string symbol;
        uint8 decimals;
        bool status;
    }
    struct Bot {
        address contractAddress;
        FeeTier[] feeTiers;
        mapping(address => Coins) coins;
    }
    struct FeeTier {
        uint256 limit;
        uint256 fee;
    }
    function revokeOrAllowCurrency(
        address contractAddress,
        address coin,
        bool status
    ) external;
    function addFeeTiers(
        address contractAddress,
        FeeTier[] memory newFeeTiers
    ) external;
}
