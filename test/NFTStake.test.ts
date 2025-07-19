import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { NFTStake, MultipassNFT } from "../typechain-types";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";

/**
 * NFT 质押测试
 * 测试 NFT 质押合约的功能
 */
describe("NFT Stake", function () {
    // 合约实例
    let nftStake: NFTStake; // 质押合约
    let nftContract: MultipassNFT; // NFT 合约
    let owner: SignerWithAddress; // 合约所有者
    let user1: SignerWithAddress; // 测试用户1
    let user2: SignerWithAddress; // 测试用户2

    /**
     * 每个测试用例前的准备工作
     */
    beforeEach(async function () {
        // 获取测试账号
        [owner, user1, user2] = await ethers.getSigners();

        // 部署 NFT 合约
        const NFT = await ethers.getContractFactory("MultipassNFT");
        nftContract = (await upgrades.deployProxy(NFT, ["bafkreigfyyjr3gue7ay2slzuxowgf7rkvypggt4nvs663bkpxtsldqhlbm"], {
            initializer: "initialize"
        })) as unknown as MultipassNFT;
        await nftContract.waitForDeployment();

        // 部署质押合约
        const NFTStake = await ethers.getContractFactory("NFTStake");
        nftStake = (await upgrades.deployProxy(NFTStake, [await nftContract.getAddress()], {
            initializer: "initialize"
        })) as unknown as NFTStake;
        await nftStake.waitForDeployment();

        // 给用户铸造一些 NFT
        await nftContract.mint(user1.address, "mtp");
        await nftContract.mint(user1.address, "mtp");
        await nftContract.mint(user2.address, "mtp");

        // 用户授权质押合约
        await nftContract.connect(user1).setApprovalForAll(await nftStake.getAddress(), true);
        await nftContract.connect(user2).setApprovalForAll(await nftStake.getAddress(), true);
    });

    /**
     * 合约初始化测试
     */
    describe("合约初始化", function () {
        it("应该正确设置 NFT 合约地址", async function () {
            const nftContractAddress = await nftContract.getAddress();
            const currentNFTContract = await nftStake.getFunction("getNFTContract")();
            expect(currentNFTContract).to.equal(nftContractAddress);
        });
    });

    /**
     * 质押功能测试
     */
    describe("质押功能", function () {
        it("用户应该能够质押 NFT", async function () {
            const tokenIds = [0, 1];
            await nftStake.connect(user1).stake(tokenIds);

            const stakedTokens = await nftStake.getUserStakedTokens(user1.address);
            expect(stakedTokens.length).to.equal(2);
            expect(stakedTokens[0]).to.equal(0n);
            expect(stakedTokens[1]).to.equal(1n);
        });

        it("质押后 NFT 所有权应该转移给质押合约", async function () {
            const tokenIds = [0];
            await nftStake.connect(user1).stake(tokenIds);
            expect(await nftContract.ownerOf(0)).to.equal(await nftStake.getAddress());
        });

        it("质押应该发出正确的事件", async function () {
            await expect(nftStake.connect(user1).stake([0]))
                .to.emit(nftStake, "Stake")
                .withArgs(user1.address, 0n, anyValue);
        });
    });

    /**
     * 解质押功能测试
     */
    describe("解质押功能", function () {
        beforeEach(async function () {
            await nftStake.connect(user1).stake([0, 1]);
        });

        it("用户应该能够解质押特定 NFT", async function () {
            await nftStake.connect(user1).unstake([0]);
            const stakedTokens = await nftStake.getUserStakedTokens(user1.address);
            expect(stakedTokens.length).to.equal(1);
            expect(stakedTokens[0]).to.equal(1n);
            expect(await nftContract.ownerOf(0)).to.equal(user1.address);
        });

        it("用户应该能够解质押所有 NFT", async function () {
            await nftStake.connect(user1).unstakeAll();
            const stakedTokens = await nftStake.getUserStakedTokens(user1.address);
            expect(stakedTokens.length).to.equal(0);
            expect(await nftContract.ownerOf(0)).to.equal(user1.address);
            expect(await nftContract.ownerOf(1)).to.equal(user1.address);
        });

        it("解质押应该发出正确的事件", async function () {
            await expect(nftStake.connect(user1).unstake([0]))
                .to.emit(nftStake, "Unstake")
                .withArgs(user1.address, 0n, anyValue);
        });
    });

    /**
     * 暂停功能测试
     */
    describe("暂停功能", function () {
        it("只有所有者可以暂停合约", async function () {
            await expect(nftStake.connect(user1).pause()).to.be.revertedWithCustomError(nftStake, "OwnableUnauthorizedAccount");
            await nftStake.connect(owner).pause();
            expect(await nftStake.pausable()).to.equal(1n);
        });

        it("暂停后不能进行质押操作", async function () {
            await nftStake.connect(owner).pause();
            await expect(nftStake.connect(user1).stake([0])).to.be.revertedWith("Contract is paused");
        });

        it("暂停后不能进行解质押操作", async function () {
            await nftStake.connect(user1).stake([0]);
            await nftStake.connect(owner).pause();
            await expect(nftStake.connect(user1).unstake([0])).to.be.revertedWith("Contract is paused");
        });

        it("所有者可以恢复合约", async function () {
            await nftStake.connect(owner).pause();
            await nftStake.connect(owner).unpause();
            expect(await nftStake.pausable()).to.equal(0n);
            await nftStake.connect(user1).stake([0]);
        });

        it("暂停应该发出正确的事件", async function () {
            await expect(nftStake.connect(owner).pause()).to.emit(nftStake, "Paused").withArgs(owner.address, anyValue);
        });
    });

    /**
     * 管理员功能测试
     */
    describe("管理员功能", function () {
        it("只有所有者可以更新 NFT 合约地址", async function () {
            const newNFT = await ethers.getContractFactory("MultipassNFT");
            const newNFTContract = await newNFT.deploy();
            await newNFTContract.waitForDeployment();

            await expect(nftStake.connect(user1).setNFTContract(await newNFTContract.getAddress())).to.be.revertedWithCustomError(nftStake, "OwnableUnauthorizedAccount");

            await nftStake.connect(owner).setNFTContract(await newNFTContract.getAddress());
            const currentNFTContract = await nftStake.getNFTContract();
            expect(currentNFTContract).to.equal(await newNFTContract.getAddress());
        });

        it("只有所有者可以提取合约中的 ETH", async function () {
            await expect(nftStake.connect(user1).withdraw(100)).to.be.revertedWithCustomError(nftStake, "OwnableUnauthorizedAccount");
        });
    });
});
