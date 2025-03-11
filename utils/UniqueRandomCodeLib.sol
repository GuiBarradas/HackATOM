// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/utils/Strings.sol";

library UniqueRandomCodeLib {
    using Strings for uint256;

    function generateUniqueCode(
        string memory prefix,
        uint256 counter
    ) internal view returns (string memory) {
        uint256 uniqueNumber = uint256(
            keccak256(
                abi.encodePacked(
                    prefix,
                    counter,
                    block.timestamp,
                    block.prevrandao,
                    msg.sender
                )
            )
        ) % 1e9;

        return
            string(
                abi.encodePacked(
                    prefix,
                    _toPaddedString(uniqueNumber),
                    counter.toString()
                )
            );
    }

    function _toPaddedString(
        uint256 value
    ) private pure returns (string memory) {
        bytes memory buffer = new bytes(9);
        for (uint256 i = 9; i > 0; i--) {
            buffer[i - 1] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
