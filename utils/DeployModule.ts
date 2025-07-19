import { ethers, network, run } from "hardhat";

// 部署普通合约
export async function deploy(contractName: string, ...args: any[]): Promise<string> {
    console.log("Deploying Contract on the chainId" + network.config.chainId);
    const Contract = await ethers.getContractFactory(contractName);
    const contract = await Contract.deploy(...args);

    console.log("contract deployed to: ", contract.target);
    return contract.target.toString();
}

// export default {
//     deploy,
//     deployUpgrade,
//     upgrade,
//     verify
// };

// Compare this snippet from util/DeployModule.ts:
