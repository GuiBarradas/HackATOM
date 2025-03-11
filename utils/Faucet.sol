// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Faucet is ERC20, Ownable {
    mapping(address => uint256) internal mints;

    uint8 internal _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to) external onlyOwner {
        require(mints[to] == 0, "You have already exceeded the mint limit");

        _mint(to, 10000 * 10 ** decimals());
        ++mints[to];
    }
}
