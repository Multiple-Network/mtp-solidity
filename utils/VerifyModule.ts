import { run } from "hardhat";

// 验证合约

export async function verify(contractPath: string, address_: string, ...args_: any[]) {
    await run("verify:verify", {
        // contract: "contracts/Token/MIA.sol:MIA",
        // contract: contractPath,
        address: address_,
        constructorArguments: args_
    });

    console.log("Verify contract Successfully.");
}
