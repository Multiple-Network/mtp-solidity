// 定义可升级合约部署函数的类型
export type DeployUpgradeFunction = (contractName: string, ...args: any[]) => Promise<string>;

// 定义合约升级函数的类型
export type UpgradeFunction = (proxyContract: string, contractName: string) => Promise<void>;
