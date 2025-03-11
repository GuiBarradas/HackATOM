// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFactory {
    struct Bot {
        string prefix;
        string name;
        address owner;
        address managerAddress;
        address strategyAddress;
        address subAccountAddress;
        address paymentsAddress;
        address tokenPassAddress;
    }
    function getBotInfo(
        address contractAddress
    ) external view returns (Bot memory);
}
