// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ISubAccount {
    struct StrategyDisplay {
        address strategyToken;
        BalanceStrategy[] balance;
    }

    struct BalanceStrategy {
        uint256 amount;
        address token;
        uint256 decimals;
        string ico;
        string name;
        bool status;
        bool paused;
    }

    struct SubAccountsDisplay {
        string id;
        string name;
        StrategyDisplay[] strategies;
    }

    struct SubAccounts {
        string id;
        string name;
    }
    function create(address user, string memory name) external;
    function getSubAccounts(
        address contractAddress,
        address user
    ) external view returns (SubAccounts[] memory);
    function getStrategies(
        address contractAddress,
        address user,
        string memory accountId
    ) external view returns (address[] memory);
    function getBalances(
        address contractAddress,
        address user,
        string memory accountId,
        address strategyToken
    ) external view returns (BalanceStrategy[] memory);
    function addLiquidy(
        address user,
        string memory accountId,
        address strategyToken,
        uint256 amount,
        address coin
    ) external;
    function removeLiquidy(
        address user,
        string memory accountId,
        address strategyToken,
        uint256 amount,
        address coin
    ) external;
    function togglePause(
        address user,
        string memory accountId,
        address strategyToken,
        address coin,
        bool paused
    ) external;

    function position(
        address contractAddress,
        address user,
        string memory accountId,
        address strategyToken,
        address coin,
        int256 amount
    ) external returns (uint256 oldBalance);
}
