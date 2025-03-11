//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./utils/UniqueRandomCodeLib.sol";
import "./interface/IFactory.sol";
import "./interface/ISubAccount.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WEbdEXSubAccountsV4 {
    using UniqueRandomCodeLib for string;

    uint256 private counter;

    IFactory public factory;

    struct SubAccount {
        string id;
        string name;
        address[] list_strategies;
        mapping(address => StrategyBalance) strategies;
    }

    struct StrategyBalance {
        bool status;
        address[] list_coins;
        mapping(address => ISubAccount.BalanceStrategy) balance;
    }

    struct Bot {
        address contractAddress;
        mapping(address => SubAccount[]) subAccounts;
    }

    event CreateSubAccount(
        address indexed manager,
        address indexed user,
        string id,
        string name
    );

    event BalanceLiquidy(
        address indexed manager,
        address indexed user,
        string accountId,
        address strategy,
        address coin,
        uint256 balance,
        uint256 value,
        bool increase,
        bool is_operation
    );

    event ChangePaused(
        address indexed manager,
        address indexed user,
        string accountId,
        address strategy,
        address coin,
        bool paused
    );

    mapping(address => Bot) internal bots;
    mapping(string => bool) private usedCodes;

    constructor(IFactory _factory) {
        factory = _factory;
    }

    modifier onlyPayments(address managerAddress) {
        IFactory.Bot memory botInfo = factory.getBotInfo(managerAddress);
        require(
            botInfo.paymentsAddress == msg.sender,
            "You must the WebDexPayments"
        );
        _;
    }

    modifier onlyManager() {
        IFactory.Bot memory botInfo = factory.getBotInfo(msg.sender);
        require(botInfo.managerAddress != address(0), "Not authorized");
        _;
    }

    function _createCode(
        string memory prefix
    ) internal returns (string memory) {
        // Incrementa o contador antes de gerar o código
        counter++;
        return prefix.generateUniqueCode(counter);
    }

    function create(address user, string memory name) public onlyManager {
        IFactory.Bot memory botInfo = factory.getBotInfo(msg.sender);
        string memory uniqueId = _createCode(botInfo.prefix);

        if (bots[msg.sender].contractAddress == address(0)) {
            bots[msg.sender].contractAddress = msg.sender;
        }

        SubAccount storage newSubAccount = bots[msg.sender]
            .subAccounts[user]
            .push();
        newSubAccount.id = uniqueId;
        newSubAccount.name = name;
        emit CreateSubAccount(msg.sender, user, uniqueId, name);
    }

    function getBalance(
        address contractAddress,
        address user,
        string memory accountId,
        address strategyToken,
        address coin
    ) public view returns (ISubAccount.BalanceStrategy memory) {
        int256 index = findSubAccountIndexById(
            contractAddress,
            user,
            accountId
        );
        require(index >= 0, "SubAccount not found");
        StrategyBalance storage strategyBalance = bots[contractAddress]
        .subAccounts[user][uint256(index)].strategies[strategyToken];
        require(strategyBalance.status, "Account not linked to strategy");
        require(
            strategyBalance.balance[coin].status,
            "Account not linked to currency"
        );

        return strategyBalance.balance[coin];
    }

    function getBalances(
        address contractAddress,
        address user,
        string memory accountId,
        address strategyToken
    ) public view returns (ISubAccount.BalanceStrategy[] memory) {
        int256 index = findSubAccountIndexById(
            contractAddress,
            user,
            accountId
        );
        require(index >= 0, "SubAccount not found");

        StrategyBalance storage strategyBalance = bots[contractAddress]
        .subAccounts[user][uint256(index)].strategies[strategyToken];
        uint256 numCoins = strategyBalance.list_coins.length;

        ISubAccount.BalanceStrategy[]
            memory balances = new ISubAccount.BalanceStrategy[](numCoins);

        for (uint256 c = 0; c < numCoins; c++) {
            address currentCoin = strategyBalance.list_coins[c];
            balances[c] = strategyBalance.balance[currentCoin];
        }

        return balances;
    }

    function getStrategies(
        address contractAddress,
        address user,
        string memory accountId
    ) public view returns (address[] memory) {
        int256 index = findSubAccountIndexById(
            contractAddress,
            user,
            accountId
        );
        require(index >= 0, "SubAccount not found");

        return
            bots[contractAddress]
            .subAccounts[user][uint256(index)].list_strategies;
    }

    function getSubAccounts(
        address contractAddress,
        address user
    ) public view returns (ISubAccount.SubAccounts[] memory) {
        uint256 subAccountCount = bots[contractAddress]
            .subAccounts[user]
            .length;
        ISubAccount.SubAccounts[]
            memory accounts = new ISubAccount.SubAccounts[](subAccountCount);

        for (uint256 i = 0; i < subAccountCount; i++) {
            accounts[i] = ISubAccount.SubAccounts(
                bots[contractAddress].subAccounts[user][i].id,
                bots[contractAddress].subAccounts[user][i].name
            );
        }
        return accounts;
    }

    function addLiquidy(
        address user,
        string memory accountId,
        address strategyToken,
        uint256 amount,
        address coin
    ) public onlyManager {
        int256 index = findSubAccountIndexById(msg.sender, user, accountId);
        require(index >= 0, "SubAccount not found");

        ERC20 erc20 = ERC20(coin);
        SubAccount[] storage subAccountsArray = bots[msg.sender].subAccounts[
            user
        ];

        if (
            !subAccountsArray[uint256(index)].strategies[strategyToken].status
        ) {
            subAccountsArray[uint256(index)].list_strategies.push(
                strategyToken
            );
        }

        if (
            !subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .balance[coin]
                .status
        ) {
            subAccountsArray[uint256(index)].strategies[strategyToken].balance[
                coin
            ] = ISubAccount.BalanceStrategy(
                0,
                coin,
                erc20.decimals(),
                erc20.symbol(),
                erc20.name(),
                true,
                false
            );
            subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .list_coins
                .push(coin);
        }

        subAccountsArray[uint256(index)]
            .strategies[strategyToken]
            .balance[coin]
            .amount += amount;

        emit BalanceLiquidy(
            msg.sender,
            user,
            accountId,
            strategyToken,
            coin,
            subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .balance[coin]
                .amount,
            amount,
            true,
            false
        );
    }

    function removeLiquidy(
        address user,
        string memory accountId,
        address strategyToken,
        uint256 amount,
        address coin
    ) public onlyManager {
        int256 index = findSubAccountIndexById(msg.sender, user, accountId);
        require(index >= 0, "SubAccount not found");
        SubAccount[] storage subAccountsArray = bots[msg.sender].subAccounts[
            user
        ];
        require(
            subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .balance[coin]
                .paused,
            "You need to pause to remove liquidity"
        );

        require(
            subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .balance[coin]
                .amount >= amount,
            "Insufficient funds"
        );

        subAccountsArray[uint256(index)]
            .strategies[strategyToken]
            .balance[coin]
            .amount -= amount;

        ERC20(coin).transfer(msg.sender, amount);

        emit BalanceLiquidy(
            msg.sender,
            user,
            accountId,
            strategyToken,
            coin,
            subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .balance[coin]
                .amount,
            amount,
            false,
            false
        );
    }

    function togglePause(
        address user,
        string memory accountId,
        address strategyToken,
        address coin,
        bool paused
    ) public onlyManager {
        int256 index = findSubAccountIndexById(msg.sender, user, accountId);
        require(index >= 0, "SubAccount not found");
        SubAccount[] storage subAccountsArray = bots[msg.sender].subAccounts[
            user
        ];
        require(
            subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .balance[coin]
                .status,
            "Account not linked to strategy"
        );
        require(
            paused !=
                subAccountsArray[uint256(index)]
                    .strategies[strategyToken]
                    .balance[coin]
                    .paused,
            "The paused must be different"
        );
        subAccountsArray[uint256(index)]
            .strategies[strategyToken]
            .balance[coin]
            .paused = paused;

        emit ChangePaused(
            msg.sender,
            user,
            accountId,
            strategyToken,
            coin,
            paused
        );
    }

    function position(
        address contractAddress,
        address user,
        string memory accountId,
        address strategyToken,
        address coin,
        int256 amount
    ) public onlyPayments(contractAddress) returns (uint256 oldBalance) {
        int256 index = findSubAccountIndexById(
            contractAddress,
            user,
            accountId
        );
        require(index >= 0, "SubAccount not found");
        SubAccount[] storage subAccountsArray = bots[contractAddress]
            .subAccounts[user];
        require(
            subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .balance[coin]
                .status,
            "Account not linked to strategy"
        );
        oldBalance = subAccountsArray[uint256(index)]
            .strategies[strategyToken]
            .balance[coin]
            .amount;

        subAccountsArray[uint256(index)]
            .strategies[strategyToken]
            .balance[coin]
            .amount = uint256(
            int256(
                subAccountsArray[uint256(index)]
                    .strategies[strategyToken]
                    .balance[coin]
                    .amount
            ) + amount
        );

        emit BalanceLiquidy(
            contractAddress,
            user,
            accountId,
            strategyToken,
            coin,
            subAccountsArray[uint256(index)]
                .strategies[strategyToken]
                .balance[coin]
                .amount,
            uint256(amount < 0 ? -amount : amount),
            amount < 0,
            true
        );

        return oldBalance;
    }

    function findSubAccountIndexById(
        address managerAddress,
        address user,
        string memory accountId
    ) internal view returns (int256) {
        SubAccount[] storage subAccountsArray = bots[managerAddress]
            .subAccounts[user];
        for (uint256 i = 0; i < subAccountsArray.length; i++) {
            if (
                keccak256(abi.encodePacked(subAccountsArray[i].id)) ==
                keccak256(abi.encodePacked(accountId))
            ) {
                return int256(i);
            }
        }
        return -1;
    }
}
