//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFactory.sol";
import "./interface/IPayments.sol";
import "./interface/IStrategy.sol";

contract WEbdEXFactoryV4 is Ownable {
    mapping(address => IFactory.Bot) internal bots;

    function _checkBot(address contractAddress) internal view virtual {
        require(
            bots[contractAddress].managerAddress != address(0),
            "Bot not found"
        );
    }

    function addBot(
        string memory name,
        string memory prefix,
        address owner,
        address contractAddress,
        address strategyAddress,
        address subAccountAddress,
        address paymentsAddress,
        address tokenPassAddress,        
        IPayments.FeeTier[] memory newFeeTiers
    ) public onlyOwner {
        require(
            bots[contractAddress].managerAddress == address(0),
            "Bot already registered"
        );
        
        bots[contractAddress] = IFactory.Bot(
            prefix,
            name,
            owner,
            contractAddress,
            strategyAddress,
            subAccountAddress,
            paymentsAddress,
            tokenPassAddress
        );
        IPayments(bots[contractAddress].paymentsAddress).addFeeTiers(
            contractAddress,
            newFeeTiers
        );
    }

    function getBotInfo(
        address contractAddress
    ) public view returns (IFactory.Bot memory) {
        return bots[contractAddress];
    }

    function updateBot(
        address contractAddress,
        address strategyAddress,
        address subAccountAddress,
        address paymentsAddress
    ) public onlyOwner {
        _checkBot(contractAddress);
        if (strategyAddress != address(0)) {
            bots[contractAddress].strategyAddress = strategyAddress;
        }
        if (subAccountAddress != address(0)) {
            bots[contractAddress].subAccountAddress = subAccountAddress;
        }
        if (paymentsAddress != address(0)) {
            bots[contractAddress].paymentsAddress = paymentsAddress;
        }
    }

    function removeBot(address contractAddress) public onlyOwner {
        _checkBot(contractAddress);
        delete bots[contractAddress];
    }

    function currencyAllow(
        address contractAddress,
        address coin
    ) public onlyOwner {
        _checkBot(contractAddress);
        IPayments(bots[contractAddress].paymentsAddress).revokeOrAllowCurrency(
            contractAddress,
            coin,
            true
        );
    }

    function currencyRevoke(
        address contractAddress,
        address coin
    ) public onlyOwner {
        _checkBot(contractAddress);
        IPayments(bots[contractAddress].paymentsAddress).revokeOrAllowCurrency(
            contractAddress,
            coin,
            false
        );
    }

    function addStrategy(
        string memory name,
        string memory symbol,
        address contractAddress
    ) public onlyOwner {
        _checkBot(contractAddress);
        IStrategy(bots[contractAddress].strategyAddress).addStrategy(
            name,
            symbol,
            contractAddress
        );
    }

    function updateStrategyStatus(
        address contractAddress,
        address tokenAddress,
        bool isActive
    ) public onlyOwner {
        _checkBot(contractAddress);
        IStrategy(bots[contractAddress].strategyAddress).updateStrategyStatus(
            contractAddress,
            tokenAddress,
            isActive
        );
    }
}
