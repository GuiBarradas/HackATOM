// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStrategy {
    struct Strategy {
        string name;
        address tokenAddress;
        bool isActive;
    }
    function findStrategy(
        address contractAddress,
        address tokenAddress
    ) external view returns (Strategy memory);

    function addStrategy(
        string memory name,
        string memory symbol,
        address contractAddress
    ) external;
    
    function updateStrategyStatus(
        address contractAddress,
        address tokenAddress,
        bool isActive
    ) external;
    
    function getStrategies(
        address contractAddress
    ) external view returns (Strategy[] memory);
}
