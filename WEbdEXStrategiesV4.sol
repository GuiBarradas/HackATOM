// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./utils/NFT.sol";
import "./interface/IFactory.sol";
import "./interface/IStrategy.sol";

contract WEbdEXStrategiesV4 {
    IFactory public factory;

    struct Bot {
        address contractAddress;
        IStrategy.Strategy[] strategies;
    }

    mapping(address => Bot) internal bots;

    event StrategyAdded(
        address indexed contractAddress,
        string name,
        string symbol,
        address tokenAddress
    );

    event StrategyStatusUpdated(
        address indexed contractAddress,
        address tokenAddress,
        bool isActive
    );

    constructor(IFactory _factory) {
        factory = _factory;
    }

    function _checkBot(address contractAddress) internal view virtual {
        IFactory.Bot memory botInfo = factory.getBotInfo(contractAddress);
        require(botInfo.managerAddress != address(0), "Bot not found");
    }

    modifier onlyOwner() {
        require(
            address(factory) == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }

    function addStrategy(
        string memory name,
        string memory symbol,
        address contractAddress
    ) public onlyOwner {
        _checkBot(contractAddress);
        NFT newNFT = new NFT(name, symbol);
        address tokenAddress = address(newNFT);

        if (bots[contractAddress].contractAddress == address(0)) {
            bots[contractAddress].contractAddress = contractAddress;
        }

        bots[contractAddress].strategies.push(
            IStrategy.Strategy(name, tokenAddress, true)
        );

        emit StrategyAdded(contractAddress, name, symbol, tokenAddress);
    }

    function updateStrategyStatus(
        address contractAddress,
        address tokenAddress,
        bool isActive
    ) public onlyOwner {
        _checkBot(contractAddress);
        Bot storage bot = bots[contractAddress];
        for (uint i = 0; i < bot.strategies.length; i++) {
            if (bot.strategies[i].tokenAddress == tokenAddress) {
                bot.strategies[i].isActive = isActive;
                emit StrategyStatusUpdated(
                    contractAddress,
                    tokenAddress,
                    isActive
                );
                return;
            }
        }
        revert("Strategy not found");
    }

    function getStrategies(
        address contractAddress
    ) public view returns (IStrategy.Strategy[] memory) {
        return bots[contractAddress].strategies;
    }

    function findStrategy(
        address contractAddress,
        address tokenAddress
    ) public view returns (IStrategy.Strategy memory) {
        _checkBot(contractAddress);
        Bot storage bot = bots[contractAddress];
        for (uint i = 0; i < bot.strategies.length; i++) {
            if (bot.strategies[i].tokenAddress == tokenAddress) {
                return bot.strategies[i];
            }
        }

        return IStrategy.Strategy("unknown", address(0), false);
    }
}
