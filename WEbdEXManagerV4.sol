//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interface/ISubAccount.sol";
import "./interface/IFactory.sol";
import "./interface/IStrategy.sol";
import "./utils/LPToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WEbdEXManagerV4 {
    IFactory public factory;
    mapping(address => User) internal users;
    struct User {
        address manager;
        uint256 gasBalance;
        uint256 passBalance;
        bool status;
    }

    struct UserDisplay {
        address manager;
        uint256 gasBalance;
        uint256 passBalance;
        ISubAccount.SubAccountsDisplay[] SubAccounts;
    }

    mapping(address => Coin) internal listCoins;
    struct Coin {
        bool status;
        LPToken lp;
    }

    event Register(address indexed user, address indexed manager);

    event BalanceGas(
        address indexed user,
        uint256 balance,
        uint256 value,
        bool increase,
        bool is_operation
    );

    event BalancePass(
        address indexed user,
        uint256 balance,
        uint256 value,
        bool increase,
        bool is_operation
    );

    constructor(IFactory _factory) {
        factory = _factory;
    }

    modifier onlyPayments() {
        IFactory.Bot memory botInfo = factory.getBotInfo(address(this));
        require(
            botInfo.paymentsAddress == msg.sender,
            "You must the WebDexPayments"
        );
        _;
    }

    modifier onlyRegistered() {
        require(users[msg.sender].status, "User not registered");
        _;
    }

    function register(address manager, string memory name) public {
        if (manager != address(0)) {
            require(users[manager].status, "Unregistered manager");
        }

        require(!users[msg.sender].status, "User already registered");
        users[msg.sender] = User(manager, 0, 0, true);
        emit Register(msg.sender, manager);

        _createSubAccount(msg.sender, name);
    }

    function subAccount() internal view returns (ISubAccount) {
        address subAccountAddress = factory
            .getBotInfo(address(this))
            .subAccountAddress;
        return ISubAccount(subAccountAddress);
    }

    function _createSubAccount(address user, string memory name) internal {
        subAccount().create(user, name);
    }

    function createSubAccount(string[] memory names) public onlyRegistered {
        for (uint256 i = 0; i < names.length; i++) {
            _createSubAccount(msg.sender, names[i]);
        }
    }

    function getInfoUser() public view returns (UserDisplay memory) {
        ISubAccount SubAccount = subAccount();
        ISubAccount.SubAccounts[] memory subAccounts = SubAccount
            .getSubAccounts(address(this), msg.sender);

        uint256 subAccountCount = subAccounts.length;
        ISubAccount.SubAccountsDisplay[]
            memory accounts = new ISubAccount.SubAccountsDisplay[](
                subAccountCount
            );

        for (uint256 i = 0; i < subAccountCount; i++) {
            address[] memory _strategies = SubAccount.getStrategies(
                address(this),
                msg.sender,
                subAccounts[i].id
            );

            ISubAccount.StrategyDisplay[]
                memory strategies = new ISubAccount.StrategyDisplay[](
                    _strategies.length
                );

            for (uint256 j = 0; j < _strategies.length; j++) {
                ISubAccount.BalanceStrategy[] memory balances = SubAccount
                    .getBalances(
                        address(this),
                        msg.sender,
                        subAccounts[i].id,
                        _strategies[j]
                    );
                strategies[j] = ISubAccount.StrategyDisplay(
                    _strategies[j],
                    balances
                );
            }
            accounts[i] = ISubAccount.SubAccountsDisplay(
                subAccounts[i].id,
                subAccounts[i].name,
                strategies
            );
        }

        return
            UserDisplay(
                users[msg.sender].manager,
                users[msg.sender].gasBalance,
                users[msg.sender].passBalance,
                accounts
            );
    }

    function getStrategies() public view returns (IStrategy.Strategy[] memory) {
        return strategy().getStrategies(address(this));
    }

    function strategy() internal view returns (IStrategy) {
        address strategyAddress = factory
            .getBotInfo(address(this))
            .strategyAddress;
        return IStrategy(strategyAddress);
    }

    function _lpMint(
        address to,
        address coin,
        uint256 amount
    ) internal returns (address) {
        listCoins[coin].lp.mint(to, amount);
        return address(listCoins[coin].lp);
    }

    function liquidyAdd(
        string[] memory accountId,
        address strategyToken,
        address coin,
        uint256 amount
    ) public onlyRegistered {
        require(
            strategy().findStrategy(address(this), strategyToken).isActive,
            "Strategy not found"
        );
        require(coin != address(0), "Invalid contract address");

        ERC20 erc20 = ERC20(coin);
        if (!listCoins[coin].status) {
            listCoins[coin] = Coin(
                true,
                new LPToken(
                    erc20.name(),
                    erc20.symbol(),
                    erc20.decimals(),
                    coin
                )
            );
        }

        ISubAccount SubAccount = subAccount();
        for (uint256 i = 0; i < accountId.length; i++) {
            SubAccount.addLiquidy(
                msg.sender,
                accountId[i],
                strategyToken,
                amount / accountId.length,
                coin
            );
        }

        erc20.transferFrom(msg.sender, address(SubAccount), amount);
        _lpMint(msg.sender, coin, amount);
    }

    function liquidyRemove(
        string[] memory accountId,
        address strategyToken,
        address coin,
        uint256 amount
    ) public onlyRegistered {
        require(
            strategy().findStrategy(address(this), strategyToken).isActive,
            "Strategy not found"
        );
        require(coin != address(0), "Invalid contract address");

        for (uint256 i = 0; i < accountId.length; i++) {
            subAccount().removeLiquidy(
                msg.sender,
                accountId[i],
                strategyToken,
                amount,
                coin
            );
        }

        ERC20 erc20 = ERC20(coin);
        listCoins[coin].lp.burnFrom(msg.sender, amount * accountId.length);
        erc20.transfer(msg.sender, amount * accountId.length);
    }

    function togglePause(
        string[] memory accountId,
        address strategyToken,
        address coin,
        bool paused
    ) public onlyRegistered {
        require(
            strategy().findStrategy(address(this), strategyToken).isActive,
            "Strategy not found"
        );
        require(coin != address(0), "Invalid contract address");

        for (uint256 i = 0; i < accountId.length; i++) {
            subAccount().togglePause(
                msg.sender,
                accountId[i],
                strategyToken,
                coin,
                paused
            );
        }
    }

    function gasRemove(uint256 amount) public onlyRegistered {
        require(
            users[msg.sender].gasBalance >= amount,
            "Insufficient gas balance"
        );

        users[msg.sender].gasBalance -= amount;

        payable(msg.sender).transfer(amount);

        emit BalanceGas(
            msg.sender,
            users[msg.sender].gasBalance,
            amount,
            false,
            false
        );
    }

    function gasAdd() public payable onlyRegistered {
        require(msg.value >= 0, "Insufficient value");
        users[msg.sender].gasBalance += msg.value;

        emit BalanceGas(
            msg.sender,
            users[msg.sender].gasBalance,
            msg.value,
            true,
            false
        );
    }

    function gasBalance() public view returns (uint256) {
        return users[msg.sender].gasBalance;
    }

    function passAdd(uint256 amount) public onlyRegistered {
        users[msg.sender].passBalance += amount;
        address token = factory.getBotInfo(address(this)).tokenPassAddress;

        ERC20 erc20 = ERC20(token);
        erc20.transferFrom(msg.sender, address(this), amount);

        emit BalancePass(
            msg.sender,
            users[msg.sender].passBalance,
            amount,
            true,
            false
        );
    }

    function passRemove(uint256 amount) public onlyRegistered {
        require(
            users[msg.sender].passBalance >= amount,
            "Insufficient pass balance"
        );
        users[msg.sender].passBalance -= amount;
        address token = factory.getBotInfo(address(this)).tokenPassAddress;

        ERC20 erc20 = ERC20(token);
        erc20.transfer(msg.sender, amount);

        emit BalancePass(
            msg.sender,
            users[msg.sender].passBalance,
            amount,
            false,
            false
        );
    }

    function passBalance() public view returns (uint256) {
        return users[msg.sender].passBalance;
    }

    function rebalancePosition(
        address user,
        int256 amount,
        uint256 gas,
        address coin,
        uint256 fee
    ) public onlyPayments {
        require(users[user].gasBalance >= gas, "Insufficient gas balance");
        require(users[user].passBalance >= fee, "Insufficient pass balance");
        users[user].passBalance -= fee;
        users[user].gasBalance -= gas;

        if (amount > 0) {
            listCoins[coin].lp.mint(user, uint256(amount));
        } else {
            listCoins[coin].lp.burnFrom(user, uint256(-1 * amount));
        }

        IFactory.Bot memory botInfo = factory.getBotInfo(address(this));
        payable(botInfo.owner).transfer(gas);

        emit BalanceGas(user, users[user].gasBalance, gas, false, true);
        emit BalancePass(user, users[user].passBalance, fee, false, true);
    }
}
