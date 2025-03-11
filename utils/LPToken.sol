//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LPToken is ERC20, Ownable {
    uint8 internal _decimals;

    struct Origin {
        string name;
        string symbol;
        uint8 decimals;
        address token;
    }
    Origin public coin;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address contract_
    )
        ERC20(
            string(abi.encodePacked("LP ", name_)),
            string(abi.encodePacked("LP", symbol_))
        )
    {
        _decimals = decimals_;
        coin = Origin(name_, symbol_, decimals_, contract_);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    function getContractOrigin() public view returns (Origin memory) {
        return coin;
    }
}
