// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IMultipassNFT.sol";

contract MutipassNftSale is OwnableUpgradeable {
    // NFT 合约地址
    IMultipassNFT private nftContract;
    // USDT 合约地址
    IERC20 private usdtToken;
    // 接收 USDT 的钱包地址
    address private receiverWallet;
    // NFT 价格（以 USDT 计价，考虑 USDT 的 18 位小数）
    uint256 public price;

    // 优惠码相关
    mapping(string => bool) public discountCodes;
    string[] public discountCodeList;

    struct DiscountCode {
        string code;
        uint256 discount; // 10 就是10%
        uint256 used; // 使用次数
        uint256 nftAmount; // 成交数量
        uint256 usdAmount; // 成交金额
    }
    mapping(string => DiscountCode) public discountCodeMap;

    event BuyNFT(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed totalUSD,
        string code
    );

    function initialize(
        address _nftContract,
        address _usdtToken,
        address _receiverWallet
    ) public initializer {
        __Ownable_init(msg.sender);

        nftContract = IMultipassNFT(_nftContract);
        usdtToken = IERC20(_usdtToken);
        receiverWallet = _receiverWallet;
        price = 200 ether; // 默认 200 USDT
    }

    // =============================================================
    //                          user
    // =============================================================
    function buyNFT(uint256 amount, string memory code_) public {
        require(amount > 0, "Amount must be greater than 0");

        // 如果优惠码不存在，使用默认的mtp代码
        string memory useCode = discountCodes[code_] ? code_ : "mtp";
        DiscountCode storage discountCode = discountCodeMap[useCode];

        uint256 totalU = price * amount;

        if (discountCodeMap[useCode].discount > 0) {
            totalU = (totalU * (100 - discountCode.discount)) / 100;
            IERC20(usdtToken).transferFrom(msg.sender, receiverWallet, totalU);
        } else {
            require(
                usdtToken.transferFrom(msg.sender, receiverWallet, totalU),
                "USDT transfer failed"
            );
        }

        // 更新优惠码使用次数、成交数量、成交金额
        discountCode.used++;
        discountCode.nftAmount += amount;
        discountCode.usdAmount += totalU;

        // 铸造NFT
        nftContract.mintBatch(msg.sender, amount, useCode);

        emit BuyNFT(msg.sender, amount, totalU, useCode);
    }

    // =============================================================
    //                          admin
    // =============================================================
    // Admin functions
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // 更新接收钱包地址
    function setReceiverWallet(address newWallet) public onlyOwner {
        receiverWallet = newWallet;
    }

    // 更新 NFT 合约地址
    function setNFTContract(address newContract) public onlyOwner {
        nftContract = IMultipassNFT(newContract);
    }

    // 添加优惠码
    function addDiscountCode(
        string memory code_,
        uint256 discount,
        string memory metaFile
    ) public onlyOwner {
        require(discount <= 100, "Discount cannot exceed 100%");
        require(!discountCodes[code_], "Code already exists");

        discountCodes[code_] = true;
        discountCodeMap[code_] = DiscountCode(
            code_,
            discount,
            0, // 使用次数
            0, // 成交数量
            0 // 成交金额
        );
        discountCodeList.push(code_);

        // 设置优惠码对应的元数据文件
        nftContract.setMetaFile(code_, metaFile);
    }

    function addDiscountCodeMuti(
        string[] memory codes_,
        uint256 discount,
        string memory metaFile
    ) public onlyOwner {
        for (uint256 i = 0; i < codes_.length; i++) {
            addDiscountCode(codes_[i], discount, metaFile);
        }
    }

    // =============================================================
    //                          view
    // =============================================================
    // 输入优惠码，获得折扣情况
    function getDiscount(
        string calldata code_
    ) public view returns (uint discount) {
        discount = discountCodeMap[code_].discount;
    }

    // 输入优惠码，查看优惠码销售情况
    function getDiscountCodeMap(
        string calldata code_
    ) public view returns (DiscountCode memory discountCode) {
        discountCode = discountCodeMap[code_];
    }

    // 查看优惠码列表
    function getDiscountCodeList() public view returns (string[] memory) {
        return discountCodeList;
    }

    // 查看 NFT 合约地址
    function getNFTContract() public view returns (address) {
        return address(nftContract);
    }

    // 查看 USDT 合约地址
    function getUSDTContract() public view returns (address) {
        return address(usdtToken);
    }

    // 查看接收钱包地址
    function getReceiverWallet() public view returns (address) {
        return receiverWallet;
    }
}
