// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interface/IFactory.sol";
import "./interface/IPayments.sol";
import "./interface/IStrategy.sol";
import "./interface/IManager.sol";
import "./interface/ISubAccount.sol";

contract WEbdEXPaymentsV4 {
    IFactory public factory;

    mapping(address => IPayments.Bot) internal bots;
    struct Currencys {
        address from;
        address to;
    }
    event Trader(address indexed manager, address from, address to);

    struct PositionDetails {
        address strategy;
        address coin;
        uint256 oldBalance;
        uint256 fee;
        uint256 gas;
        int256 profit;
    }

    event OpenPosition(
        address indexed manager,
        address user,
        string accountId,
        PositionDetails details
    );

    constructor(IFactory _factory) {
        factory = _factory;
    }

    modifier onlyOwner(address contractAddress) {
        IFactory.Bot memory botInfo = factory.getBotInfo(contractAddress);
        require(
            botInfo.owner == msg.sender || address(factory) == msg.sender,
            "Ownable: caller is not the owner nor the factory"
        );
        _;
    }

    function manager(address contractAddress) internal view returns (IManager) {
        address managerAddress = factory
            .getBotInfo(contractAddress)
            .managerAddress;
        return IManager(managerAddress);
    }

    function strategy(
        address contractAddress
    ) internal view returns (IStrategy) {
        address strategyAddress = factory
            .getBotInfo(contractAddress)
            .strategyAddress;
        return IStrategy(strategyAddress);
    }

    function subAccount(
        address contractAddress
    ) internal view returns (ISubAccount) {
        address subAccountAddress = factory
            .getBotInfo(contractAddress)
            .subAccountAddress;
        return ISubAccount(subAccountAddress);
    }

    function revokeOrAllowCurrency(
        address contractAddress,
        address coin,
        bool status
    ) public onlyOwner(contractAddress) {
        require(
            status != bots[contractAddress].coins[coin].status,
            "The status must be different"
        );
        if (!bots[contractAddress].coins[coin].status) {
            ERC20 erc20 = ERC20(coin);
            bots[contractAddress].coins[coin] = IPayments.Coins(
                erc20.name(),
                erc20.symbol(),
                erc20.decimals(),
                true
            );
        }

        bots[contractAddress].coins[coin].status = status;
    }

    function addFeeTiers(
        address contractAddress,
        IPayments.FeeTier[] memory newFeeTiers
    ) public onlyOwner(contractAddress) {
        delete bots[contractAddress].feeTiers;

        for (uint256 i = 0; i < newFeeTiers.length; i++) {
            bots[contractAddress].feeTiers.push(newFeeTiers[i]);
        }
    }

    function calculateFee(
        address contractAddress,
        uint256 value
    ) internal view returns (uint256) {
        IPayments.FeeTier[] memory feeTiers = bots[contractAddress].feeTiers;
        for (uint256 i = 0; i < feeTiers.length; i++) {
            if (value <= feeTiers[i].limit) {
                return feeTiers[i].fee;
            }
        }
        return feeTiers[feeTiers.length - 1].fee;
    }

    function openPosition(
        address contractAddress,
        string memory accountId,
        address strategyToken,
        address user,
        int256 amount,
        Currencys[] memory currrencys,
        uint256 gas,
        address coin
    ) public onlyOwner(contractAddress) {
        IFactory.Bot memory botInfo = factory.getBotInfo(contractAddress);
        require(
            strategy(contractAddress)
                .findStrategy(botInfo.managerAddress, strategyToken)
                .isActive,
            "Strategy not found"
        );

        for (uint256 index = 0; index < currrencys.length; index++) {
            require(
                bots[contractAddress].coins[currrencys[index].from].status &&
                    bots[contractAddress].coins[currrencys[index].to].status,
                "One of the coins is not a valid ERC20 token"
            );
        }

        uint256 oldBalance = subAccount(contractAddress).position(
            botInfo.managerAddress,
            user,
            accountId,
            strategyToken,
            coin,
            amount
        );
        uint256 fee = calculateFee(contractAddress, oldBalance);

        manager(contractAddress).rebalancePosition(
            user,
            amount,
            gas,
            coin,
            fee
        );

        PositionDetails memory details = PositionDetails(
            strategyToken,
            coin,
            oldBalance,
            fee,
            gas,
            amount
        );

        emit OpenPosition(contractAddress, user, accountId, details);

        for (uint256 index = 0; index < currrencys.length; index++) {
            emit Trader(
                contractAddress,
                currrencys[index].from,
                currrencys[index].to
            );
        }
    }
}
