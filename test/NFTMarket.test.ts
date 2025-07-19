import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { MyNFT, NFTSale } from "../typechain-types";

/**
 * NFT 市场测试
 * 测试 NFT 合约和销售合约的功能
 */
describe("NFT Market", function () {
    // 合约实例
    let nft: MyNFT; // NFT 合约
    let sale: NFTSale; // 销售合约
    let owner: SignerWithAddress; // 合约所有者
    let user1: SignerWithAddress; // 测试用户1
    let user2: SignerWithAddress; // 测试用户2
    let usdt: any; // 模拟 USDT 合约

    // 测试常量
    const MTP_META = "mtp.json"; // 默认元数据文件
    const DISCOUNT_CODE = "DISCOUNT50"; // 测试优惠码
    const DISCOUNT_META = "discount.json"; // 优惠码对应的元数据文件
    const DISCOUNT_AMOUNT = 20; // 优惠码折扣比例（50%）

    /**
     * 每个测试用例前的准备工作
     */
    beforeEach(async function () {
        // 获取测试账号
        [owner, user1, user2] = await ethers.getSigners();

        // 部署 USDT 模拟合约
        const USDT = await ethers.getContractFactory("MockUSDT");
        usdt = await USDT.deploy();
        await usdt.waitForDeployment();

        // 部署 NFT 合约
        const MyNFT = await ethers.getContractFactory("MyNFT");
        nft = (await upgrades.deployProxy(MyNFT, [MTP_META], {
            initializer: "initialize"
        })) as unknown as MyNFT;
        await nft.waitForDeployment();

        // 部署销售合约
        const NFTSale = await ethers.getContractFactory("NFTSale");
        sale = (await upgrades.deployProxy(NFTSale, [await nft.getAddress(), await usdt.getAddress(), owner.address], {
            initializer: "initialize"
        })) as unknown as NFTSale;
        await sale.waitForDeployment();

        // 将销售合约添加为铸造者
        await nft.addMinter(await sale.getAddress());

        // 添加默认优惠码（无折扣）
        await sale.addDiscountCode("mtp", 0, MTP_META);

        // 给测试用户分配 USDT（每人 1000 USDT）
        await usdt.mint(user1.address, ethers.parseUnits("1000", 6));
        await usdt.mint(user2.address, ethers.parseUnits("1000", 6));
    });

    /**
     * NFT 合约功能测试
     */
    describe("NFT Contract", function () {
        // 测试合约初始化
        it("should initialize correctly", async function () {
            expect(await nft.name()).to.equal("MyNFT");
            expect(await nft.symbol()).to.equal("MNFT");
            expect(await nft.codeMetaMap("mtp")).to.equal(MTP_META);
        });

        // 测试添加铸造者权限
        it("should allow owner to add minter", async function () {
            await nft.addMinter(user1.address);
            expect(await nft.minters(user1.address)).to.be.true;
        });

        // 测试铸造 NFT
        it("should allow minter to mint NFT", async function () {
            await nft.addMinter(user1.address);
            await nft.connect(user1).mint(user2.address, "mtp");
            expect(await nft.ownerOf(0n)).to.equal(user2.address);
        });
    });

    /**
     * 销售合约功能测试
     */
    describe("Sale Contract", function () {
        // 测试合约初始化
        it("should initialize correctly", async function () {
            expect(await sale.getNFTContract()).to.equal(await nft.getAddress());
            expect(await sale.getUSDTContract()).to.equal(await usdt.getAddress());
            expect(await sale.getReceiverWallet()).to.equal(owner.address);
            expect(await sale.price()).to.equal(ethers.parseUnits("200", 6));
        });

        // 测试添加优惠码
        it("should allow owner to add discount code", async function () {
            await sale.addDiscountCode(DISCOUNT_CODE, DISCOUNT_AMOUNT, DISCOUNT_META);
            const discountInfo = await sale.getDiscountCodeMap(DISCOUNT_CODE);
            expect(discountInfo.discount).to.equal(DISCOUNT_AMOUNT);
        });

        // 测试使用优惠码购买 NFT
        it("should allow user to buy NFT with discount", async function () {
            // 添加优惠码（20% 折扣）
            await sale.addDiscountCode(DISCOUNT_CODE, DISCOUNT_AMOUNT, DISCOUNT_META);

            // 用户授权 USDT 支付
            await usdt.connect(user1).approve(await sale.getAddress(), ethers.parseUnits("1000", 6));

            // 购买 NFT
            const amount = 2n; // 购买数量
            const price = await sale.price(); // 单价
            const totalPrice = price * amount; // 总价
            const discountedPrice = (totalPrice * BigInt(100 - DISCOUNT_AMOUNT)) / 100n; // 折扣后价格

            // 验证购买事件
            await expect(sale.connect(user1).buyNFT(amount, DISCOUNT_CODE)).to.emit(sale, "BuyNFT").withArgs(user1.address, amount, discountedPrice, DISCOUNT_CODE);

            // 验证 NFT 所有权
            expect(await nft.ownerOf(0n)).to.equal(user1.address);
            expect(await nft.ownerOf(1n)).to.equal(user1.address);

            // 验证优惠码使用情况
            const discountInfo = await sale.getDiscountCodeMap(DISCOUNT_CODE);
            expect(discountInfo.used).to.equal(1n); // 使用次数
            expect(discountInfo.nftAmount).to.equal(amount); // NFT 数量
            expect(discountInfo.usdAmount).to.equal(discountedPrice); // 成交金额
        });

        // 测试使用无折扣码购买
        it("should allow buying with non-discount code", async function () {
            // 用户授权 USDT 支付
            await usdt.connect(user1).approve(await sale.getAddress(), ethers.parseUnits("1000", 6));

            // 使用默认优惠码购买（无折扣）
            const amount = 1n;
            const price = await sale.price();
            const totalPrice = price * amount;

            // 记录初始余额
            const initialBalance = await usdt.balanceOf(user1.address);

            // 执行购买
            await sale.connect(user1).buyNFT(amount, "mtp");

            // 验证 USDT 支付
            const finalBalance = await usdt.balanceOf(user1.address);
            expect(finalBalance).to.equal(initialBalance - totalPrice);

            // 验证 NFT 所有权
            expect(await nft.ownerOf(0n)).to.equal(user1.address);
        });

        // 测试使用无效优惠码购买
        it("should allow buying with invalid discount code", async function () {
            // 用户授权 USDT 支付
            await usdt.connect(user1).approve(await sale.getAddress(), ethers.parseUnits("1000", 6));

            // 使用无效优惠码购买
            const amount = 1n;
            const price = await sale.price();
            const totalPrice = price * amount;

            // 记录初始余额
            const initialBalance = await usdt.balanceOf(user1.address);

            // 执行购买（使用无效优惠码，将自动使用默认优惠码）
            await sale.connect(user1).buyNFT(amount, "INVALID_CODE");

            // 验证 USDT 支付（全额支付）
            const finalBalance = await usdt.balanceOf(user1.address);
            expect(finalBalance).to.equal(initialBalance - totalPrice);

            // 验证 NFT 所有权
            expect(await nft.ownerOf(0n)).to.equal(user1.address);
        });

        // 测试更新价格
        it("should allow owner to update price", async function () {
            const newPrice = ethers.parseUnits("300", 6); // 新价格：300 USDT
            await sale.setPrice(newPrice);
            expect(await sale.price()).to.equal(newPrice);
        });
    });
});
