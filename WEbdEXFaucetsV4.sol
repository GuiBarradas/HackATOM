//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./utils/Faucet.sol";

contract WEbdEXFaucetsV4 {
    Faucet public CBC;
    Faucet public USDT;
    Faucet public DAI;
    Faucet public USDC;

    constructor() {
        CBC = new Faucet("Conecta Crypto", "CBC", 9);
        USDT = new Faucet("Tether USD", "USDT", 6);
        DAI = new Faucet("Dai Stablecoin", "DAI", 18);
        USDC = new Faucet("USD Coin", "USDC", 6);
    }

    function mint() public {
        CBC.mint(msg.sender);
        USDT.mint(msg.sender);
        DAI.mint(msg.sender);
        USDC.mint(msg.sender);
    }
}
