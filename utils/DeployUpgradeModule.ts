import { ethers, upgrades, network } from "hardhat";

// 部署可升级合约
export async function deployUpgrade(contractName: string, ...args: any[]): Promise<string> {
    console.log("Deploying Contract on the chainId" + network.config.chainId);
    const Contract = await ethers.getContractFactory(contractName);
    const contract = await upgrades.deployProxy(Contract, args, {
        initializer: "initialize"
    });
    console.log("contract deployed to: ", contract.target);
    return contract.target.toString();
}

// 升级合约
export async function upgrade(proxyContract: string, contractName: string): Promise<void> {
    console.log("Deploying Contract on the chainId " + network.config.chainId);

    const logicContract = await ethers.getContractFactory(contractName);

    console.log("代理合约地址: ", proxyContract);
    const contract = await upgrades.upgradeProxy(proxyContract, logicContract);
    console.log("contract deployed to: ", contract.target);

    // 检测代理升级情况
    const storeImpl: string = await upgrades.erc1967.getImplementationAddress(contract.target.toString());
    console.log("实现合约: ", storeImpl);
}
