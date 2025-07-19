// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    constructor() ERC20("USDT-TOKEN", "USDT") {
        _mint(msg.sender, 100000000000000 ether);
        // _mint(
        //     0x6982731ba74C2Ef68799ACe1047C096aBE9A10f7,
        //     100000000000000 ether
        // );
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
