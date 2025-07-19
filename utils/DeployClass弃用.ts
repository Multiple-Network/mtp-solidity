import { Addressable } from "ethers";
import { ethers, upgrades, network, run } from "hardhat";

interface Script {
    deploy: (contractName: string, ...args: any[]) => Promise<void>;
    deployUpgrade: (contractName: string, ...args: any[]) => Promise<void>;
    upgrade: (...args: any[]) => Promise<void>;
    verify: (...args: any[]) => Promise<void>;
}

class DeployModule implements Script {
    constructor(public contractName: string) {}

    async deploy(contractName: string, ...args: any[]) {
        console.log("Deploying Contract on the chainId" + network.config.chainId);
        const Contract = await ethers.getContractFactory(contractName);
        const contract = await Contract.deploy(...args);
        console.log("contract deployed to: ", contract.target);
    }

    async deployUpgrade(contractName: string, ...args: any[]) {
        console.log("Deploying Contract on the chainId" + network.config.chainId);
        const Contract = await ethers.getContractFactory(contractName);
        const contract = await upgrades.deployProxy(Contract, args, {
            initializer: "initialize"
        });
        console.log("contract deployed to: ", contract.target);
    }

    async upgrade(proxyContract: string, contractName: string, ...args: any[]) {
        console.log("Deploying Contract on the chainId " + network.config.chainId);

        const logicContract = await ethers.getContractFactory(contractName);

        console.log("代理合约地址: ", proxyContract);
        const contract = await upgrades.upgradeProxy(proxyContract, logicContract);
        console.log("contract deployed to: ", contract.target);

        // 检测代理升级情况
        const storeImpl: string = await upgrades.erc1967.getImplementationAddress(contract.target.toString());
        console.log("实现合约: ", storeImpl);
    }

    async verify(address_: string, ...args_: any[]) {
        await run("verify:verify", {
            // contract: "contracts/Fam/game/Funds.sol:Funds",
            address: address_,
            constructorArguments: args_
        });

        console.log("Verify contract Successfully.");
    }
}

export default DeployModule;
