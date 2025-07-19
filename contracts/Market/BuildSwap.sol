// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniswapV3Swap} from "contracts/Market/lib/MarketV3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// WBNB 接口
interface IWBNB {
    function withdraw(uint256 wad) external;
}

contract BuildTokenMarket is UniswapV3Swap, Ownable {
    // use IERC20;
    // 管理员
    mapping(address => bool) public admin;

    event SwapByConToken(
        address indexed tokenIn,
        address indexed tokenOut,
        uint indexed amount
    );

    event SwapByUserToken(
        address indexed tokenIn,
        address indexed tokenOut,
        uint indexed amount
    );

    constructor(
        address swapRouter_,
        address factory_
    ) UniswapV3Swap(swapRouter_, factory_) Ownable(msg.sender) {
        admin[msg.sender] = true;
    }

    event Swap(
        address indexed tokenOut,
        address indexed tokenIn,
        uint indexed amount
    );
    modifier onlyAdmin() {
        require(admin[msg.sender], "only admin");
        _;
    }

    // 用于接收无数据的 ETH / BNB
    receive() external payable {
        // 这个函数用来接收 ETH / BNB
        // msg.value 表示接收到的主链币的数量
    }

    // 查询合约中存储的 ETH / BNB
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // 提取合约中的 ETH / BNB
    function withdraw() public onlyOwner {
        // 确保调用者是合约所有者（或其他安全的权限控制）
        payable(msg.sender).transfer(address(this).balance);
    }

    function setAdmin(address admin_, bool b_) public onlyOwner {
        admin[admin_] = b_;
    }

    function safePull(
        address token_,
        address to_,
        uint amount_
    ) external onlyAdmin {
        IERC20(token_).transfer(to_, amount_);
    }

    function swapByConToken(
        address tokenIn,
        address tokenOut,
        uint amount,
        uint24 poolFee
    ) public payable onlyAdmin {
        swapExactInputSingleHop(tokenIn, tokenOut, poolFee, amount);
        emit SwapByConToken(tokenIn, tokenOut, amount);
        (tokenIn, tokenOut, amount);
    }

    function swapByUserToken(
        address tokenIn,
        address tokenOut,
        uint amount,
        uint24 poolFee
    ) public payable onlyAdmin {
        swapExactInputSingleHopToRecipient(tokenIn, tokenOut, poolFee, amount);
        emit SwapByUserToken(tokenIn, tokenOut, amount);
    }
}
